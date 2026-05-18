param(
    [string]$Elf = "build/Debug/dpiny-RTK.elf",
    [string]$Programmer = "STM32_Programmer_CLI",
    [string]$Connect = "port=SWD freq=4000"
)

if (-not (Test-Path $Elf)) {
    throw "ELF not found: $Elf"
}

Write-Host "[FLASH] $Elf"
& $Programmer -c $Connect -w $Elf -v -rst
if ($LASTEXITCODE -ne 0) { throw "Flash failed with exit code $LASTEXITCODE" }
Write-Host "[FLASH] PASS"
