param(
    [string]$Adapter = ".\project-adapter.json",
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

function Convert-ArgsObjectToHashtable($ArgsObject) {
    $result = @{}
    if (-not $ArgsObject) { return $result }

    foreach ($prop in $ArgsObject.PSObject.Properties) {
        $result[$prop.Name] = $prop.Value
    }
    return $result
}

function Resolve-WorkflowPath([string]$Root, [string]$PathValue) {
    if ([string]::IsNullOrWhiteSpace($PathValue)) { return $PathValue }
    if ([System.IO.Path]::IsPathRooted($PathValue)) { return $PathValue }
    return [System.IO.Path]::GetFullPath((Join-Path $Root $PathValue))
}

function Has-Property($Object, [string]$Name) {
    return ($Object -and ($Object.PSObject.Properties.Name -contains $Name))
}

function Invoke-Step([string]$Name, [scriptblock]$Body) {
    Write-Host ""
    Write-Host "== $Name ==" -ForegroundColor Cyan
    & $Body
    Write-Host "[$Name] PASS" -ForegroundColor Green
}

function Load-Adapter([string]$Path) {
    $ext = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()
    if ($ext -eq ".json") {
        return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    }

    Write-Host "[WARN] YAML adapter support is limited to scalar fields. Use project-adapter.json for adapter-driven tests." -ForegroundColor Yellow
    return $null
}

if (-not (Test-Path -LiteralPath $Adapter)) {
    throw "Adapter not found: $Adapter"
}

$adapterFullPath = (Resolve-Path -LiteralPath $Adapter).Path
$adapterDir = Split-Path -Parent $adapterFullPath
$templateRoot = Split-Path -Parent $PSCommandPath
$config = Load-Adapter $adapterFullPath

if ($config) {
    $projectName = $config.project.name
    $projectRootValue = if (Has-Property $config.project "root") { $config.project.root } else { "." }
    $projectRoot = Resolve-WorkflowPath $adapterDir $projectRootValue
    $buildDir = if (Has-Property $config.build "working_dir") { $config.build.working_dir } else { $config.project.build_dir }
    $elf = $config.project.elf
    $buildCommand = $config.build.command
    $flashTool = $config.flash.tool
    $connectArgs = if (Has-Property $config.flash "connect") { $config.flash.connect } else { "port=SWD freq=4000" }
    $tests = if (Has-Property $config "tests") { @($config.tests) } else { @() }
    $probeTargets = if ((Has-Property $config "register_probe") -and (Has-Property $config.register_probe "targets")) { $config.register_probe.targets -join "," } else { "all" }
} else {
    $projectName = Read-AdapterScalar $adapterFullPath "name" "embedded-project"
    $projectRootValue = Read-AdapterScalar $adapterFullPath "root" "."
    $projectRoot = Resolve-WorkflowPath $adapterDir $projectRootValue
    $buildDir = Read-AdapterScalar $adapterFullPath "build_dir" "build/Debug"
    $elf = Read-AdapterScalar $adapterFullPath "elf" "build/Debug/firmware.elf"
    $buildCommand = Read-AdapterScalar $adapterFullPath "command" "ninja"
    $flashTool = Read-AdapterScalar $adapterFullPath "tool" "STM32_Programmer_CLI"
    $connectArgs = "port=SWD freq=4000"
    $tests = @()
    $probeTargets = "all"
}

Write-Host "[WORKFLOW] adapter=$adapterFullPath"
Write-Host "[WORKFLOW] project=$projectName stage=$Stage output=$OutputDir"
Write-Host "[WORKFLOW] project_root=$projectRoot"

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
        $resolvedBuildDir = Resolve-WorkflowPath $projectRoot $buildDir
        if ($DryRun) {
            Write-Host "[DRY-RUN] .\build.ps1 -BuildDir $resolvedBuildDir -Command $buildCommand"
        } else {
            & (Join-Path $templateRoot "build.ps1") -BuildDir $resolvedBuildDir -Command $buildCommand
        }
    }
}

if ($stages -contains "flash") {
    Invoke-Step "FLASH" {
        $resolvedElf = Resolve-WorkflowPath $projectRoot $elf
        if ($DryRun) {
            Write-Host "[DRY-RUN] .\flash.ps1 -Elf $resolvedElf -Programmer $flashTool -Connect `"$connectArgs`""
        } else {
            & (Join-Path $templateRoot "flash.ps1") -Elf $resolvedElf -Programmer $flashTool -Connect $connectArgs
        }
    }
}

if ($stages -contains "test") {
    Invoke-Step "TEST" {
        if ($tests.Count -eq 0) {
            Write-Host "[WARN] No adapter tests found. Add a tests array to the JSON adapter." -ForegroundColor Yellow
        }

        foreach ($test in $tests) {
            $testName = $test.name
            $scriptPath = Resolve-WorkflowPath $projectRoot $test.script
            $testArgs = Convert-ArgsObjectToHashtable $test.args

            if ($testArgs.ContainsKey("OutputJson")) {
                $testArgs["OutputJson"] = Resolve-WorkflowPath $projectRoot ([string]$testArgs["OutputJson"])
            }

            if ($DryRun) {
                $argText = ($testArgs.GetEnumerator() | ForEach-Object { "-$($_.Key) $($_.Value)" }) -join " "
                Write-Host "[DRY-RUN] $scriptPath $argText"
            } else {
                if (-not (Test-Path -LiteralPath $scriptPath)) {
                    throw "Test script not found for '$testName': $scriptPath"
                }
                & $scriptPath @testArgs
            }
        }
    }
}

if ($stages -contains "probe") {
    Invoke-Step "PROBE" {
        if ($DryRun) {
            Write-Host "[DRY-RUN] .\register_probe.ps1 -Target $probeTargets"
        } else {
            & (Join-Path $templateRoot "register_probe.ps1") -Target $probeTargets
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
            project_root = $projectRoot
            generated_at = (Get-Date).ToString("s")
            stage = $Stage
            build_dir = $buildDir
            elf = $elf
            tests = @($tests | ForEach-Object { $_.name })
            dry_run = [bool]$DryRun
        } | ConvertTo-Json -Depth 6
        Set-Content -LiteralPath $manifest -Value $json -Encoding utf8
        Write-Host "[EVIDENCE] $manifest"
    }
}

Write-Host ""
Write-Host "[WORKFLOW-RESULT] PASS" -ForegroundColor Green
