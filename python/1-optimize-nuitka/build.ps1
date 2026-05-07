# 1-optimize-nuitka: Nuitka — compile Python to C, then to a native binary (no Python on host)
# Smaller and faster than PyInstaller because it's actually compiled, not bundled.
$ErrorActionPreference = "Stop"

# Make sure nuitka is available
$nu = (Get-Command nuitka -ErrorAction SilentlyContinue)
if (-not $nu) {
    Write-Host "[1-optimize-nuitka] pip install --quiet nuitka" -ForegroundColor Cyan
    pip install --quiet nuitka
}

if (Test-Path build) { Remove-Item -Recurse -Force build }
if (Test-Path dist)  { Remove-Item -Recurse -Force dist  }

Write-Host "[1-optimize-nuitka] python -m nuitka --onefile --output-dir=dist --remove-output app.py" -ForegroundColor Cyan
Write-Host "(Nuitka actually compiles Python to C — expect 1-3 min for trivial CLI)" -ForegroundColor DarkGray
python -m nuitka --onefile --output-dir=dist --remove-output --assume-yes-for-downloads app.py | Out-Host

# Nuitka's --onefile produces app.exe on Windows / app.bin on Linux
$exe = if (Test-Path "dist/app.exe") { "dist/app.exe" } else { "dist/app.bin" }
if (-not (Test-Path $exe)) { throw "Nuitka build failed: $exe not found" }

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
