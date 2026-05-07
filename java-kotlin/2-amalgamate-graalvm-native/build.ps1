$12-amalgamate-graalvm-native (Java/Kotlin): GraalVM native + every safe size knob + scratch container
# Stacks: native AOT + -Os + serial GC + initialize-at-build-time + Optimize=2
# Note: skips UPX — UPX compression breaks GraalVM native binaries (relocation issues)
$ErrorActionPreference = "Stop"

Write-Host "[2-amalgamate-graalvm-native] mvn -Pnative clean package -DskipTests" -ForegroundColor Cyan
Write-Host "(GraalVM native with stacked size flags — expect 2-5 min build time)" -ForegroundColor DarkGray
mvn -q -Pnative clean package -DskipTests | Out-Host

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
