param(
    [string[]]$Target = @("all"),
    [string]$Programmer = "STM32_Programmer_CLI",
    [string]$Connect = "port=SWD mode=HotPlug",
    [string]$OutputJson = "",
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Expand-ProbeTargets([string[]]$Targets) {
    $validTargets = @("fault", "rcc", "gpio", "usart", "i2c", "flash", "all")
    $requestedTargets = @()

    foreach ($item in $Targets) {
        foreach ($part in ([string]$item -split ",")) {
            $trimmed = $part.Trim().ToLowerInvariant()
            if ($trimmed.Length -eq 0) { continue }
            if ($validTargets -notcontains $trimmed) {
                throw "Invalid F103 register probe target '$trimmed'. Valid targets: $($validTargets -join ', ')"
            }
            $requestedTargets += $trimmed
        }
    }

    if ($requestedTargets -contains "all") {
        return @("fault", "rcc", "gpio", "usart", "i2c", "flash")
    }
    return @($requestedTargets)
}

function New-Reg([string]$TargetName, [string]$Name, [string]$Address, [string]$Decoder) {
    [pscustomobject]@{
        target = $TargetName
        name = $Name
        address = $Address
        decoder = $Decoder
    }
}

function Get-RegisterPlan([string[]]$Targets) {
    $plan = @()
    foreach ($targetName in $Targets) {
        switch ($targetName) {
            "fault" {
                $plan += New-Reg "fault" "DHCSR" "0xE000EDF0" "dhcsr"
            }
            "rcc" {
                $plan += New-Reg "rcc" "RCC_APB2ENR" "0x40021018" "rcc_apb2enr"
                $plan += New-Reg "rcc" "RCC_APB1ENR" "0x4002101C" "rcc_apb1enr"
                $plan += New-Reg "rcc" "RCC_CSR" "0x40021024" "rcc_csr"
            }
            "gpio" {
                $plan += New-Reg "gpio" "GPIOA_CRH" "0x40010804" "gpioa_crh"
                $plan += New-Reg "gpio" "GPIOB_CRL" "0x40010C00" "gpiob_crl"
                $plan += New-Reg "gpio" "GPIOB_IDR" "0x40010C08" "gpiob_idr"
                $plan += New-Reg "gpio" "GPIOC_CRH" "0x40011004" "gpioc_crh"
            }
            "usart" {
                $plan += New-Reg "usart" "USART1_SR" "0x40013800" "usart_sr"
                $plan += New-Reg "usart" "USART1_BRR" "0x40013808" "usart_brr"
                $plan += New-Reg "usart" "USART1_CR1" "0x4001380C" "usart_cr1"
            }
            "i2c" {
                $plan += New-Reg "i2c" "I2C1_CR1" "0x40005400" "i2c_cr1"
                $plan += New-Reg "i2c" "I2C1_CR2" "0x40005404" "i2c_cr2"
                $plan += New-Reg "i2c" "I2C1_SR1" "0x40005414" "i2c_sr1"
                $plan += New-Reg "i2c" "I2C1_SR2" "0x40005418" "i2c_sr2"
                $plan += New-Reg "i2c" "I2C1_CCR" "0x4000541C" "i2c_ccr"
                $plan += New-Reg "i2c" "I2C1_TRISE" "0x40005420" "i2c_trise"
            }
            "flash" {
                $plan += New-Reg "flash" "FLASH_SR" "0x4002200C" "flash_sr"
                $plan += New-Reg "flash" "FLASH_CR" "0x40022010" "flash_cr"
            }
        }
    }
    return $plan
}

function Split-ConnectArgs([string]$ConnectValue) {
    $tokens = @()
    foreach ($token in ($ConnectValue -split "\s+")) {
        $trimmed = $token.Trim()
        if ($trimmed.Length -gt 0) { $tokens += $trimmed }
    }
    return $tokens
}

function Convert-HexToUInt32([string]$HexValue) {
    return [Convert]::ToUInt32(($HexValue -replace "^0x", ""), 16)
}

function Test-RegBit([uint32]$Value, [int]$Bit) {
    return (($Value -band ([uint32]1 -shl $Bit)) -ne 0)
}

function Format-Bool([bool]$Value) {
    if ($Value) { return "1" }
    return "0"
}

function Decode-F1GpioPin([uint32]$Value, [int]$Pin) {
    $bits = ($Value -shr (($Pin % 8) * 4)) -band 0xF
    $mode = $bits -band 0x3
    $cnf = ($bits -shr 2) -band 0x3
    return ("mode={0} cnf={1}" -f $mode, $cnf)
}

function Get-DecodeLines([string]$Decoder, [Nullable[uint32]]$Value) {
    if ($null -eq $Value) { return @("decode=pending") }

    switch ($Decoder) {
        "dhcsr" {
            return @(
                "S_HALT(bit17)=$(Format-Bool (Test-RegBit $Value 17))",
                "S_SLEEP(bit18)=$(Format-Bool (Test-RegBit $Value 18))",
                "S_LOCKUP(bit19)=$(Format-Bool (Test-RegBit $Value 19))",
                "S_RESET_ST(bit25)=$(Format-Bool (Test-RegBit $Value 25))"
            )
        }
        "rcc_apb2enr" {
            return @(
                "AFIOEN(bit0)=$(Format-Bool (Test-RegBit $Value 0))",
                "IOPAEN(bit2)=$(Format-Bool (Test-RegBit $Value 2))",
                "IOPBEN(bit3)=$(Format-Bool (Test-RegBit $Value 3))",
                "IOPCEN(bit4)=$(Format-Bool (Test-RegBit $Value 4))",
                "USART1EN(bit14)=$(Format-Bool (Test-RegBit $Value 14))"
            )
        }
        "rcc_apb1enr" {
            return @(
                "I2C1EN(bit21)=$(Format-Bool (Test-RegBit $Value 21))",
                "PWREN(bit28)=$(Format-Bool (Test-RegBit $Value 28))"
            )
        }
        "rcc_csr" {
            return @(
                "RMVF(bit24)=$(Format-Bool (Test-RegBit $Value 24))",
                "PINRSTF(bit26)=$(Format-Bool (Test-RegBit $Value 26))",
                "PORRSTF(bit27)=$(Format-Bool (Test-RegBit $Value 27))",
                "SFTRSTF(bit28)=$(Format-Bool (Test-RegBit $Value 28))",
                "IWDGRSTF(bit29)=$(Format-Bool (Test-RegBit $Value 29))",
                "WWDGRSTF(bit30)=$(Format-Bool (Test-RegBit $Value 30))",
                "LPWRRSTF(bit31)=$(Format-Bool (Test-RegBit $Value 31))"
            )
        }
        "gpioa_crh" {
            return @(
                "PA9 USART1_TX $(Decode-F1GpioPin $Value 9)",
                "PA10 USART1_RX $(Decode-F1GpioPin $Value 10)"
            )
        }
        "gpiob_crl" {
            return @(
                "PB6 I2C1_SCL $(Decode-F1GpioPin $Value 6)",
                "PB7 I2C1_SDA $(Decode-F1GpioPin $Value 7)"
            )
        }
        "gpiob_idr" {
            return @(
                "PB6_SCL_IDLE(bit6)=$(Format-Bool (Test-RegBit $Value 6))",
                "PB7_SDA_IDLE(bit7)=$(Format-Bool (Test-RegBit $Value 7))"
            )
        }
        "gpioc_crh" {
            return @("PC13_LED $(Decode-F1GpioPin $Value 13)")
        }
        "usart_sr" {
            return @(
                "RXNE(bit5)=$(Format-Bool (Test-RegBit $Value 5))",
                "TC(bit6)=$(Format-Bool (Test-RegBit $Value 6))",
                "TXE(bit7)=$(Format-Bool (Test-RegBit $Value 7))",
                "ORE(bit3)=$(Format-Bool (Test-RegBit $Value 3))"
            )
        }
        "usart_brr" {
            return @("BRR=0x{0:X8}" -f $Value)
        }
        "usart_cr1" {
            return @(
                "UE(bit13)=$(Format-Bool (Test-RegBit $Value 13))",
                "TE(bit3)=$(Format-Bool (Test-RegBit $Value 3))",
                "RE(bit2)=$(Format-Bool (Test-RegBit $Value 2))",
                "RXNEIE(bit5)=$(Format-Bool (Test-RegBit $Value 5))"
            )
        }
        "i2c_cr1" {
            return @(
                "PE(bit0)=$(Format-Bool (Test-RegBit $Value 0))",
                "START(bit8)=$(Format-Bool (Test-RegBit $Value 8))",
                "STOP(bit9)=$(Format-Bool (Test-RegBit $Value 9))",
                "ACK(bit10)=$(Format-Bool (Test-RegBit $Value 10))",
                "SWRST(bit15)=$(Format-Bool (Test-RegBit $Value 15))"
            )
        }
        "i2c_cr2" {
            return @("FREQ(bits5:0)=$(($Value -band 0x3F))")
        }
        "i2c_sr1" {
            return @(
                "SB(bit0)=$(Format-Bool (Test-RegBit $Value 0))",
                "ADDR(bit1)=$(Format-Bool (Test-RegBit $Value 1))",
                "BTF(bit2)=$(Format-Bool (Test-RegBit $Value 2))",
                "RXNE(bit6)=$(Format-Bool (Test-RegBit $Value 6))",
                "TXE(bit7)=$(Format-Bool (Test-RegBit $Value 7))",
                "BERR(bit8)=$(Format-Bool (Test-RegBit $Value 8))",
                "ARLO(bit9)=$(Format-Bool (Test-RegBit $Value 9))",
                "AF(bit10)=$(Format-Bool (Test-RegBit $Value 10))",
                "OVR(bit11)=$(Format-Bool (Test-RegBit $Value 11))"
            )
        }
        "i2c_sr2" {
            return @(
                "MSL(bit0)=$(Format-Bool (Test-RegBit $Value 0))",
                "BUSY(bit1)=$(Format-Bool (Test-RegBit $Value 1))",
                "TRA(bit2)=$(Format-Bool (Test-RegBit $Value 2))"
            )
        }
        "i2c_ccr" {
            return @("CCR(bits11:0)=$(($Value -band 0xFFF))", "F/S(bit15)=$(Format-Bool (Test-RegBit $Value 15))")
        }
        "i2c_trise" {
            return @("TRISE(bits5:0)=$(($Value -band 0x3F))")
        }
        "flash_sr" {
            return @(
                "BSY(bit0)=$(Format-Bool (Test-RegBit $Value 0))",
                "PGERR(bit2)=$(Format-Bool (Test-RegBit $Value 2))",
                "WRPRTERR(bit4)=$(Format-Bool (Test-RegBit $Value 4))",
                "EOP(bit5)=$(Format-Bool (Test-RegBit $Value 5))"
            )
        }
        "flash_cr" {
            return @(
                "PG(bit0)=$(Format-Bool (Test-RegBit $Value 0))",
                "PER(bit1)=$(Format-Bool (Test-RegBit $Value 1))",
                "STRT(bit6)=$(Format-Bool (Test-RegBit $Value 6))",
                "LOCK(bit7)=$(Format-Bool (Test-RegBit $Value 7))"
            )
        }
    }

    return @("decode=raw")
}

function Parse-ReadValue([string[]]$RawOutput, [string]$Address) {
    $text = $RawOutput -join "`n"
    $matches = @([regex]::Matches($text, "0x[0-9A-Fa-f]{8}") | ForEach-Object { $_.Value })
    if ($matches.Count -eq 0) { return $null }

    $addressLower = $Address.ToLowerInvariant()
    $candidate = $null
    foreach ($match in $matches) {
        if ($match.ToLowerInvariant() -ne $addressLower) {
            $candidate = $match
        }
    }

    if (-not $candidate) {
        $candidate = $matches[$matches.Count - 1]
    }
    return Convert-HexToUInt32 $candidate
}

$targets = Expand-ProbeTargets $Target
$registers = Get-RegisterPlan $targets
$connectTokens = Split-ConnectArgs $Connect
$results = @()

Write-Host "[F103-REG] targets=$($targets -join ',')"
Write-Host "[F103-REG] programmer=$Programmer connect=$Connect"
Write-Host "[F103-REG] read-only SWD probe; no register writes are issued"

foreach ($reg in $registers) {
    $readArgs = @("-c") + $connectTokens + @("-r32", $reg.address, "1")
    $rawOutput = @()
    $exitCode = 0
    $value = $null

    if ($DryRun) {
        Write-Host "[DRY-RUN] $Programmer $($readArgs -join ' ')"
    } else {
        try {
            $rawOutput = @(& $Programmer @readArgs 2>&1)
            $exitCode = $LASTEXITCODE
            foreach ($line in $rawOutput) { Write-Host $line }
            if ($exitCode -eq 0) {
                $value = Parse-ReadValue $rawOutput $reg.address
            }
        } catch {
            $rawOutput = @($_.Exception.Message)
            $exitCode = 127
            Write-Host "[F103-REG] ERROR: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    $decode = Get-DecodeLines $reg.decoder $value
    if ($null -ne $value) {
        Write-Host ("[F103-REG] {0} {1} = 0x{2:X8}" -f $reg.name, $reg.address, $value)
    } else {
        Write-Host "[F103-REG] $($reg.name) $($reg.address) = <not captured>"
    }
    foreach ($line in $decode) { Write-Host "          $line" }

    $results += [pscustomobject]@{
        target = $reg.target
        name = $reg.name
        address = $reg.address
        value = if ($null -eq $value) { $null } else { "0x{0:X8}" -f $value }
        decode = $decode
        result = if ($DryRun) { "DRY_RUN" } elseif ($exitCode -eq 0 -and $null -ne $value) { "PASS" } else { "FAIL" }
        exit_code = if ($DryRun) { 0 } else { $exitCode }
        raw = $rawOutput
    }
}

$failed = @($results | Where-Object { $_.result -eq "FAIL" })
$overall = if ($DryRun) {
    "DRY_RUN"
} elseif ($failed.Count -eq 0) {
    "PASS"
} else {
    "FAIL"
}

if ($OutputJson) {
    $parent = Split-Path -Parent $OutputJson
    if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }

    [ordered]@{
        test = "register_probe_f103"
        result = $overall
        targets = $targets
        programmer = $Programmer
        connect = $Connect
        registers = $results
    } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputJson -Encoding utf8
}

Write-Host "[F103-REG-RESULT] $overall"
if ($overall -eq "FAIL") {
    exit 1
}
