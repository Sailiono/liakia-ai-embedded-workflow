param(
    [Parameter(Mandatory = $true)]
    [string]$EvidenceDir,
    [ValidateSet("case-a", "case-b", "case-c", "case-d", "generic")]
    [string]$Case = "case-a",
    [int]$MaxLogChars = 5000
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $EvidenceDir)) {
    throw "Evidence directory not found: $EvidenceDir"
}

$evidenceFullPath = (Resolve-Path -LiteralPath $EvidenceDir).Path
$manifestPath = Join-Path $evidenceFullPath "00_manifest.json"
if (-not (Test-Path -LiteralPath $manifestPath)) {
    $manifestPath = Join-Path $evidenceFullPath "manifest.json"
}
if (-not (Test-Path -LiteralPath $manifestPath)) {
    $candidate = Get-ChildItem -LiteralPath $evidenceFullPath -Filter "00_manifest*.json" -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($candidate) {
        $manifestPath = $candidate.FullName
    }
}
if (-not (Test-Path -LiteralPath $manifestPath)) {
    throw "Manifest not found in evidence directory: $evidenceFullPath"
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$manifestProps = @($manifest.PSObject.Properties.Name)
$steps = if ($manifestProps -contains "steps") { @($manifest.steps) } else { @() }
$runResult = if ($manifestProps -contains "result") { [string]$manifest.result } else { "UNKNOWN" }
$failedSteps = @($steps | Where-Object { $_.result -eq "FAIL" })
if ($failedSteps.Count -eq 0 -and ($manifestProps -contains "failure")) {
    $failedSteps = @([pscustomobject]@{
        name = $manifest.failure.failed_gate
        result = "FAIL"
        log = ""
    })
}
$logDir = Join-Path $evidenceFullPath "logs"

function Read-LogSnippet([string]$Path, [int]$Limit) {
    if (-not $Path -or -not (Test-Path -LiteralPath $Path)) { return "" }
    $text = Get-Content -LiteralPath $Path -Raw
    if ($text.Length -le $Limit) { return $text.Trim() }
    return ($text.Substring(0, $Limit) + "`n...[truncated]").Trim()
}

function Get-CaseFocus([string]$CaseName) {
    switch ($CaseName) {
        "case-b" {
            return "Focus on software-reset I2C recovery, SDA/SCL idle state, I2C BUSY, RCC_CSR reset reason, and GPIOB PB6/PB7 mode."
        }
        "case-a" {
            return "Focus on BMP280 calibration endian, signed 16-bit decode, integer width, raw ADC plausibility, and data-quality gates."
        }
        "case-d" {
            return "Focus on USART IDLE interrupt ordering, DMA NDTR snapshot timing, ring buffer indexes, frame truncation, and CRC clustering."
        }
        "case-c" {
            return "Focus on Flash half-word writes, page erase boundary, struct padding, CRC range, config version, and post-reset reload."
        }
    }
    return "Focus on evidence-backed root cause isolation before proposing fixes."
}

$logSections = @()
if (Test-Path -LiteralPath $logDir) {
    foreach ($file in (Get-ChildItem -LiteralPath $logDir -File | Sort-Object Name)) {
        $logSections += "### $($file.Name)"
        $logSections += ""
        $logSections += '```text'
        $logSections += Read-LogSnippet $file.FullName $MaxLogChars
        $logSections += '```'
        $logSections += ""
    }
}

$failedTable = if ($failedSteps.Count -eq 0) {
    "No failed steps recorded. Review warnings and skipped gates."
} else {
    ($failedSteps | ForEach-Object { "- $($_.name): $($_.result), log=$($_.log)" }) -join "`n"
}

$caseFocus = Get-CaseFocus $Case
$promptPath = Join-Path $evidenceFullPath "ai_prompt.md"
$triagePath = Join-Path $evidenceFullPath "failure_triage.md"

$manifestText = Get-Content -LiteralPath $manifestPath -Raw
$promptLines = @(
    "# AI Diagnosis Prompt",
    "",
    "You are an embedded firmware debugging assistant. Analyze only from evidence. Do not assume hardware is broken unless the logs support it.",
    "",
    "## Project",
    "",
    "Liakia Starter-F103 Sensor Lab",
    "",
    "## Case",
    "",
    $Case,
    "",
    "## Case Focus",
    "",
    $caseFocus,
    "",
    "## Run Result",
    "",
    $runResult,
    "",
    "## Failed Steps",
    "",
    $failedTable,
    "",
    "## Manifest",
    "",
    '```json',
    $manifestText.Trim(),
    '```',
    "",
    "## Logs",
    "",
    ($logSections -join "`n"),
    "",
    "## Required Output Format",
    "",
    "1. Observations",
    "2. Ruled-out causes",
    "3. Ranked hypotheses",
    "4. Minimal fix scope",
    "5. Regression plan",
    "6. Human checks that must not be delegated to AI"
)
$prompt = $promptLines -join "`n"

$triage = @(
    "# Failure Triage",
    "",
    ('Evidence directory: `{0}`' -f $evidenceFullPath),
    "",
    ('Case: `{0}`' -f $Case),
    "",
    ('Result: `{0}`' -f $runResult),
    "",
    "## Failed Steps",
    "",
    $failedTable,
    "",
    "## Case Focus",
    "",
    $caseFocus,
    "",
    "## Generated Files",
    "",
    '- `ai_prompt.md`: prompt to paste into an AI assistant',
    '- `failure_triage.md`: this summary',
    "",
    "## Review Boundary",
    "",
    "Do not mark the run as PASS until the same gate is re-run and the evidence package is regenerated."
)

$prompt | Set-Content -LiteralPath $promptPath -Encoding utf8
$triage | Set-Content -LiteralPath $triagePath -Encoding utf8

Write-Host "[DIAG] prompt=$promptPath"
Write-Host "[DIAG] triage=$triagePath"
Write-Host "[DIAG-RESULT] PASS"
