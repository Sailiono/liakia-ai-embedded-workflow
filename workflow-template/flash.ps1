param(
    [string]$Elf = "build/Debug/dpiny-RTK.elf",
    [string]$Programmer = "STM32_Programmer_CLI",
    [string]$Connect = "port=SWD freq=4000",
    [switch]$DryRun
)

if (-not (Test-Path $Elf)) {
    throw "ELF not found: $Elf"
}

$connectTokens = @()
foreach ($token in ($Connect -split '\s+')) {
    $trimmed = $token.Trim()
    if ($trimmed.Length -gt 0) {
        $connectTokens += $trimmed
    }
}

$args = @("-c") + $connectTokens + @("-w", $Elf, "-v", "-rst")

Write-Host "[FLASH] $Programmer $($args -join ' ')"
if ($DryRun) {
    Write-Host "[FLASH] DRY-RUN"
    return
}

& $Programmer @args
if ($LASTEXITCODE -ne 0) { throw "Flash failed with exit code $LASTEXITCODE" }
Write-Host "[FLASH] PASS"
