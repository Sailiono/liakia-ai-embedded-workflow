param(
    [Alias("Preset")]
    [ValidateSet("Debug", "Release")]
    [string]$BuildPreset = "Debug",
    [string]$ComPort = "COM4",
    [string]$RtcmPort = "COM6",
    [string]$UsbPort = "",
    [int]$RtcmReadSecs = 10,
    [string]$OutputDir = "evidence-out\baseline",
    [string]$ConnectArgs = "port=SWD freq=4000",
    [string]$RegisterProbeScript = "",
    [int]$ScriptTimeoutSec = 300,
    [switch]$AllowDangerousShellCommands,
    [switch]$SkipFunctionalTest,
    [switch]$SkipRtcm,
    [switch]$SkipUsbCdcReset,
    [switch]$SkipRegisterProbe,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSCommandPath
$repoRoot = Split-Path -Parent $repoRoot
$resolvedOutputDir = if ([System.IO.Path]::IsPathRooted($OutputDir)) {
    $OutputDir
} else {
    Join-Path $repoRoot $OutputDir
}
$logDir = Join-Path $resolvedOutputDir "logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$registerProbeIsTemplate = $false
if (-not $RegisterProbeScript) {
    $candidate = Join-Path $repoRoot "tools\register_probe.ps1"
    if (Test-Path -LiteralPath $candidate) {
        $RegisterProbeScript = $candidate
    } else {
        $RegisterProbeScript = Join-Path $repoRoot "workflow-template\register_probe.ps1"
        $registerProbeIsTemplate = $true
    }
} elseif ($RegisterProbeScript -match "workflow-template[\\/]+register_probe\.ps1$") {
    $registerProbeIsTemplate = $true
}

function Resolve-Pwsh {
    $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($pwsh) { return $pwsh.Source }

    $powershell = Get-Command powershell.exe -ErrorAction SilentlyContinue
    if ($powershell) { return $powershell.Source }

    throw "PowerShell executable not found."
}

function Quote-ProcessArgument([string]$Value) {
    if ($null -eq $Value) { return '""' }
    if ($Value -match '[\s"]') {
        return '"' + ($Value -replace '"', '\"') + '"'
    }
    return $Value
}

function Invoke-OptionalTextCommand([string]$Exe, [string[]]$Arguments) {
    try {
        $output = & $Exe @Arguments 2>$null
        if ($null -eq $output) { return "" }
        return (($output | ForEach-Object { [string]$_ }) -join "`n").Trim()
    } catch {
        return ""
    }
}

function Get-GitInfo {
    $commit = Invoke-OptionalTextCommand "git" @("-C", $repoRoot, "rev-parse", "HEAD")
    $short = Invoke-OptionalTextCommand "git" @("-C", $repoRoot, "rev-parse", "--short", "HEAD")
    $branch = Invoke-OptionalTextCommand "git" @("-C", $repoRoot, "rev-parse", "--abbrev-ref", "HEAD")
    $status = Invoke-OptionalTextCommand "git" @("-C", $repoRoot, "status", "--porcelain")

    return [ordered]@{
        commit = $commit
        short_commit = $short
        branch = $branch
        dirty = -not [string]::IsNullOrWhiteSpace($status)
    }
}

function Get-ToolVersions {
    $cmakeVersion = Invoke-OptionalTextCommand "cmake" @("--version")
    $cmakeFirstLine = if ($cmakeVersion) { @($cmakeVersion -split "\r?\n")[0] } else { "" }
    $programmerCommand = Get-Command "STM32_Programmer_CLI.exe" -ErrorAction SilentlyContinue

    return [ordered]@{
        cmake = $cmakeFirstLine
        stm32_programmer_cli = if ($programmerCommand) { $programmerCommand.Source } else { "" }
        powershell = $PSVersionTable.PSVersion.ToString()
    }
}

function Get-ArtifactInfo([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    $item = Get-Item -LiteralPath $Path
    $hash = Get-FileHash -LiteralPath $Path -Algorithm SHA256
    return [ordered]@{
        path = $Path
        size_bytes = $item.Length
        sha256 = $hash.Hash.ToLowerInvariant()
        last_write_time = $item.LastWriteTime.ToString("o")
    }
}

function Get-FirmwareArtifacts {
    $buildDir = Join-Path $repoRoot ("build\{0}" -f $BuildPreset)
    $candidateNames = @("dpiny-RTK.elf", "dpiny-RTK.hex", "dpiny-RTK.bin")
    $artifacts = [ordered]@{}
    foreach ($name in $candidateNames) {
        $path = Join-Path $buildDir $name
        $info = Get-ArtifactInfo $path
        if ($info) {
            $key = [System.IO.Path]::GetExtension($name).TrimStart(".")
            $artifacts[$key] = $info
        }
    }
    return $artifacts
}

function Invoke-LoggedScript([string]$Name, [string]$Script, [string[]]$Arguments, [string]$LogPath) {
    Write-Host ""
    Write-Host "== $Name ==" -ForegroundColor Cyan

    if ($DryRun) {
        $line = "[DRY-RUN] $Script $($Arguments -join ' ')"
        Write-Host $line
        Set-Content -LiteralPath $LogPath -Value $line -Encoding utf8
        return [pscustomobject]@{
            name = $Name
            result = "DRY_RUN"
            exit_code = 0
            log = $LogPath
        }
    }

    $pwsh = Resolve-Pwsh
    $processArgs = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $Script) + $Arguments
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $pwsh
    $pinfo.Arguments = (($processArgs | ForEach-Object { Quote-ProcessArgument ([string]$_) }) -join " ")
    $pinfo.RedirectStandardOutput = $true
    $pinfo.RedirectStandardError = $true
    $pinfo.UseShellExecute = $false
    $pinfo.CreateNoWindow = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $pinfo
    [void]$process.Start()
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()

    $timedOut = $false
    if (-not $process.WaitForExit($ScriptTimeoutSec * 1000)) {
        $timedOut = $true
        try {
            $process.Kill()
            [void]$process.WaitForExit(5000)
        } catch { }
    }

    $stdout = $stdoutTask.Result
    $stderr = $stderrTask.Result
    $exitCode = if ($timedOut) { -1 } else { $process.ExitCode }
    $output = @()
    if ($stdout) { $output += ($stdout -split "\r?\n") }
    if ($stderr) { $output += ($stderr -split "\r?\n" | ForEach-Object { "STDERR: $_" }) }
    if ($timedOut) {
        $output += "[TIMEOUT] $Name exceeded ${ScriptTimeoutSec}s and was terminated."
    }

    $output | Tee-Object -FilePath $LogPath | ForEach-Object { Write-Host $_ }
    $result = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }

    return [pscustomobject]@{
        name = $Name
        result = $result
        exit_code = $exitCode
        log = $LogPath
    }
}

$steps = @()
$runId = (Get-Date).ToString("yyyyMMdd-HHmmss")
$startedAt = (Get-Date).ToString("o")

if (-not $SkipFunctionalTest) {
    $functionalScript = Join-Path $repoRoot "tools\functional_test.ps1"
    $functionalArgs = @(
        "-BuildPreset", $BuildPreset,
        "-ComPort", $ComPort,
        "-ConnectArgs", $ConnectArgs
    )
    if ($AllowDangerousShellCommands) {
        $functionalArgs += "-AllowDangerousShellCommands"
    } else {
        $functionalArgs += "-SkipPersistence"
    }
    $steps += Invoke-LoggedScript "functional_test" $functionalScript $functionalArgs (Join-Path $logDir "functional_test.log")
}

if (-not $SkipRtcm) {
    $rtcmScript = Join-Path $repoRoot "tools\rtcm_parse.ps1"
    $rtcmSummary = Join-Path $resolvedOutputDir "rtcm_summary.json"
    $rtcmArgs = @(
        "-Port", $RtcmPort,
        "-ReadSecs", ([string]$RtcmReadSecs),
        "-OutputJson", $rtcmSummary
    )
    $steps += Invoke-LoggedScript "rtcm_parse" $rtcmScript $rtcmArgs (Join-Path $logDir "rtcm_parse.log")
}

if ($SkipUsbCdcReset) {
    $logPath = Join-Path $logDir "usb_cdc_reset.log"
    $msg = "[USB-CDC] SKIP_DISABLED: reset recovery gate disabled by -SkipUsbCdcReset"
    Write-Host $msg -ForegroundColor Yellow
    Set-Content -LiteralPath $logPath -Value $msg -Encoding utf8
    $steps += [pscustomobject]@{
        name = "usb_cdc_reset"
        result = "SKIP_DISABLED"
        exit_code = $null
        log = $logPath
    }
} elseif (-not $UsbPort) {
    $logPath = Join-Path $logDir "usb_cdc_reset.log"
    $msg = "[USB-CDC] SKIP_NO_USB_PORT: pass -UsbPort COMx to enable reset recovery gate"
    Write-Host $msg -ForegroundColor Yellow
    Set-Content -LiteralPath $logPath -Value $msg -Encoding utf8
    $steps += [pscustomobject]@{
        name = "usb_cdc_reset"
        result = "SKIP_NO_USB_PORT"
        exit_code = $null
        log = $logPath
    }
} elseif (-not $AllowDangerousShellCommands) {
    $logPath = Join-Path $logDir "usb_cdc_reset.log"
    $msg = "[USB-CDC] SKIP_REQUIRES_ALLOW_DANGEROUS: reset recovery gate sends shell reset; pass -AllowDangerousShellCommands to enable it"
    Write-Host $msg -ForegroundColor Yellow
    Set-Content -LiteralPath $logPath -Value $msg -Encoding utf8
    $steps += [pscustomobject]@{
        name = "usb_cdc_reset"
        result = "SKIP_REQUIRES_ALLOW_DANGEROUS"
        exit_code = $null
        log = $logPath
    }
} else {
    $usbScript = Join-Path $repoRoot "tools\usb_cdc_reset_test.ps1"
    if (Test-Path -LiteralPath $usbScript) {
        $usbSummary = Join-Path $resolvedOutputDir "usb_cdc_reset_summary.json"
        $usbArgs = @(
            "-UsbPort", $UsbPort,
            "-OutputJson", $usbSummary,
            "-AllowDangerousShellCommands"
        )
        $steps += Invoke-LoggedScript "usb_cdc_reset" $usbScript $usbArgs (Join-Path $logDir "usb_cdc_reset.log")
    } else {
        $logPath = Join-Path $logDir "usb_cdc_reset.log"
        $msg = "[USB-CDC] SKIP_SCRIPT_MISSING: reset recovery script not found: $usbScript"
        Write-Host $msg -ForegroundColor Yellow
        Set-Content -LiteralPath $logPath -Value $msg -Encoding utf8
        $steps += [pscustomobject]@{
            name = "usb_cdc_reset"
            result = "SKIP_SCRIPT_MISSING"
            exit_code = $null
            log = $logPath
        }
    }
}

if (-not $SkipRegisterProbe) {
    if (Test-Path -LiteralPath $RegisterProbeScript) {
        $probeSummary = Join-Path $resolvedOutputDir "register_probe_summary.json"
        $probeArgs = @("-Target", "all", "-OutputJson", $probeSummary)
        $probeStep = Invoke-LoggedScript "register_probe" $RegisterProbeScript $probeArgs (Join-Path $logDir "register_probe.log")
        if ($registerProbeIsTemplate -and $probeStep.result -eq "PASS") {
            $probeStep.result = "TEMPLATE_PASS"
        } elseif ($registerProbeIsTemplate -and $probeStep.result -eq "DRY_RUN") {
            $probeStep.result = "TEMPLATE_DRY_RUN"
        }
        $steps += $probeStep
    } else {
        $logPath = Join-Path $logDir "register_probe.log"
        $msg = "[REG] SKIP: register probe script not found: $RegisterProbeScript"
        Write-Host $msg -ForegroundColor Yellow
        Set-Content -LiteralPath $logPath -Value $msg -Encoding utf8
        $steps += [pscustomobject]@{
            name = "register_probe"
            result = "SKIP"
            exit_code = $null
            log = $logPath
        }
    }
}

$summaryFiles = @(Get-ChildItem -LiteralPath $resolvedOutputDir -Filter "*_summary.json" -File -Recurse -ErrorAction SilentlyContinue)
$testResults = @()
foreach ($file in $summaryFiles) {
    try {
        $testResults += (Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json)
    } catch {
        $testResults += [pscustomobject]@{
            file = $file.FullName
            result = "UNREADABLE"
            error = $_.Exception.Message
        }
    }
}

$failedSteps = @($steps | Where-Object { $_.result -eq "FAIL" })
$artifacts = Get-FirmwareArtifacts
$gitInfo = Get-GitInfo
$toolVersions = Get-ToolVersions
$safety = [ordered]@{
    dangerous_shell_commands_require_explicit_allow = $true
    dangerous_shell_commands_allowed = [bool]$AllowDangerousShellCommands
    functional_persistence_gate = if ($AllowDangerousShellCommands) { "ENABLED" } else { "SKIPPED_BY_DEFAULT" }
    usb_cdc_reset_gate = if ($SkipUsbCdcReset) {
        "SKIP_DISABLED"
    } elseif (-not $UsbPort) {
        "SKIP_NO_USB_PORT"
    } elseif ($AllowDangerousShellCommands) {
        "ENABLED"
    } else {
        "SKIP_REQUIRES_ALLOW_DANGEROUS"
    }
    dangerous_shell_commands = @("baud", "save", "reset", "erase", "bootloader")
}
$manifest = [ordered]@{
    schema_version = "liakia.baseline.v1"
    workflow = "baseline"
    run_id = $runId
    started_at = $startedAt
    ended_at = (Get-Date).ToString("o")
    runner = "tools/run_test_baseline.ps1"
    build_preset = $BuildPreset
    com_port = $ComPort
    rtcm_port = $RtcmPort
    usb_port = $UsbPort
    output_dir = $resolvedOutputDir
    dry_run = [bool]$DryRun
    git = $gitInfo
    tools = $toolVersions
    artifacts = $artifacts
    safety = $safety
    steps = $steps
    test_results = $testResults
    result = if ($failedSteps.Count -eq 0) { "PASS" } else { "FAIL" }
}

$manifestPath = Join-Path $resolvedOutputDir "manifest.json"
$manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding utf8

$testSummary = [ordered]@{
    schema_version = "liakia.test_summary.v1"
    run_id = $runId
    result = $manifest.result
    git = $gitInfo
    artifacts = $artifacts
    safety = $safety
    steps = $steps
    gates = $testResults
    failed_steps = @($failedSteps | ForEach-Object { $_.name })
}
$testSummaryPath = Join-Path $resolvedOutputDir "test_summary.json"
$testSummary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $testSummaryPath -Encoding utf8

Write-Host ""
Write-Host "[BASELINE] manifest=$manifestPath"
Write-Host "[BASELINE] test_summary_json=$testSummaryPath"
Write-Host "[BASELINE-RESULT] $($manifest.result)"

if ($failedSteps.Count -gt 0) {
    exit 1
}
