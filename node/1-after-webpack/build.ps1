# 1-after-webpack: webpack bundle + Terser minify (industry-standard predecessor to esbuild)
$ErrorActionPreference = "Stop"

if (Test-Path dist) { Remove-Item -Recurse -Force dist }

Write-Host "[1-after-webpack] npm install (build-time only)" -ForegroundColor Cyan
npm install --silent --no-audit --no-fund | Out-Host

Write-Host "[1-after-webpack] npm run build (webpack)" -ForegroundColor Cyan
npm run build | Out-Host

$artifact = "dist/app.cjs"
if (-not (Test-Path $artifact)) { throw "Webpack build failed: $artifact not found" }

$size = (Get-Item $artifact).Length
Write-Host ("Artifact: {0}  (single CommonJS bundle — Node on host runs it)" -f $artifact)
Write-Host ("Size:     {0:N1} KB ({1:N0} bytes)" -f ($size / 1KB), $size)

Write-Host "Verifying output..." -ForegroundColor Cyan
$output = & node $artifact
Write-Host ("Output:   {0}" -f $output)

Write-Host "Cold-start (3 runs)..." -ForegroundColor Cyan
1..3 | ForEach-Object {
    $ms = (Measure-Command { & node $artifact | Out-Null }).TotalMilliseconds
    Write-Host ("  run {0}: {1:N0} ms" -f $_, $ms)
}
