# before-minimize: default cargo build --release
$ErrorActionPreference = "Stop"

Write-Host "[before-minimize] cargo build --release" -ForegroundColor Cyan
cargo build --release | Out-Host

$exe = "target/release/app.exe"
if (-not (Test-Path $exe)) { throw "Build failed: $exe not found" }

$size = (Get-Item $exe).Length
Write-Host ("Artifact: {0}" -f $exe)
Write-Host ("Size:     {0:N2} MB ({1:N0} bytes)" -f ($size / 1MB), $size)

Write-Host "Verifying output..." -ForegroundColor Cyan
$output = & $exe
Write-Host ("Output:   {0}" -f $output)

Write-Host "Cold-start (3 runs)..." -ForegroundColor Cyan
1..3 | ForEach-Object {
    $ms = (Measure-Command { & $exe | Out-Null }).TotalMilliseconds
    Write-Host ("  run {0}: {1:N0} ms" -f $_, $ms)
}
