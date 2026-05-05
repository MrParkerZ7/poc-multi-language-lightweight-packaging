# before-minimize: typical Node deployment — ship source + node_modules + dist
$ErrorActionPreference = "Stop"

if (Test-Path node_modules) { Remove-Item -Recurse -Force node_modules }
if (Test-Path dist)         { Remove-Item -Recurse -Force dist }

Write-Host "[before-minimize] npm install" -ForegroundColor Cyan
npm install --silent --no-audit --no-fund | Out-Host

Write-Host "[before-minimize] npx tsc" -ForegroundColor Cyan
npx tsc | Out-Host

$nodeModBytes = (Get-ChildItem node_modules -Recurse -File | Measure-Object -Property Length -Sum).Sum
$distBytes    = (Get-ChildItem dist          -Recurse -File | Measure-Object -Property Length -Sum).Sum
$srcBytes     = (Get-ChildItem src           -Recurse -File | Measure-Object -Property Length -Sum).Sum
$total        = $nodeModBytes + $distBytes + $srcBytes + (Get-Item package.json).Length + (Get-Item tsconfig.json).Length

Write-Host ("Artifact: source + dist/ + node_modules/  (folder shipped together)")
Write-Host ("Source:        {0:N1} KB" -f ($srcBytes / 1KB))
Write-Host ("dist/:         {0:N1} KB" -f ($distBytes / 1KB))
Write-Host ("node_modules:  {0:N2} MB" -f ($nodeModBytes / 1MB))
Write-Host ("TOTAL:         {0:N2} MB ({1:N0} bytes)" -f ($total / 1MB), $total)

Write-Host "Verifying output..." -ForegroundColor Cyan
$output = & node dist/main.js
Write-Host ("Output:   {0}" -f $output)

Write-Host "Cold-start (3 runs)..." -ForegroundColor Cyan
1..3 | ForEach-Object {
    $ms = (Measure-Command { & node dist/main.js | Out-Null }).TotalMilliseconds
    Write-Host ("  run {0}: {1:N0} ms" -f $_, $ms)
}
