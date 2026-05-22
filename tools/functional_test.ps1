param(
    [ValidateSet('Debug','Release')]
    [string]$BuildPreset = $(if ($env:DPINY_BUILD_PRESET) { $env:DPINY_BUILD_PRESET } else { 'Debug' }),

    [string]$ElfPath = $env:DPINY_ELF_PATH,

    [string]$ComPort = $env:DPINY_COM_PORT,

    [string]$ProgrammerCliPath = $env:DPINY_PROGRAMMER_CLI,

    [string]$ConnectArgs = $(if ($env:DPINY_PROGRAMMER_CONNECT) { $env:DPINY_PROGRAMMER_CONNECT } else { 'port=SWD freq=4000' }),

    [int]$CommandTimeoutMs = $(if ($env:LIAKIA_COMMAND_TIMEOUT_MS) { [int]$env:LIAKIA_COMMAND_TIMEOUT_MS } else { 60000 }),

    [switch]$AllowDangerousShellCommands,

    [switch]$SkipBuild,
    [switch]$SkipFlash,
    [switch]$SkipPersistence
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSCommandPath
$repoRoot = Split-Path -Parent $repoRoot

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$reportDir = Join-Path $repoRoot 'build'
$reportPath = Join-Path $reportDir ("functional_test_${BuildPreset}.log")

function Write-ReportLine([string]$msg) {
    $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $line = "[$ts] $msg"
    Write-Host $line
    [System.IO.File]::AppendAllText($reportPath, $line + "`r`n", $utf8NoBom)
}

function Exec([string]$exe, [string[]]$args) {
    Write-ReportLine ("EXEC: {0} {1}" -f $exe, ($args -join ' '))
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $exe
    $pinfo.Arguments = ($args -join ' ')
    $pinfo.RedirectStandardOutput = $true
    $pinfo.RedirectStandardError = $true
    $pinfo.UseShellExecute = $false
    $pinfo.CreateNoWindow = $true

    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    [void]$p.Start()
    $stdoutTask = $p.StandardOutput.ReadToEndAsync()
    $stderrTask = $p.StandardError.ReadToEndAsync()

    if (-not $p.WaitForExit($CommandTimeoutMs)) {
        try {
            $p.Kill()
            [void]$p.WaitForExit(5000)
        } catch { }
        throw "Command timed out after ${CommandTimeoutMs}ms: $exe"
    }

    $stdout = $stdoutTask.Result
    $stderr = $stderrTask.Result

    if ($stdout) { Write-ReportLine ("STDOUT:`n" + $stdout.TrimEnd()) }
    if ($stderr) { Write-ReportLine ("STDERR:`n" + $stderr.TrimEnd()) }

    if ($p.ExitCode -ne 0) {
        throw "Command failed with exit code $($p.ExitCode): $exe"
    }
}

function Resolve-ElfPath {
    if ($ElfPath -and (Test-Path -LiteralPath $ElfPath)) {
        return (Resolve-Path -LiteralPath $ElfPath).Path
    }

    $candidate = Join-Path $repoRoot ("build\\{0}\\dpiny-RTK.elf" -f $BuildPreset)
    if (Test-Path -LiteralPath $candidate) {
        return (Resolve-Path -LiteralPath $candidate).Path
    }

    throw "ELF not found. Provide -ElfPath or build first. Tried: $candidate"
}

function Resolve-ProgrammerCli {
    if ($ProgrammerCliPath -and (Test-Path -LiteralPath $ProgrammerCliPath)) {
        return (Resolve-Path -LiteralPath $ProgrammerCliPath).Path
    }

    $cmd = Get-Command 'STM32_Programmer_CLI.exe' -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }

    $common = @(
        'C:\\ST\\STM32CubeCLT\\STM32CubeProgrammer\\bin\\STM32_Programmer_CLI.exe',
        'C:\\Program Files\\STMicroelectronics\\STM32Cube\\STM32CubeProgrammer\\bin\\STM32_Programmer_CLI.exe',
        'C:\\Program Files (x86)\\STMicroelectronics\\STM32Cube\\STM32CubeProgrammer\\bin\\STM32_Programmer_CLI.exe'
    )

    foreach ($p in $common) {
        if (Test-Path -LiteralPath $p) { return $p }
    }

    throw "STM32_Programmer_CLI.exe not found. Install STM32CubeCLT/CubeProgrammer or pass -ProgrammerCliPath."
}

function Get-AvailablePorts {
    return [System.IO.Ports.SerialPort]::GetPortNames() | Sort-Object
}

function Wait-ForPort([string]$portName, [int]$timeoutMs = 20000) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.ElapsedMilliseconds -lt $timeoutMs) {
        $ports = Get-AvailablePorts
        if ($ports -contains $portName) {
            return $true
        }
        Start-Sleep -Milliseconds 250
    }
    return $false
}

function Open-Serial([string]$portName, [int]$baud = 115200) {
    $sp = New-Object System.IO.Ports.SerialPort $portName, $baud, 'None', 8, 'One'
    $sp.DtrEnable = $true
    $sp.RtsEnable = $true
    $sp.NewLine = "`r`n"
    $sp.ReadTimeout = 200
    $sp.WriteTimeout = 2000
    $sp.Open()
    return $sp
}

function Serial-Drain([System.IO.Ports.SerialPort]$sp, [int]$drainMs = 250) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $buf = ""
    while ($sw.ElapsedMilliseconds -lt $drainMs) {
        try {
            $buf += $sp.ReadExisting()
        } catch { }
        Start-Sleep -Milliseconds 50
    }
    return $buf
}

function Serial-SendLine([System.IO.Ports.SerialPort]$sp, [string]$line) {
    Write-ReportLine ("SERIAL >> {0}" -f $line)
    $sp.Write("$line`r`n")
}

$script:LastDangerousCommandAt = @{}
$script:DangerousShellCommands = @("baud", "save", "reset", "erase", "bootloader")
$script:DangerousMinIntervalMs = @{
    "reset" = 5000
    "save" = 3000
}

function Get-ShellCommandName([string]$line) {
    $trimmed = $line.Trim()
    if (-not $trimmed) { return "" }
    return (($trimmed -split "\s+")[0]).ToLowerInvariant()
}

function Assert-ShellCommandAllowed([string]$line, [string]$reason = "") {
    $command = Get-ShellCommandName $line
    if (-not $command -or $script:DangerousShellCommands -notcontains $command) {
        return
    }

    $allowed = [bool]$AllowDangerousShellCommands -or ($env:LIAKIA_ALLOW_DANGEROUS_COMMANDS -eq "1")
    if (-not $allowed) {
        throw "Dangerous shell command '$command' is blocked. Re-run with -AllowDangerousShellCommands or set LIAKIA_ALLOW_DANGEROUS_COMMANDS=1. Command: $line"
    }

    if ($script:DangerousMinIntervalMs.ContainsKey($command) -and $script:LastDangerousCommandAt.ContainsKey($command)) {
        $elapsed = [int]((Get-Date) - $script:LastDangerousCommandAt[$command]).TotalMilliseconds
        $minInterval = [int]$script:DangerousMinIntervalMs[$command]
        if ($elapsed -lt $minInterval) {
            throw "Dangerous shell command '$command' repeated after ${elapsed}ms; minimum interval is ${minInterval}ms."
        }
    }

    $script:LastDangerousCommandAt[$command] = Get-Date
    $suffix = if ($reason) { " reason=$reason" } else { "" }
    Write-ReportLine "SAFETY: dangerous shell command allowed: $command$suffix"
}

function Send-ShellLine([System.IO.Ports.SerialPort]$sp, [string]$line, [string]$reason = "") {
    Assert-ShellCommandAllowed $line $reason
    Serial-SendLine $sp $line
}

function Serial-ReadUntil([System.IO.Ports.SerialPort]$sp, [string]$pattern, [int]$timeoutMs = 2000) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $buf = ""
    while ($sw.ElapsedMilliseconds -lt $timeoutMs) {
        $chunk = $sp.ReadExisting()
        if ($chunk) {
            $buf += $chunk
            if ($buf -match $pattern) {
                return $buf
            }
        }
        Start-Sleep -Milliseconds 50
    }
    return $buf
}

function Assert-Match([string]$name, [string]$text, [string]$pattern) {
    if ($text -notmatch $pattern) {
        Write-ReportLine "FAIL: $name"
        Write-ReportLine ("Expected pattern: {0}" -f $pattern)
        Write-ReportLine ("Got:`n{0}" -f $text.TrimEnd())
        throw "Assertion failed: $name"
    }
    Write-ReportLine "PASS: $name"
}

# Ensure report directory exists
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
[System.IO.File]::WriteAllText($reportPath, "", $utf8NoBom)

Write-ReportLine "=== dpiny-RTK Functional Test Start ==="
Write-ReportLine ("Repo: {0}" -f $repoRoot)
Write-ReportLine ("Preset: {0}" -f $BuildPreset)

if (-not $SkipBuild) {
    Push-Location $repoRoot
    try {
        Exec 'cmake' @('--build', '--preset', $BuildPreset)
    } finally {
        Pop-Location
    }
} else {
    Write-ReportLine "Skip build."
}

$resolvedElf = Resolve-ElfPath
Write-ReportLine ("ELF: {0}" -f $resolvedElf)

if (-not $SkipFlash) {
    $cli = Resolve-ProgrammerCli
    Write-ReportLine ("Programmer CLI: {0}" -f $cli)

    $connectTokens = @()
    foreach ($t in ($ConnectArgs -split '\s+')) {
        if ($t.Trim().Length -gt 0) { $connectTokens += $t }
    }

    # Download ELF and reset
    Exec $cli (@('-c') + $connectTokens + @('-d', ('"' + $resolvedElf + '"'), '-rst'))
} else {
    Write-ReportLine "Skip flash."
}

# Determine COM port
if (-not $ComPort) {
    $ports = Get-AvailablePorts
    if ($ports.Count -eq 0) {
        throw "No COM ports detected. Provide -ComPort COMx."
    }

    Write-ReportLine ("Detected ports: {0}" -f ($ports -join ', '))
    throw "-ComPort not specified. Rerun with -ComPort COMx (e.g. COM11)."
}

Write-ReportLine ("Target COM: {0}" -f $ComPort)
if (-not (Wait-ForPort $ComPort 20000)) {
    throw "Timeout waiting for $ComPort to appear."
}

# Run shell tests
$sp = $null
try {
    $sp = Open-Serial $ComPort 115200
    [void](Serial-Drain $sp 250)

    # Get prompt
    Send-ShellLine $sp ''
    $out = Serial-ReadUntil $sp '>' 2000
    Write-ReportLine ("SERIAL <<`n{0}" -f $out.TrimEnd())

    Send-ShellLine $sp 'help'
    $out = Serial-ReadUntil $sp 'Available commands' 2000
    Write-ReportLine ("SERIAL <<`n{0}" -f $out.TrimEnd())
    Assert-Match 'help prints command list' $out 'Available commands'

    Send-ShellLine $sp 'status'
    $out = Serial-ReadUntil $sp 'System Status' 2000
    Write-ReportLine ("SERIAL <<`n{0}" -f $out.TrimEnd())
    Assert-Match 'status prints system status' $out '---\s*System Status\s*---'

    Send-ShellLine $sp 'config'
    $out = Serial-ReadUntil $sp 'Configuration' 2000
    Write-ReportLine ("SERIAL <<`n{0}" -f $out.TrimEnd())
    Assert-Match 'config prints configuration header' $out '---\s*Configuration\s*---'

    if (-not $SkipPersistence) {
        Send-ShellLine $sp 'baud 1 57600' 'persistence-test'
        $out = Serial-ReadUntil $sp 'baudrate set' 2000
        Write-ReportLine ("SERIAL <<`n{0}" -f $out.TrimEnd())
        Assert-Match 'baud command accepted' $out 'UART1 baudrate set to 57600'

        Send-ShellLine $sp 'save' 'persistence-test'
        $out = Serial-ReadUntil $sp 'saved|saved to Flash|Configuration saved' 3000
        Write-ReportLine ("SERIAL <<`n{0}" -f $out.TrimEnd())

        Send-ShellLine $sp 'reset' 'persistence-test'
        Write-ReportLine "Reset issued. Waiting for device reboot and COM re-open..."
        try { $sp.Close() } catch { }
        $sp = $null

        Start-Sleep -Seconds 2
        if (-not (Wait-ForPort $ComPort 20000)) {
            throw "After reset, timeout waiting for $ComPort to re-appear."
        }
        Start-Sleep -Milliseconds 500

        $sp = Open-Serial $ComPort 115200
        [void](Serial-Drain $sp 500)

        Send-ShellLine $sp ''
        [void](Serial-ReadUntil $sp '>' 2000)

        Send-ShellLine $sp 'config'
        $out = Serial-ReadUntil $sp 'UART1 Baud' 2000
        Write-ReportLine ("SERIAL <<`n{0}" -f $out.TrimEnd())
        Assert-Match 'config persistence UART1 baud=57600' $out 'UART1 Baud:\s*57600'
    } else {
        Write-ReportLine "Skip persistence test."
    }

    Write-ReportLine "=== Functional Test: ALL PASS ==="
} finally {
    if ($sp -and $sp.IsOpen) {
        try { $sp.Close() } catch { }
    }
}
