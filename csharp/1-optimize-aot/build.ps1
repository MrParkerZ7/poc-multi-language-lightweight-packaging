# 1-optimize-aot: Native AOT
# Requires: .NET SDK 8+ AND the C++ build tools (Visual Studio "Desktop development with C++" workload on Windows)
$ErrorActionPreference = "Stop"

Write-Host "[1-optimize-aot] dotnet publish -c Release -r win-x64" -ForegroundColor Cyan
Write-Host "(this is a real native compile â€” expect 30s to 2min)" -ForegroundColor DarkGray
dotnet publish -c Release -r win-x64 -o publish | Out-Host

$exe = "publish/app.exe"
if (-not (Test-Path $exe)) { throw "AOT publish failed: $exe not found. Confirm C++ build tools are installed." }

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
