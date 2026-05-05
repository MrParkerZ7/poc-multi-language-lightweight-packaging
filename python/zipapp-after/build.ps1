# zipapp-after: zipapp â€” single .pyz, stdlib only, needs Python installed on host
$ErrorActionPreference = "Stop"

if (Test-Path build) { Remove-Item -Recurse -Force build }
if (Test-Path dist)  { Remove-Item -Recurse -Force dist  }
New-Item -ItemType Directory -Path build | Out-Null
New-Item -ItemType Directory -Path dist  | Out-Null

Copy-Item app.py      build/
Copy-Item __main__.py build/

Write-Host "[zipapp-after] python -m zipapp build/ -o dist/app.pyz" -ForegroundColor Cyan
python -m zipapp build/ -o dist/app.pyz -p "/usr/bin/env python3"

$pyz = "dist/app.pyz"
if (-not (Test-Path $pyz)) { throw "zipapp failed: $pyz not found" }

$size = (Get-Item $pyz).Length
Write-Host ("Artifact: {0}" -f $pyz)
Write-Host ("Size:     {0:N1} KB ({1:N0} bytes)" -f ($size / 1KB), $size)

Write-Host "Verifying output..." -ForegroundColor Cyan
$output = & python $pyz
Write-Host ("Output:   {0}" -f $output)

Write-Host "Cold-start (3 runs)..." -ForegroundColor Cyan
1..3 | ForEach-Object {
    $ms = (Measure-Command { & python $pyz | Out-Null }).TotalMilliseconds
    Write-Host ("  run {0}: {1:N0} ms" -f $_, $ms)
}
