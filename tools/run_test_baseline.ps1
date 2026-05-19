param(
    [ValidateSet("Debug", "Release")]
    [string]$BuildPreset = "Debug",
    [string]$ComPort = "COM4",
    [string]$RtcmPort = "COM6",
    [int]$RtcmReadSecs = 10,
    [string]$OutputDir = "evidence-out\baseline",
    [string]$ConnectArgs = "port=SWD freq=4000",
    [string]$RegisterProbeScript = "",
    [switch]$SkipFunctionalTest,
    [switch]$SkipRtcm,
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

if (-not $RegisterProbeScript) {
    $candidate = Join-Path $repoRoot "tools\register_probe.ps1"
    if (Test-Path -LiteralPath $candidate) {
        $RegisterProbeScript = $candidate
    } else {
        $RegisterProbeScript = Join-Path $repoRoot "workflow-template\register_probe.ps1"
    }
}

function Resolve-Pwsh {
    $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($pwsh) { return $pwsh.Source }

    $powershell = Get-Command powershell.exe -ErrorAction SilentlyContinue
    if ($powershell) { return $powershell.Source }

    throw "PowerShell executable not found."
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
    & $pwsh @processArgs 2>&1 | Tee-Object -FilePath $LogPath
    $exitCode = $LASTEXITCODE
    $result = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }

    return [pscustomobject]@{
        name = $Name
        result = $result
        exit_code = $exitCode
        log = $LogPath
    }
}

$steps = @()
$startedAt = (Get-Date).ToString("s")

if (-not $SkipFunctionalTest) {
    $functionalScript = Join-Path $repoRoot "tools\functional_test.ps1"
    $functionalArgs = @(
        "-BuildPreset", $BuildPreset,
        "-ComPort", $ComPort,
        "-ConnectArgs", $ConnectArgs
    )
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

if (-not $SkipRegisterProbe) {
    if (Test-Path -LiteralPath $RegisterProbeScript) {
        $probeArgs = @("-Target", "all")
        $steps += Invoke-LoggedScript "register_probe" $RegisterProbeScript $probeArgs (Join-Path $logDir "register_probe.log")
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
$manifest = [ordered]@{
    workflow = "baseline"
    started_at = $startedAt
    ended_at = (Get-Date).ToString("s")
    build_preset = $BuildPreset
    com_port = $ComPort
    rtcm_port = $RtcmPort
    output_dir = $resolvedOutputDir
    dry_run = [bool]$DryRun
    steps = $steps
    test_results = $testResults
    result = if ($failedSteps.Count -eq 0) { "PASS" } else { "FAIL" }
}

$manifestPath = Join-Path $resolvedOutputDir "manifest.json"
$manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding utf8
Write-Host ""
Write-Host "[BASELINE] manifest=$manifestPath"
Write-Host "[BASELINE-RESULT] $($manifest.result)"

if ($failedSteps.Count -gt 0) {
    exit 1
}
