param(
    [string]$ProjectRoot = ".",
    [string]$BuildCommand = "cmake --build --preset Debug",
    [string]$BuildWorkingDir = ".",
    [string]$Elf = "",
    [string]$Programmer = "STM32_Programmer_CLI",
    [string]$ConnectArgs = "port=SWD freq=4000",
    [string]$ComPort = "COM4",
    [int]$Baud = 115200,
    [ValidateSet("case-a", "case-b", "case-c", "case-d", "generic")]
    [string]$Case = "case-a",
    [string]$OutputDir = "",
    [string]$ExpectedFailureGate = "",
    [switch]$AllowExpectedFailure,
    [switch]$SkipBuild,
    [switch]$SkipFlash,
    [switch]$SkipResetRecovery,
    [switch]$SkipRegisterProbe,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $PSCommandPath
$labRoot = Split-Path -Parent $scriptRoot
$projectFullPath = [System.IO.Path]::GetFullPath((Resolve-Path -LiteralPath $ProjectRoot).Path)
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $resolvedOutputDir = Join-Path $projectFullPath "evidence-out\starter-f103-$timestamp"
} elseif ([System.IO.Path]::IsPathRooted($OutputDir)) {
    $resolvedOutputDir = $OutputDir
} else {
    $resolvedOutputDir = Join-Path $projectFullPath $OutputDir
}

$logDir = Join-Path $resolvedOutputDir "logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$script:steps = @()
$script:rawLogs = @{}

function Resolve-Pwsh {
    $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($pwsh) { return $pwsh.Source }

    $powershell = Get-Command powershell.exe -ErrorAction SilentlyContinue
    if ($powershell) { return $powershell.Source }

    throw "PowerShell executable not found."
}

function Resolve-LabPath([string]$Base, [string]$PathValue) {
    if ([string]::IsNullOrWhiteSpace($PathValue)) { return $PathValue }
    if ([System.IO.Path]::IsPathRooted($PathValue)) { return $PathValue }
    return [System.IO.Path]::GetFullPath((Join-Path $Base $PathValue))
}

function New-Step([string]$Name, [string]$Result, [string]$LogPath, [bool]$Blocking, [object]$Details = $null) {
    $step = [pscustomobject]@{
        name = $Name
        result = $Result
        blocking = $Blocking
        log = $LogPath
        details = $Details
    }
    $script:steps += $step
    return $step
}

function Write-StepLog([string]$LogPath, [string[]]$Lines) {
    $parent = Split-Path -Parent $LogPath
    if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
    $Lines | Set-Content -LiteralPath $LogPath -Encoding utf8
    foreach ($line in $Lines) { Write-Host $line }
}

function Invoke-CommandString([string]$Name, [string]$Command, [string]$WorkingDir, [string]$LogPath, [bool]$Blocking) {
    Write-Host ""
    Write-Host "== $Name ==" -ForegroundColor Cyan

    if ($DryRun) {
        $lines = @("[DRY-RUN] cwd=$WorkingDir", "[DRY-RUN] command=$Command")
        Write-StepLog $LogPath $lines
        return New-Step $Name "DRY_RUN" $LogPath $Blocking @{ command = $Command; cwd = $WorkingDir }
    }

    $pwsh = Resolve-Pwsh
    $escapedDir = $WorkingDir.Replace("'", "''")
    $script = "Set-Location -LiteralPath '$escapedDir'; $Command"
    $output = @(& $pwsh -NoProfile -ExecutionPolicy Bypass -Command $script 2>&1)
    $exitCode = $LASTEXITCODE
    $output | Set-Content -LiteralPath $LogPath -Encoding utf8
    foreach ($line in $output) { Write-Host $line }

    $result = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
    return New-Step $Name $result $LogPath $Blocking @{ command = $Command; cwd = $WorkingDir; exit_code = $exitCode }
}

function Split-ConnectArgs([string]$ConnectValue) {
    $tokens = @()
    foreach ($token in ($ConnectValue -split "\s+")) {
        $trimmed = $token.Trim()
        if ($trimmed.Length -gt 0) { $tokens += $trimmed }
    }
    return $tokens
}

function Invoke-Flash([string]$LogPath) {
    Write-Host ""
    Write-Host "== flash ==" -ForegroundColor Cyan

    if ([string]::IsNullOrWhiteSpace($Elf)) {
        $lines = @("[FLASH] FAIL_NO_ELF: pass -Elf path\to\firmware.elf or use -SkipFlash explicitly")
        Write-StepLog $LogPath $lines
        return New-Step "flash" "FAIL" $LogPath $true @{ elf = $Elf; reason = "missing_elf" }
    }

    $resolvedElf = Resolve-LabPath $projectFullPath $Elf
    if (-not (Test-Path -LiteralPath $resolvedElf)) {
        $lines = @("[FLASH] FAIL: ELF not found: $resolvedElf")
        Write-StepLog $LogPath $lines
        return New-Step "flash" "FAIL" $LogPath $true @{ elf = $resolvedElf }
    }

    $connectTokens = Split-ConnectArgs $ConnectArgs
    $args = @("-c") + $connectTokens + @("-w", $resolvedElf, "-v", "-rst")
    if ($DryRun) {
        $lines = @("[DRY-RUN] $Programmer $($args -join ' ')")
        Write-StepLog $LogPath $lines
        return New-Step "flash" "DRY_RUN" $LogPath $true @{ elf = $resolvedElf; programmer = $Programmer }
    }

    $output = @(& $Programmer @args 2>&1)
    $exitCode = $LASTEXITCODE
    $output | Set-Content -LiteralPath $LogPath -Encoding utf8
    foreach ($line in $output) { Write-Host $line }

    $result = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
    return New-Step "flash" $result $LogPath $true @{ elf = $resolvedElf; programmer = $Programmer; exit_code = $exitCode }
}

function Open-StarterSerial {
    $serial = New-Object System.IO.Ports.SerialPort $ComPort, $Baud, None, 8, One
    $serial.DtrEnable = $true
    $serial.RtsEnable = $true
    $serial.NewLine = "`r`n"
    $serial.ReadTimeout = 200
    $serial.WriteTimeout = 2000
    $serial.Open()
    return $serial
}

function Read-SerialFor([System.IO.Ports.SerialPort]$Serial, [int]$TimeoutMs) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $buffer = ""
    while ($sw.ElapsedMilliseconds -lt $TimeoutMs) {
        try {
            $chunk = $Serial.ReadExisting()
            if ($chunk) { $buffer += $chunk }
        } catch {
        }
        Start-Sleep -Milliseconds 50
    }
    return $buffer
}

function Invoke-SerialCommand([System.IO.Ports.SerialPort]$Serial, [string]$Command, [int]$TimeoutMs) {
    [void](Read-SerialFor $Serial 100)
    $Serial.Write("$Command`r`n")
    Start-Sleep -Milliseconds 100
    return Read-SerialFor $Serial $TimeoutMs
}

function Test-ContainsAll([string]$Text, [string[]]$Keywords) {
    foreach ($keyword in $Keywords) {
        if ($Text -notmatch [regex]::Escape($keyword)) { return $false }
    }
    return $true
}

function Invoke-SerialGate([string]$GateName, [string[]]$Commands, [scriptblock]$Assert, [string]$LogFile, [bool]$Blocking) {
    Write-Host ""
    Write-Host "== $GateName ==" -ForegroundColor Cyan

    if ($DryRun) {
        $lines = @("[DRY-RUN] serial=$ComPort baud=$Baud commands=$($Commands -join ', ')")
        Write-StepLog $LogFile $lines
        return New-Step $GateName "DRY_RUN" $LogFile $Blocking @{ commands = $Commands }
    }

    $serial = $null
    $responses = @()
    try {
        $serial = Open-StarterSerial
        [void](Read-SerialFor $serial 300)
        foreach ($cmd in $Commands) {
            $response = Invoke-SerialCommand $serial $cmd 1200
            $responses += [pscustomobject]@{ command = $cmd; response = $response }
        }
    } catch {
        $responses += [pscustomobject]@{ command = "<open>"; response = $_.Exception.Message }
    } finally {
        if ($serial -and $serial.IsOpen) { $serial.Close() }
    }

    $lines = @()
    foreach ($item in $responses) {
        $lines += ">> $($item.command)"
        $lines += ($item.response -split "`r?`n")
    }
    $text = $lines -join "`n"
    $ok = & $Assert $text
    $result = if ($ok) { "PASS" } else { "FAIL" }
    Write-StepLog $LogFile $lines
    return New-Step $GateName $result $LogFile $Blocking @{ commands = $Commands }
}

function Invoke-ResetRecovery([string]$LogFile) {
    Write-Host ""
    Write-Host "== reset_recovery ==" -ForegroundColor Cyan

    if ($DryRun) {
        $lines = @("[DRY-RUN] reset recovery on $ComPort")
        Write-StepLog $LogFile $lines
        return New-Step "reset_recovery" "DRY_RUN" $LogFile $false @{ port = $ComPort }
    }

    $lines = @()
    $ok = $false
    try {
        $serial = Open-StarterSerial
        $before = Invoke-SerialCommand $serial "version" 1200
        $lines += ">> version"
        $lines += ($before -split "`r?`n")
        $beforeSensor = Invoke-SerialCommand $serial "sensor id" 1200
        $lines += ">> sensor id"
        $lines += ($beforeSensor -split "`r?`n")
        $serial.Write("reset`r`n")
        $lines += ">> reset"
        Start-Sleep -Milliseconds 1800
        if ($serial.IsOpen) { $serial.Close() }

        $serial = Open-StarterSerial
        $after = Invoke-SerialCommand $serial "version" 2000
        $lines += ">> version after reset"
        $lines += ($after -split "`r?`n")
        $afterSensor = Invoke-SerialCommand $serial "sensor id" 2000
        $lines += ">> sensor id after reset"
        $lines += ($afterSensor -split "`r?`n")
        $ok = ((Test-ContainsAll $before @("Liakia", "STM32F103")) -and
               (Test-ContainsAll $after @("Liakia", "STM32F103")) -and
               (Test-ContainsAll $beforeSensor @("SENSOR_ID", "id=0x58", "result=PASS")) -and
               (Test-ContainsAll $afterSensor @("SENSOR_ID", "id=0x58", "result=PASS")))
    } catch {
        $lines += "[ERROR] $($_.Exception.Message)"
    } finally {
        if ($serial -and $serial.IsOpen) { $serial.Close() }
    }

    $result = if ($ok) { "PASS" } else { "FAIL" }
    Write-StepLog $LogFile $lines
    return New-Step "reset_recovery" $result $LogFile $false @{ port = $ComPort }
}

function Invoke-RegisterProbe([string]$LogPath) {
    Write-Host ""
    Write-Host "== register_probe ==" -ForegroundColor Cyan

    $probeScript = Join-Path $scriptRoot "register_probe_f103.ps1"
    $summary = Join-Path $resolvedOutputDir "register_probe_summary.json"
    $connect = if ($ConnectArgs -match "mode=") { $ConnectArgs } else { "$ConnectArgs mode=HotPlug" }
    $args = @("-Target", "all", "-Programmer", $Programmer, "-Connect", $connect, "-OutputJson", $summary)
    if ($DryRun) { $args += "-DryRun" }

    $pwsh = Resolve-Pwsh
    $output = @(& $pwsh -NoProfile -ExecutionPolicy Bypass -File $probeScript @args 2>&1)
    $exitCode = $LASTEXITCODE
    $output | Set-Content -LiteralPath $LogPath -Encoding utf8
    foreach ($line in $output) { Write-Host $line }

    $result = if ($exitCode -eq 0) { if ($DryRun) { "DRY_RUN" } else { "PASS" } } else { "FAIL" }
    return New-Step "register_probe" $result $LogPath $false @{ summary = $summary; exit_code = $exitCode }
}

function Write-Manifest {
    $blockingFailures = @($script:steps | Where-Object { $_.blocking -and $_.result -eq "FAIL" })
    $allFailures = @($script:steps | Where-Object { $_.result -eq "FAIL" })
    $expectedMatch = $false
    if ($AllowExpectedFailure -and $ExpectedFailureGate) {
        $expectedMatch = (@($allFailures | Where-Object { $_.name -eq $ExpectedFailureGate }).Count -gt 0)
    }

    $result = if ($blockingFailures.Count -eq 0 -and $allFailures.Count -eq 0) {
        "PASS"
    } elseif ($expectedMatch) {
        "EXPECTED_FAIL"
    } elseif ($blockingFailures.Count -eq 0) {
        "PASS_WITH_WARNINGS"
    } else {
        "FAIL"
    }

    $manifest = [ordered]@{
        project = "Liakia Starter-F103 Sensor Lab"
        case = $Case
        timestamp_start = $script:startedAt
        timestamp_end = (Get-Date).ToString("s")
        project_root = $projectFullPath
        output_dir = $resolvedOutputDir
        hardware = [ordered]@{
            mcu = "STM32F103C8T6"
            sensor = "BMP280"
            shell_uart = $ComPort
            baud = $Baud
            debug_probe = $Programmer
        }
        build = [ordered]@{
            command = $BuildCommand
            working_dir = (Resolve-LabPath $projectFullPath $BuildWorkingDir)
        }
        flash = [ordered]@{
            elf = $Elf
            connect = $ConnectArgs
        }
        expected_failure_gate = $ExpectedFailureGate
        allow_expected_failure = [bool]$AllowExpectedFailure
        steps = $script:steps
        result = $result
    }

    $manifestPath = Join-Path $resolvedOutputDir "00_manifest.json"
    $manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding utf8

    $summaryPath = Join-Path $resolvedOutputDir "test_summary.md"
    $summary = @(
        "# Starter-F103 Test Summary",
        "",
        "Result: $result",
        "",
        "Case: $Case",
        "",
        "| Step | Result | Blocking |",
        "|---|---|---|"
    )
    foreach ($step in $script:steps) {
        $summary += "| $($step.name) | $($step.result) | $($step.blocking) |"
    }
    $summary | Set-Content -LiteralPath $summaryPath -Encoding utf8

    Write-Host ""
    Write-Host "[STARTER-F103] manifest=$manifestPath"
    Write-Host "[STARTER-F103] summary=$summaryPath"
    Write-Host "[STARTER-F103-RESULT] $result"
    return $result
}

$script:startedAt = (Get-Date).ToString("s")

New-Step "environment" "PASS" $null $true @{
    project_root = $projectFullPath
    output_dir = $resolvedOutputDir
    com_port = $ComPort
    baud = $Baud
} | Out-Null

if ($SkipBuild) {
    New-Step "build" "SKIP_DISABLED" $null $true @{ reason = "SkipBuild" } | Out-Null
} else {
    $buildDir = Resolve-LabPath $projectFullPath $BuildWorkingDir
    Invoke-CommandString "build" $BuildCommand $buildDir (Join-Path $logDir "02_build.log") $true | Out-Null
}

if ($SkipFlash) {
    New-Step "flash" "SKIP_DISABLED" $null $false @{ reason = "SkipFlash" } | Out-Null
} else {
    Invoke-Flash (Join-Path $logDir "03_flash.log") | Out-Null
}

Invoke-SerialGate "shell" @("version", "led on", "led off") {
    param($Text)
    return ((Test-ContainsAll $Text @("Liakia", "STM32F103")) -and (Test-ContainsAll $Text @("LED PASS state=on", "LED PASS state=off")))
} (Join-Path $logDir "04_shell.log") $true | Out-Null

Invoke-SerialGate "i2c_scan" @("diag i2c") {
    param($Text)
    return (($Text -match "I2C_SCAN found=0x(76|77)") -and ($Text -match "I2C_SCAN result=PASS"))
} (Join-Path $logDir "05_i2c_scan.log") $true | Out-Null

Invoke-SerialGate "sensor_id" @("sensor id") {
    param($Text)
    return (($Text -match "SENSOR_ID") -and ($Text -match "id=0x58") -and ($Text -match "result=PASS"))
} (Join-Path $logDir "06_sensor_id.log") $true | Out-Null

Invoke-SerialGate "data_quality" @("sensor read") {
    param($Text)
    return (($Text -match "DATA_QUALITY result=PASS") -or ($Text -match "COMP_TEMP.*result=PASS"))
} (Join-Path $logDir "07_data_quality.log") $true | Out-Null

Invoke-SerialGate "telemetry_crc" @("telemetry once") {
    param($Text)
    return (($Text -match "TELEMETRY") -and ($Text -match "crc=") -and ($Text -match "result=PASS"))
} (Join-Path $logDir "08_telemetry_crc.log") $true | Out-Null

if ($SkipResetRecovery) {
    New-Step "reset_recovery" "SKIP_DISABLED" $null $false @{ reason = "SkipResetRecovery" } | Out-Null
} else {
    Invoke-ResetRecovery (Join-Path $logDir "09_reset_recovery.log") | Out-Null
}

if ($SkipRegisterProbe) {
    New-Step "register_probe" "SKIP_DISABLED" $null $false @{ reason = "SkipRegisterProbe" } | Out-Null
} else {
    Invoke-RegisterProbe (Join-Path $logDir "10_register_probe.log") | Out-Null
}

$final = Write-Manifest

if ($final -eq "FAIL") { exit 1 }
exit 0
