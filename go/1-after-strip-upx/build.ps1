# 1-after-strip-upx: stripped + UPX-compressed
# Requires: UPX on PATH (https://upx.github.io/)
$ErrorActionPreference = "Stop"

Write-Host "[1-after-strip-upx] go build -ldflags='-s -w' -trimpath" -ForegroundColor Cyan
go build -ldflags="-s -w" -trimpath -o app.exe .

if (-not (Test-Path app.exe)) { throw "Build failed: app.exe not found" }
$strippedSize = (Get-Item app.exe).Length

# UPX compress (skip if not installed)
$upx = (Get-Command upx -ErrorAction SilentlyContinue)
if ($upx) {
    Write-Host "[1-after-strip-upx] upx --best --lzma app.exe" -ForegroundColor Cyan
    upx --best --lzma app.exe | Out-Host
    $compressedSize = (Get-Item app.exe).Length
} else {
    Write-Warning "UPX not found on PATH â€” skipping compression. Install UPX for full lightweight result."
    $compressedSize = $strippedSize
}

Write-Host ("Artifact: app.exe")
Write-Host ("Stripped only:  {0:N2} MB" -f ($strippedSize / 1MB))
Write-Host ("After UPX:      {0:N2} MB ({1:N0} bytes)" -f ($compressedSize / 1MB), $compressedSize)

Write-Host "Verifying output..." -ForegroundColor Cyan
$output = & ./app.exe
Write-Host ("Output:   {0}" -f $output)

Write-Host "Cold-start (3 runs)..." -ForegroundColor Cyan
1..3 | ForEach-Object {
    $ms = (Measure-Command { & ./app.exe | Out-Null }).TotalMilliseconds
    Write-Host ("  run {0}: {1:N0} ms" -f $_, $ms)
}
