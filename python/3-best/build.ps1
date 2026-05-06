# 3-best (Python): PyOxidizer + memory-only modules + stripped CPython + UPX (Linux only)
# Trade: PyOxidizer build is finicky vs. Nuitka. C-extension wheels need explicit handling.
#        Smaller AND faster cold-start than Nuitka onefile because there's no self-extraction step.
$ErrorActionPreference = "Stop"

$pyox = (Get-Command pyoxidizer -ErrorAction SilentlyContinue)
if (-not $pyox) {
    Write-Host "[3-best] cargo install pyoxidizer" -ForegroundColor Cyan
    Write-Host "(installs PyOxidizer via cargo - expect 5-10 min on first run)" -ForegroundColor DarkGray
    cargo install pyoxidizer | Out-Host
}

if (Test-Path build) { Remove-Item -Recurse -Force build }

Write-Host "[3-best] pyoxidizer build --release exe" -ForegroundColor Cyan
pyoxidizer build --release exe | Out-Host

# Locate the produced binary (PyOxidizer puts it in build/<triple>/release/install/)
$exe = Get-ChildItem -Path build -Recurse -Filter "app.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $exe) {
    $exe = Get-ChildItem -Path build -Recurse -Filter "app" -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer } | Select-Object -First 1
}
if (-not $exe) { throw "PyOxidizer build failed: no app binary under build/" }

$preUpxSize = $exe.Length

# UPX on PyOxidizer-built binaries: works on Linux ELF; sometimes corrupts Windows PE.
$upx = (Get-Command upx -ErrorAction SilentlyContinue)
if ($upx -and $exe.Extension -ne ".exe") {
    Write-Host "[3-best] upx --best --lzma" -ForegroundColor Cyan
    upx --best --lzma $exe.FullName 2>&1 | Out-Host
}
$size = (Get-Item $exe.FullName).Length

Write-Host ("Artifact: {0}" -f $exe.FullName)
Write-Host ("After PyOxidizer + memory-only modules: {0:N2} MB" -f ($preUpxSize / 1MB))
Write-Host ("After UPX (if applied):                 {0:N2} MB ({1:N0} bytes)" -f ($size / 1MB), $size)

Write-Host "Verifying output..." -ForegroundColor Cyan
$output = & $exe.FullName
Write-Host ("Output:   {0}" -f $output)

Write-Host "Cold-start (3 runs)..." -ForegroundColor Cyan
1..3 | ForEach-Object {
    $ms = (Measure-Command { & $exe.FullName | Out-Null }).TotalMilliseconds
    Write-Host ("  run {0}: {1:N0} ms" -f $_, $ms)
}
