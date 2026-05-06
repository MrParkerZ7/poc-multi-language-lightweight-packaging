# 1-after-bun-compile: bun build --compile — single binary with bun runtime bundled
# Larger than esbuild+llrt (~50-60 MB) but Node-API compatible (where llrt is a subset).
$ErrorActionPreference = "Stop"

# Verify bun is available
$bun = (Get-Command bun -ErrorAction SilentlyContinue)
if (-not $bun) { throw "bun not found on PATH. Install: https://bun.sh/" }

if (Test-Path dist) { Remove-Item -Recurse -Force dist }
New-Item -ItemType Directory -Path dist | Out-Null

Write-Host "[1-after-bun-compile] bun install (build-time only)" -ForegroundColor Cyan
bun install --silent | Out-Host

Write-Host "[1-after-bun-compile] bun build --compile --minify ..." -ForegroundColor Cyan
bun run build | Out-Host

$exe = if ($IsWindows -or $env:OS -eq "Windows_NT") { "dist/app.exe" } else { "dist/app" }
if (-not (Test-Path $exe)) { throw "Bun compile failed: $exe not found" }

$size = (Get-Item $exe).Length
Write-Host ("Artifact: {0}  (single binary — bun runtime bundled, no Node needed)" -f $exe)
Write-Host ("Size:     {0:N2} MB ({1:N0} bytes)" -f ($size / 1MB), $size)

Write-Host "Verifying output..." -ForegroundColor Cyan
$output = & $exe
Write-Host ("Output:   {0}" -f $output)

Write-Host "Cold-start (3 runs)..." -ForegroundColor Cyan
1..3 | ForEach-Object {
    $ms = (Measure-Command { & $exe | Out-Null }).TotalMilliseconds
    Write-Host ("  run {0}: {1:N0} ms" -f $_, $ms)
}
