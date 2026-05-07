# 1-optimize-quarkus-native: Quarkus native (native-first JVM framework, GraalVM-compiled)
# Requires: GraalVM 21 with native-image (run `gu install native-image`)
$ErrorActionPreference = "Stop"

Write-Host "[1-optimize-quarkus-native] mvn -Pnative clean package -DskipTests" -ForegroundColor Cyan
Write-Host "(Quarkus native build — expect 2-4 min build time, faster than Spring Native)" -ForegroundColor DarkGray
mvn -q -Pnative clean package -DskipTests | Out-Host

$exe = if ($IsWindows -or $env:OS -eq "Windows_NT") { "target/app-1.0.0-runner.exe" } else { "target/app-1.0.0-runner" }
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
