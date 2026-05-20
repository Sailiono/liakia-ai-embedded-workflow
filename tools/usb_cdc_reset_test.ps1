# USB CDC reset recovery validation gate.
param(
    [string]$UsbPort = "COM4",
    [int]$Baud = 115200,
    [int]$OpenTimeoutMs = 20000,
    [int]$ResponseTimeoutMs = 4000,
    [int]$ResetWaitMs = 2500,
    [string]$OutputJson = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-AvailablePorts {
    return [System.IO.Ports.SerialPort]::GetPortNames() | Sort-Object
}

function Wait-ForPort([string]$PortName, [int]$TimeoutMs) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.ElapsedMilliseconds -lt $TimeoutMs) {
        if ((Get-AvailablePorts) -contains $PortName) {
            return $true
        }
        Start-Sleep -Milliseconds 250
    }
    return $false
}

function Open-UsbSerial([string]$PortName, [int]$BaudRate) {
    $sp = New-Object System.IO.Ports.SerialPort $PortName, $BaudRate, None, 8, One
    $sp.DtrEnable = $true
    $sp.RtsEnable = $true
    $sp.NewLine = "`r`n"
    $sp.ReadTimeout = 200
    $sp.WriteTimeout = 2000
    $sp.Open()
    return $sp
}

function Read-For([System.IO.Ports.SerialPort]$Serial, [int]$TimeoutMs) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $buffer = ""
    while ($sw.ElapsedMilliseconds -lt $TimeoutMs) {
        try {
            $chunk = $Serial.ReadExisting()
            if ($chunk) {
                $buffer += $chunk
            }
        } catch {
        }
        if ($buffer -match ">") {
            break
        }
        Start-Sleep -Milliseconds 50
    }
    return $buffer
}

function Invoke-ShellCommand([string]$PortName, [string]$Command, [int]$TimeoutMs) {
    $serial = $null
    try {
        $serial = Open-UsbSerial $PortName $Baud
        [void](Read-For $serial 300)
        Write-Host ">> $Command"
        $serial.Write("$Command`r`n")
        Start-Sleep -Milliseconds 100
        return Read-For $serial $TimeoutMs
    } finally {
        if ($serial -and $serial.IsOpen) {
            $serial.Close()
        }
    }
}

function Assert-VersionResponse([string]$Name, [string]$Text) {
    if ($Text -notmatch "dpiny-RTK" -or $Text -notmatch "STM32F407" -or $Text -notmatch "FreeRTOS") {
        Write-Host "[FAIL] $Name" -ForegroundColor Red
        Write-Host $Text
        throw "$Name did not return a valid version response."
    }
    Write-Host "[PASS] $Name" -ForegroundColor Green
}

$failed = $false
$before = ""
$after = ""
$availablePorts = Get-AvailablePorts

try {
    Write-Host "dpiny-RTK USB CDC reset recovery test"
    Write-Host "USB CDC port: $UsbPort"
    Write-Host ("Available COM ports: {0}" -f ($availablePorts -join ", "))

    if (-not (Wait-ForPort $UsbPort $OpenTimeoutMs)) {
        throw "Timeout waiting for USB CDC port: $UsbPort"
    }

    Write-Host "Waiting for USB CDC shell (before software reset)..."
    $before = Invoke-ShellCommand $UsbPort "version" $ResponseTimeoutMs
    Write-Host $before
    Assert-VersionResponse "USB CDC shell responded before reset" $before

    Write-Host "Issuing software reset..."
    [void](Invoke-ShellCommand $UsbPort "reset" 500)
    Start-Sleep -Milliseconds $ResetWaitMs

    if (-not (Wait-ForPort $UsbPort $OpenTimeoutMs)) {
        throw "Timeout waiting for USB CDC port after software reset: $UsbPort"
    }

    Write-Host "Waiting for USB CDC shell (after software reset)..."
    $after = Invoke-ShellCommand $UsbPort "version" $ResponseTimeoutMs
    Write-Host $after
    Assert-VersionResponse "USB CDC shell responded after reset" $after
} catch {
    $failed = $true
    Write-Host "[USB-CDC-RESULT] FAIL: $($_.Exception.Message)" -ForegroundColor Red
}

$summary = [ordered]@{
    test = "usb_cdc_reset"
    port = $UsbPort
    baud = $Baud
    before_reset_version_response = ($before -match "dpiny-RTK")
    after_reset_version_response = ($after -match "dpiny-RTK")
    result = if ($failed) { "FAIL" } else { "PASS" }
}

if ($OutputJson) {
    $outDir = Split-Path -Parent $OutputJson
    if ($outDir) {
        New-Item -ItemType Directory -Force -Path $outDir | Out-Null
    }
    $summary | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $OutputJson -Encoding utf8
    Write-Host "[USB-CDC] summary_json=$OutputJson"
}

if ($failed) {
    exit 1
}

Write-Host "[USB-CDC-RESULT] PASS" -ForegroundColor Green
exit 0
