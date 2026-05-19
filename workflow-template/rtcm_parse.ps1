param(
    [string]$Port = "COM6",
    [int]$ReadSecs = 10,
    [int[]]$ExpectedMessages = @(1005, 1074, 1084, 1094, 1124),
    [switch]$AllowNoFrames
)

Write-Host "[RTCM] sample parser entry"
Write-Host "[RTCM] frames_total=0 crc_bad=0"
Write-Host "[RTCM] replace with protocol-specific parser for non-RTCM projects"

if (-not $AllowNoFrames) {
    Write-Host "[RTCM-RESULT] FAIL: template parser did not capture frames" -ForegroundColor Red
    exit 1
}

Write-Host "[RTCM-RESULT] PASS: no-frame mode allowed for template smoke test" -ForegroundColor Green
exit 0
