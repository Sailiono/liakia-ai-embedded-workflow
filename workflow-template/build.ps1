param(
    [string]$BuildDir = "build/Debug",
    [string]$Command = "ninja"
)

Write-Host "[BUILD] working_dir=$BuildDir command=$Command"
Push-Location $BuildDir
try {
    & $Command
    if ($LASTEXITCODE -ne 0) { throw "Build failed with exit code $LASTEXITCODE" }
    Write-Host "[BUILD] PASS"
} finally {
    Pop-Location
}
