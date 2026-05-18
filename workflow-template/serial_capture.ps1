param(
    [string]$Port = "COM4",
    [int]$BaudRate = 115200,
    [int]$ReadSecs = 10,
    [string]$Output = "serial_capture.log"
)

Write-Host "[SERIAL] capture port=$Port baud=$BaudRate seconds=$ReadSecs output=$Output"
Write-Host "[SERIAL] implement with System.IO.Ports.SerialPort for the target project"
