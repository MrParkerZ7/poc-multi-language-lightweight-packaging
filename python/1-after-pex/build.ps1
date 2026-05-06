# 1-after-pex: PEX (Python EXecutable) — Twitter/Pants's "zipapp on steroids"
# Single .pex file with vendored deps, runs on any Python 3.x. Smarter than zipapp for non-stdlib code.
$ErrorActionPreference = "Stop"

# Make sure pex is available
$px = (Get-Command pex -ErrorAction SilentlyContinue)
if (-not $px) {
    Write-Host "[1-after-pex] pip install --quiet pex" -ForegroundColor Cyan
    pip install --quiet pex
}

if (Test-Path dist) { Remove-Item -Recurse -Force dist }
New-Item -ItemType Directory -Path dist | Out-Null

Write-Host "[1-after-pex] pex --output-file=dist/app.pex --entry-point=app:main ." -ForegroundColor Cyan
pex --output-file=dist/app.pex --sources-directory=. --entry-point=app:main | Out-Host

$pex = "dist/app.pex"
if (-not (Test-Path $pex)) { throw "PEX build failed: $pex not found" }

$size = (Get-Item $pex).Length
Write-Host ("Artifact: {0}" -f $pex)
Write-Host ("Size:     {0:N1} KB ({1:N0} bytes)" -f ($size / 1KB), $size)

Write-Host "Verifying output..." -ForegroundColor Cyan
$output = & python $pex
Write-Host ("Output:   {0}" -f $output)

Write-Host "Cold-start (3 runs)..." -ForegroundColor Cyan
1..3 | ForEach-Object {
    $ms = (Measure-Command { & python $pex | Out-Null }).TotalMilliseconds
    Write-Host ("  run {0}: {1:N0} ms" -f $_, $ms)
}
