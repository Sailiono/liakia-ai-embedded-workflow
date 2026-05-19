param(
    [string]$Adapter = ".\project-adapter.yaml",
    [ValidateSet("env", "build", "flash", "test", "probe", "evidence", "all")]
    [string]$Stage = "all",
    [string]$OutputDir = ".\evidence-out",
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Read-AdapterScalar([string]$Path, [string]$Key, [string]$Default = "") {
    $pattern = "^\s*$([regex]::Escape($Key))\s*:\s*(.+?)\s*$"
    $line = Get-Content -LiteralPath $Path | Where-Object { $_ -match $pattern } | Select-Object -First 1
    if (-not $line) { return $Default }
    return (($line -replace $pattern, '$1').Trim('"').Trim("'"))
}

function Invoke-Step([string]$Name, [scriptblock]$Body) {
    Write-Host ""
    Write-Host "== $Name ==" -ForegroundColor Cyan
    & $Body
    Write-Host "[$Name] PASS" -ForegroundColor Green
}

if (-not (Test-Path -LiteralPath $Adapter)) {
    throw "Adapter not found: $Adapter"
}

$adapterFullPath = (Resolve-Path -LiteralPath $Adapter).Path
$adapterRoot = Split-Path -Parent $adapterFullPath
$templateRoot = Split-Path -Parent $PSCommandPath

$projectName = Read-AdapterScalar $adapterFullPath "name" "embedded-project"
$buildDir = Read-AdapterScalar $adapterFullPath "build_dir" "build/Debug"
$elf = Read-AdapterScalar $adapterFullPath "elf" "build/Debug/firmware.elf"
$buildCommand = Read-AdapterScalar $adapterFullPath "command" "ninja"
$flashTool = Read-AdapterScalar $adapterFullPath "tool" "STM32_Programmer_CLI"
$shellPort = Read-AdapterScalar $adapterFullPath "shell_port" "COM4"
$rtcmPort = Read-AdapterScalar $adapterFullPath "rtcm_port" "COM6"
$baudrate = Read-AdapterScalar $adapterFullPath "baudrate" "115200"

Write-Host "[WORKFLOW] adapter=$adapterFullPath"
Write-Host "[WORKFLOW] project=$projectName stage=$Stage output=$OutputDir"

$stages = if ($Stage -eq "all") {
    @("env", "build", "flash", "test", "probe", "evidence")
} else {
    @($Stage)
}

if ($stages -contains "env") {
    Invoke-Step "ENV" {
        Write-Host "PowerShell: $($PSVersionTable.PSVersion)"
        Write-Host "Adapter: $adapterFullPath"
        Write-Host "Build dir: $buildDir"
        Write-Host "ELF: $elf"
        foreach ($cmd in @($buildCommand, $flashTool)) {
            $resolved = Get-Command $cmd -ErrorAction SilentlyContinue
            if ($resolved) {
                Write-Host "[OK] $cmd -> $($resolved.Source)"
            } else {
                Write-Host "[WARN] $cmd not found in PATH"
            }
        }
    }
}

if ($stages -contains "build") {
    Invoke-Step "BUILD" {
        if ($DryRun) {
            Write-Host "[DRY-RUN] .\build.ps1 -BuildDir $buildDir -Command $buildCommand"
        } else {
            & (Join-Path $templateRoot "build.ps1") -BuildDir (Join-Path $adapterRoot $buildDir) -Command $buildCommand
        }
    }
}

if ($stages -contains "flash") {
    Invoke-Step "FLASH" {
        if ($DryRun) {
            Write-Host "[DRY-RUN] .\flash.ps1 -Elf $elf -Programmer $flashTool"
        } else {
            & (Join-Path $templateRoot "flash.ps1") -Elf (Join-Path $adapterRoot $elf) -Programmer $flashTool
        }
    }
}

if ($stages -contains "test") {
    Invoke-Step "TEST" {
        if ($DryRun) {
            Write-Host "[DRY-RUN] .\test_shell.ps1 -Port $shellPort"
            Write-Host "[DRY-RUN] .\rtcm_parse.ps1 -Port $rtcmPort"
        } else {
            & (Join-Path $templateRoot "test_shell.ps1") -Port $shellPort
            & (Join-Path $templateRoot "rtcm_parse.ps1") -Port $rtcmPort
        }
    }
}

if ($stages -contains "probe") {
    Invoke-Step "PROBE" {
        if ($DryRun) {
            Write-Host "[DRY-RUN] .\register_probe.ps1 -Target all"
        } else {
            & (Join-Path $templateRoot "register_probe.ps1") -Target "all"
        }
    }
}

if ($stages -contains "evidence") {
    Invoke-Step "EVIDENCE" {
        New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
        $manifest = Join-Path $OutputDir "manifest.json"
        $json = [ordered]@{
            project = $projectName
            adapter = $adapterFullPath
            generated_at = (Get-Date).ToString("s")
            stage = $Stage
            build_dir = $buildDir
            elf = $elf
            dry_run = [bool]$DryRun
        } | ConvertTo-Json -Depth 4
        Set-Content -LiteralPath $manifest -Value $json -Encoding utf8
        Write-Host "[EVIDENCE] $manifest"
    }
}

Write-Host ""
Write-Host "[WORKFLOW-RESULT] PASS" -ForegroundColor Green
