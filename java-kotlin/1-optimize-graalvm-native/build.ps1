# 1-optimize-graalvm-native: GraalVM native image
# Requires: GraalVM 21 + native-image (run `gu install native-image`)
$ErrorActionPreference = "Stop"

Write-Host "[1-optimize-graalvm-native] mvn -Pnative clean package -DskipTests" -ForegroundColor Cyan
mvn -q -Pnative clean package -DskipTests

$exe = if ($IsWindows -or $env:OS -eq "Windows_NT") { "target/app.exe" } else { "target/app" }
if (-not (Test-Path $exe)) { throw "Native build failed: $exe not found. Confirm GraalVM is installed and native-image is on PATH." }

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
