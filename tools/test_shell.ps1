# dpiny-RTK Shell Test Script
param(
    [string]$Port = "COM4",
    [int]$Baud = 115200
)

$p = New-Object System.IO.Ports.SerialPort $Port, $Baud, None, 8, One
$p.DtrEnable = $true
$p.RtsEnable = $true
$p.ReadTimeout = 3000
$p.Open()
Write-Host "=== dpiny-RTK Shell Test ($Port) ==="

Start-Sleep -Milliseconds 500
$d = $p.ReadExisting()
if ($d) { Write-Host "Boot: $d" }

$tests = @(
    @{Cmd="version"; Desc="Version Info"; Expect=@("dpiny-RTK","STM32F407","UM982","FreeRTOS")},
    @{Cmd="usb";     Desc="USB Status";   Expect=@("USB","Connected")},
    @{Cmd="status";  Desc="System Status";Expect=@("System Status","Passthrough","GNSS","Watchdog")},
    @{Cmd="config";  Desc="Configuration";Expect=@("Configuration","UART1","UART4","GNSS")},
    @{Cmd="rtcm list";Desc="RTCM Config"; Expect=@("RTCM","1005","1074","1084","1094","1124")},
    @{Cmd="help";    Desc="Help";         Expect=@("help","status","config","save","reset","baud","usb","version","rtcm")}
)

$pass = 0
$fail = 0

foreach ($t in $tests) {
    Write-Host "`n--- $($t.Desc) ---"
    $p.WriteLine($t.Cmd)
    Start-Sleep -Milliseconds 800
    $r = $p.ReadExisting()
    Write-Host $r

    $ok = $true
    foreach ($kw in $t.Expect) {
        if ($r -match [regex]::Escape($kw)) {
            Write-Host "  [OK] $kw" -ForegroundColor Green
        } else {
            Write-Host "  [MISS] $kw" -ForegroundColor Red
            $ok = $false
        }
    }
    if ($ok) { $pass++ } else { $fail++ }
}

$p.Close()
Write-Host "`n=== Passed: $pass  Failed: $fail ===" -ForegroundColor $(if ($fail -eq 0) { "Green" } else { "Red" })
exit $fail
