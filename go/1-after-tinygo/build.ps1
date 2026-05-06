# 1-after-tinygo: TinyGo compiler — alternative Go compiler with much smaller output
# Designed for embedded/WASM but works for CLIs. Trade-off: stdlib coverage is smaller (some packages unsupported).
$ErrorActionPreference = "Stop"

# Verify tinygo is available
$tg = (Get-Command tinygo -ErrorAction SilentlyContinue)
if (-not $tg) { throw "tinygo not found on PATH. Install: https://tinygo.org/getting-started/install/" }

Write-Host "[1-after-tinygo] tinygo build -o app.exe -opt=z ." -ForegroundColor Cyan
tinygo build -o app.exe -opt=z .

if (-not (Test-Path app.exe)) { throw "TinyGo build failed: app.exe not found" }

$size = (Get-Item app.exe).Length
Write-Host ("Artifact: app.exe")
Write-Host ("Size:     {0:N2} MB ({1:N0} bytes)" -f ($size / 1MB), $size)

Write-Host "Verifying output..." -ForegroundColor Cyan
$output = & ./app.exe
Write-Host ("Output:   {0}" -f $output)

Write-Host "Cold-start (3 runs)..." -ForegroundColor Cyan
1..3 | ForEach-Object {
    $ms = (Measure-Command { & ./app.exe | Out-Null }).TotalMilliseconds
    Write-Host ("  run {0}: {1:N0} ms" -f $_, $ms)
}
