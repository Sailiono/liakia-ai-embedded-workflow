param(
    [string]$Port = "COM6",
    [int]$ReadSecs = 10,
    [int[]]$ExpectedMessages = @(1005, 1074, 1084, 1094, 1124),
    [string]$OutputJson = "",
    [switch]$AllowNoFrames
)

Write-Host "[RTCM] sample parser entry"
Write-Host "[RTCM] frames_total=0 crc_bad=0"
Write-Host "[RTCM] replace with protocol-specific parser for non-RTCM projects"

$result = if ($AllowNoFrames) { "PASS" } else { "FAIL" }
$summary = [ordered]@{
    test = "rtcm_parse_template"
    port = $Port
    read_secs = $ReadSecs
    frames_total = 0
    crc_bad = 0
    expected_messages = $ExpectedMessages
    allow_no_frames = [bool]$AllowNoFrames
    result = $result
}

if ($OutputJson) {
    $outDir = Split-Path -Parent $OutputJson
    if ($outDir) {
        New-Item -ItemType Directory -Force -Path $outDir | Out-Null
    }
    $summary | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $OutputJson -Encoding utf8
    Write-Host "[RTCM] summary_json=$OutputJson"
}

if (-not $AllowNoFrames) {
    Write-Host "[RTCM-RESULT] FAIL: template parser did not capture frames" -ForegroundColor Red
    exit 1
}

Write-Host "[RTCM-RESULT] PASS: no-frame mode allowed for template smoke test" -ForegroundColor Green
exit 0
