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

function Convert-HashtableToArgumentList([hashtable]$ArgsTable) {
    $result = @()
    foreach ($entry in ($ArgsTable.GetEnumerator() | Sort-Object Name)) {
        $key = [string]$entry.Key
        $value = $entry.Value
        if ($null -eq $value) { continue }

        if ($value -is [bool]) {
            if ($value) {
                $result += "-$key"
            }
            continue
        }

        $result += "-$key"
        if (($value -is [System.Collections.IEnumerable]) -and -not ($value -is [string])) {
            foreach ($item in @($value)) {
                $result += [string]$item
            }
        } else {
            $result += [string]$value
        }
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

function Resolve-Pwsh {
    $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($pwsh) { return $pwsh.Source }

    $powershell = Get-Command powershell.exe -ErrorAction SilentlyContinue
    if ($powershell) { return $powershell.Source }

    throw "PowerShell executable not found."
}

function Invoke-WorkflowScript([string]$Name, [string]$Script, [hashtable]$Arguments, [string]$LogPath) {
    $parent = Split-Path -Parent $LogPath
    if ($parent) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }

    $argList = Convert-HashtableToArgumentList $Arguments
    if ($DryRun) {
        $line = "[DRY-RUN] $Script $($argList -join ' ')"
        Write-Host $line
        Set-Content -LiteralPath $LogPath -Value $line -Encoding utf8
        return [pscustomobject]@{
            name = $Name
            script = $Script
            result = "DRY_RUN"
            exit_code = 0
            log = $LogPath
        }
    }

    if (-not (Test-Path -LiteralPath $Script)) {
        $msg = "Script not found for '$Name': $Script"
        Write-Host "[FAIL] $msg" -ForegroundColor Red
        Set-Content -LiteralPath $LogPath -Value $msg -Encoding utf8
        return [pscustomobject]@{
            name = $Name
            script = $Script
            result = "FAIL"
            exit_code = 127
            log = $LogPath
        }
    }

    $pwsh = Resolve-Pwsh
    $processArgs = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $Script) + $argList
    $output = @(& $pwsh @processArgs 2>&1)
    $exitCode = $LASTEXITCODE
    $output | Tee-Object -FilePath $LogPath | ForEach-Object { Write-Host $_ }

    return [pscustomobject]@{
        name = $Name
        script = $Script
        result = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
        exit_code = $exitCode
        log = $LogPath
    }
}

function Invoke-Step([string]$Name, [scriptblock]$Body) {
    Write-Host ""
    Write-Host "== $Name ==" -ForegroundColor Cyan
    & $Body
    Write-Host "[$Name] DONE" -ForegroundColor Green
}

function Load-Adapter([string]$Path) {
    $ext = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()
    if ($ext -eq ".json") {
        return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    }

    Write-Host "[WARN] YAML adapter support is limited to scalar fields. Use project-adapter.json for adapter-driven tests." -ForegroundColor Yellow
    return $null
}

function Write-WorkflowManifest {
    New-Item -ItemType Directory -Force -Path $resolvedOutputDir | Out-Null
    $manifest = Join-Path $resolvedOutputDir "manifest.json"
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

    $failedSteps = @($script:stepResults | Where-Object { $_.result -eq "FAIL" })
    $failedStepName = if ($failedSteps.Count -gt 0) { $failedSteps[0].name } else { $null }
    $json = [ordered]@{
        project = $projectName
        adapter = $adapterFullPath
        project_root = $projectRoot
        generated_at = (Get-Date).ToString("s")
        stage = $Stage
        build_dir = $buildDir
        elf = $elf
        tests = @($tests | ForEach-Object { $_.name })
        steps = $script:stepResults
        failed_step = $failedStepName
        output_dir = $resolvedOutputDir
        test_results = $testResults
        result = if ($script:workflowFailed) { "FAIL" } elseif ($DryRun) { "DRY_RUN" } else { "PASS" }
        dry_run = [bool]$DryRun
    } | ConvertTo-Json -Depth 6
    Set-Content -LiteralPath $manifest -Value $json -Encoding utf8
    return $manifest
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
    $probeEnabled = if ((Has-Property $config "register_probe") -and (Has-Property $config.register_probe "enabled")) { [bool]$config.register_probe.enabled } else { $true }
    $probeTargets = if ((Has-Property $config "register_probe") -and (Has-Property $config.register_probe "targets")) { @($config.register_probe.targets) } else { @("all") }
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
    $probeEnabled = $true
    $probeTargets = @("all")
}

Write-Host "[WORKFLOW] adapter=$adapterFullPath"
Write-Host "[WORKFLOW] project=$projectName stage=$Stage output=$OutputDir"
Write-Host "[WORKFLOW] project_root=$projectRoot"
$resolvedOutputDir = Resolve-WorkflowPath $projectRoot $OutputDir
$script:stepResults = @()
$script:workflowFailed = $false

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
        New-Item -ItemType Directory -Force -Path $resolvedOutputDir | Out-Null
        $logDir = Join-Path $resolvedOutputDir "logs"
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

            $safeName = ([string]$testName -replace "[^\w.-]+", "_")
            if ([string]::IsNullOrWhiteSpace($safeName)) {
                $safeName = [System.IO.Path]::GetFileNameWithoutExtension($scriptPath)
            }

            $result = Invoke-WorkflowScript $testName $scriptPath $testArgs (Join-Path $logDir "$safeName.log")
            $script:stepResults += $result
            if ($result.result -eq "FAIL") {
                $script:workflowFailed = $true
            }
        }
    }
}

if ($stages -contains "probe") {
    Invoke-Step "PROBE" {
        New-Item -ItemType Directory -Force -Path $resolvedOutputDir | Out-Null
        $logDir = Join-Path $resolvedOutputDir "logs"
        if (-not $probeEnabled) {
            Write-Host "[REG] SKIP: register_probe.enabled=false"
            $script:stepResults += [pscustomobject]@{
                name = "register_probe"
                script = Join-Path $templateRoot "register_probe.ps1"
                result = "SKIP"
                exit_code = $null
                log = $null
            }
        } else {
            $probeArgs = @{
                Target = ($probeTargets -join ",")
                Programmer = $flashTool
                Connect = if ($connectArgs -match "mode=") { $connectArgs } else { "$connectArgs mode=HotPlug" }
                OutputJson = Join-Path $resolvedOutputDir "register_probe_summary.json"
            }
            $probeScript = Join-Path $templateRoot "register_probe.ps1"
            $result = Invoke-WorkflowScript "register_probe" $probeScript $probeArgs (Join-Path $logDir "register_probe.log")
            $script:stepResults += $result
            if ($result.result -eq "FAIL") {
                $script:workflowFailed = $true
            }
        }
    }
}

if ($stages -contains "evidence") {
    Invoke-Step "EVIDENCE" {
        $manifest = Write-WorkflowManifest
        Write-Host "[EVIDENCE] $manifest"
    }
}

Write-Host ""
if ($script:workflowFailed) {
    if (-not ($stages -contains "evidence")) {
        $manifest = Write-WorkflowManifest
        Write-Host "[EVIDENCE] $manifest"
    }
    Write-Host "[WORKFLOW-RESULT] FAIL" -ForegroundColor Red
    exit 1
}

Write-Host "[WORKFLOW-RESULT] PASS" -ForegroundColor Green
