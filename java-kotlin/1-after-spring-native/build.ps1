# 1-after-spring-native: Spring Boot 3 + GraalVM native image (keeps Spring, AOT-compiled)
# Requires: GraalVM 21 with native-image (run `gu install native-image`)
$ErrorActionPreference = "Stop"

Write-Host "[1-after-spring-native] mvn -Pnative native:compile -DskipTests" -ForegroundColor Cyan
Write-Host "(Spring Boot 3 + GraalVM AOT — expect 2-5 min build time)" -ForegroundColor DarkGray
mvn -q -Pnative native:compile -DskipTests | Out-Host

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
