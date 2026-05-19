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
    $validTargets = @("rcc", "gpio", "usart", "usb", "fault", "all")
    $requestedTargets = @()
    foreach ($item in $Targets) {
        foreach ($part in ([string]$item -split ",")) {
            $trimmed = $part.Trim()
            if ($trimmed.Length -gt 0) {
                if ($validTargets -notcontains $trimmed) {
                    throw "Invalid register probe target '$trimmed'. Valid targets: $($validTargets -join ', ')"
                }
                $requestedTargets += $trimmed
            }
        }
    }

    if ($requestedTargets -contains "all") {
        return @("fault", "rcc", "gpio", "usart", "usb")
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
                $plan += New-Reg "rcc" "RCC_APB1ENR" "0x40023840" "rcc_apb1enr"
                $plan += New-Reg "rcc" "RCC_APB2ENR" "0x40023844" "rcc_apb2enr"
                $plan += New-Reg "rcc" "RCC_CSR" "0x40023874" "rcc_csr"
            }
            "gpio" {
                $plan += New-Reg "gpio" "GPIOD_MODER" "0x40020C00" "gpiod_moder"
                $plan += New-Reg "gpio" "GPIOD_AFRL" "0x40020C20" "gpiod_afrl"
                $plan += New-Reg "gpio" "GPIOD_AFRH" "0x40020C24" "gpiod_afrh"
            }
            "usart" {
                $plan += New-Reg "usart" "USART2_BRR" "0x40004408" "usart_brr"
                $plan += New-Reg "usart" "USART2_CR1" "0x4000440C" "usart_cr1"
                $plan += New-Reg "usart" "USART3_BRR" "0x40004808" "usart_brr"
                $plan += New-Reg "usart" "USART3_CR1" "0x4000480C" "usart_cr1"
            }
            "usb" {
                $plan += New-Reg "usb" "USB_OTG_FS_DSTS" "0x50000808" "usb_dsts"
            }
        }
    }
    return $plan
}

function Split-ConnectArgs([string]$ConnectValue) {
    $tokens = @()
    foreach ($token in ($ConnectValue -split "\s+")) {
        if ($token.Trim().Length -gt 0) {
            $tokens += $token.Trim()
        }
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

function Get-GpioMode([uint32]$Value, [int]$Pin) {
    $mode = ($Value -shr ($Pin * 2)) -band 0x3
    switch ($mode) {
        0 { "Input" }
        1 { "Output" }
        2 { "AF" }
        3 { "Analog" }
    }
}

function Get-GpioAf([uint32]$Value, [int]$PinBase, [int]$Pin) {
    return (($Value -shr (($Pin - $PinBase) * 4)) -band 0xF)
}

function Get-DecodeLines([string]$Decoder, [Nullable[uint32]]$Value) {
    if ($null -eq $Value) {
        return @("decode=pending")
    }

    switch ($Decoder) {
        "dhcsr" {
            return @(
                "S_HALT(bit17)=$(Format-Bool (Test-RegBit $Value 17))",
                "S_SLEEP(bit18)=$(Format-Bool (Test-RegBit $Value 18))",
                "S_LOCKUP(bit19)=$(Format-Bool (Test-RegBit $Value 19))",
                "S_RESET_ST(bit25)=$(Format-Bool (Test-RegBit $Value 25))"
            )
        }
        "rcc_apb1enr" {
            return @(
                "USART2EN(bit17)=$(Format-Bool (Test-RegBit $Value 17))",
                "USART3EN(bit18)=$(Format-Bool (Test-RegBit $Value 18))"
            )
        }
        "rcc_apb2enr" {
            return @(
                "USART1EN(bit4)=$(Format-Bool (Test-RegBit $Value 4))",
                "SYSCFGEN(bit14)=$(Format-Bool (Test-RegBit $Value 14))"
            )
        }
        "rcc_csr" {
            return @(
                "LSION(bit0)=$(Format-Bool (Test-RegBit $Value 0))",
                "PINRSTF(bit26)=$(Format-Bool (Test-RegBit $Value 26))",
                "PORRSTF(bit27)=$(Format-Bool (Test-RegBit $Value 27))",
                "SFTRSTF(bit28)=$(Format-Bool (Test-RegBit $Value 28))",
                "IWDGRSTF(bit29)=$(Format-Bool (Test-RegBit $Value 29))",
                "WWDGRSTF(bit30)=$(Format-Bool (Test-RegBit $Value 30))",
                "LPWRRSTF(bit31)=$(Format-Bool (Test-RegBit $Value 31))"
            )
        }
        "gpiod_moder" {
            return @(
                "PD5=$(Get-GpioMode $Value 5)",
                "PD6=$(Get-GpioMode $Value 6)",
                "PD8=$(Get-GpioMode $Value 8)",
                "PD9=$(Get-GpioMode $Value 9)"
            )
        }
        "gpiod_afrl" {
            return @(
                "PD5=AF$(Get-GpioAf $Value 0 5)",
                "PD6=AF$(Get-GpioAf $Value 0 6)"
            )
        }
        "gpiod_afrh" {
            return @(
                "PD8=AF$(Get-GpioAf $Value 8 8)",
                "PD9=AF$(Get-GpioAf $Value 8 9)"
            )
        }
        "usart_cr1" {
            return @(
                "UE(bit13)=$(Format-Bool (Test-RegBit $Value 13))",
                "TE(bit3)=$(Format-Bool (Test-RegBit $Value 3))",
                "RE(bit2)=$(Format-Bool (Test-RegBit $Value 2))"
            )
        }
        "usart_brr" {
            return @("BRR=0x{0:X8}" -f $Value)
        }
        "usb_dsts" {
            return @(
                "SUSPSTS(bit0)=$(Format-Bool (Test-RegBit $Value 0))",
                "ENUMSPD(bits2:1)=$((($Value -shr 1) -band 0x3))",
                "FNSOF(bits21:8)=$((($Value -shr 8) -band 0x3FFF))"
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

Write-Host "[REG] targets=$($targets -join ',')"
Write-Host "[REG] programmer=$Programmer connect=$Connect"
Write-Host "[REG] read-only SWD probe; no register writes are issued"

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
            foreach ($line in $rawOutput) {
                Write-Host $line
            }
            if ($exitCode -eq 0) {
                $value = Parse-ReadValue $rawOutput $reg.address
            }
        } catch {
            $rawOutput = @($_.Exception.Message)
            $exitCode = 127
            Write-Host "[REG] ERROR: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    $decode = Get-DecodeLines $reg.decoder $value
    if ($null -ne $value) {
        Write-Host ("[REG] {0} {1} = 0x{2:X8}" -f $reg.name, $reg.address, $value)
    } else {
        Write-Host "[REG] $($reg.name) $($reg.address) = <not captured>"
    }
    foreach ($line in $decode) {
        Write-Host "      $line"
    }

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
    if ($parent) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }

    [ordered]@{
        test = "register_probe"
        result = $overall
        targets = $targets
        programmer = $Programmer
        connect = $Connect
        registers = $results
    } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputJson -Encoding utf8
}

Write-Host "[REG-RESULT] $overall"
if ($overall -eq "FAIL") {
    exit 1
}
