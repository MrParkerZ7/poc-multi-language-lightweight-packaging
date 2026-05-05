# pyinstaller-after: PyInstaller onefile â€” bundles a stripped Python interpreter
$ErrorActionPreference = "Stop"

# Make sure pyinstaller is available
$pi = (Get-Command pyinstaller -ErrorAction SilentlyContinue)
if (-not $pi) {
    Write-Host "[pyinstaller-after] pip install --quiet pyinstaller" -ForegroundColor Cyan
    pip install --quiet pyinstaller
}

if (Test-Path build) { Remove-Item -Recurse -Force build }
if (Test-Path dist)  { Remove-Item -Recurse -Force dist  }

Write-Host "[pyinstaller-after] pyinstaller --onefile --strip --noconfirm app.py" -ForegroundColor Cyan
pyinstaller --onefile --noconfirm --name app app.py | Out-Host

$exe = "dist/app.exe"
if (-not (Test-Path $exe)) { throw "PyInstaller failed: $exe not found" }

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
