$12-amalgamate-tinygo (Go): TinyGo + opt=z + UPX + scratch container
$ErrorActionPreference = "Stop"

$tg = (Get-Command tinygo -ErrorAction SilentlyContinue)
if (-not $tg) { throw "tinygo not found. Install: https://tinygo.org/getting-started/install/" }

Write-Host "[2-amalgamate-tinygo] tinygo build -opt=z -no-debug" -ForegroundColor Cyan
tinygo build -o app.exe -opt=z -no-debug .
if (-not (Test-Path app.exe)) { throw "TinyGo build failed: app.exe not found" }
$preUpxSize = (Get-Item app.exe).Length

$upx = (Get-Command upx -ErrorAction SilentlyContinue)
if ($upx) {
    Write-Host "[2-amalgamate-tinygo] upx --best --lzma app.exe" -ForegroundColor Cyan
    upx --best --lzma app.exe | Out-Host
}
$size = (Get-Item app.exe).Length

Write-Host ("Artifact: app.exe")
Write-Host ("After TinyGo only: {0:N1} KB" -f ($preUpxSize / 1KB))
Write-Host ("After UPX:         {0:N1} KB ({1:N0} bytes)" -f ($size / 1KB), $size)

Write-Host "Verifying output..." -ForegroundColor Cyan
$output = & ./app.exe
Write-Host ("Output:   {0}" -f $output)

Write-Host "Cold-start (3 runs)..." -ForegroundColor Cyan
1..3 | ForEach-Object {
    $ms = (Measure-Command { & ./app.exe | Out-Null }).TotalMilliseconds
    Write-Host ("  run {0}: {1:N0} ms" -f $_, $ms)
}
