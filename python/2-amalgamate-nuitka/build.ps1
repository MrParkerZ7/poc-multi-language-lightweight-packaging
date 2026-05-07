$12-amalgamate-nuitka (Python): Nuitka onefile + LTO + every size knob
# Stacks: --onefile + --lto=yes + --remove-output (no build cache) + --no-pyi-file
# Skips UPX on the artifact — Nuitka onefile uses self-extraction; UPX can break it
$ErrorActionPreference = "Stop"

$nu = (Get-Command nuitka -ErrorAction SilentlyContinue)
if (-not $nu) {
    Write-Host "[2-amalgamate-nuitka] pip install --quiet nuitka" -ForegroundColor Cyan
    pip install --quiet nuitka
}

if (Test-Path build) { Remove-Item -Recurse -Force build }
if (Test-Path dist)  { Remove-Item -Recurse -Force dist  }

Write-Host "[2-amalgamate-nuitka] python -m nuitka --onefile --lto=yes --no-pyi-file ..." -ForegroundColor Cyan
Write-Host "(Nuitka with stacked size flags — expect 2-5 min)" -ForegroundColor DarkGray
python -m nuitka `
    --onefile `
    --lto=yes `
    --no-pyi-file `
    --output-dir=dist `
    --remove-output `
    --assume-yes-for-downloads `
    app.py | Out-Host

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
