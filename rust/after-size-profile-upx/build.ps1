# after-size-profile-upx: aggressive size optimization + UPX
# Cargo.toml profile sets opt-level="z", lto, strip, panic=abort, codegen-units=1
$ErrorActionPreference = "Stop"

Write-Host "[after-size-profile-upx] cargo build --release  (size-tuned profile)" -ForegroundColor Cyan
cargo build --release | Out-Host

$exe = "target/release/app.exe"
if (-not (Test-Path $exe)) { throw "Build failed: $exe not found" }
$strippedSize = (Get-Item $exe).Length

# UPX compress (skip if not installed)
$upx = (Get-Command upx -ErrorAction SilentlyContinue)
if ($upx) {
    Write-Host "[after-size-profile-upx] upx --best --lzma" -ForegroundColor Cyan
    upx --best --lzma $exe | Out-Host
    $compressedSize = (Get-Item $exe).Length
} else {
    Write-Warning "UPX not found on PATH â€” skipping compression. Install UPX for full lightweight result."
    $compressedSize = $strippedSize
}

Write-Host ("Artifact: {0}" -f $exe)
Write-Host ("After Cargo size profile only: {0:N1} KB" -f ($strippedSize / 1KB))
Write-Host ("After UPX:                     {0:N1} KB ({1:N0} bytes)" -f ($compressedSize / 1KB), $compressedSize)

Write-Host "Verifying output..." -ForegroundColor Cyan
$output = & $exe
Write-Host ("Output:   {0}" -f $output)

Write-Host "Cold-start (3 runs)..." -ForegroundColor Cyan
1..3 | ForEach-Object {
    $ms = (Measure-Command { & $exe | Out-Null }).TotalMilliseconds
    Write-Host ("  run {0}: {1:N0} ms" -f $_, $ms)
}
