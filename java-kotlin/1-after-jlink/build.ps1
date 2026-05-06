# 1-after-jlink: jlink runtime image via jpackage --type app-image
# Result: target/app/  (folder containing custom JRE + app + Jackson lib, no JDK install needed)
$ErrorActionPreference = "Stop"

Write-Host "[1-after-jlink] mvn clean package -DskipTests" -ForegroundColor Cyan
mvn -q clean package -DskipTests

$mainJar = "target/app.jar"
if (-not (Test-Path $mainJar)) { throw "Build failed: $mainJar not found" }

# Detect required JDK modules with jdeps (uses --print-module-deps for jlink-friendly output)
Write-Host "Detecting JDK modules with jdeps..." -ForegroundColor Cyan
$modules = (& jdeps --print-module-deps --multi-release 21 --recursive --class-path "target/lib/*" $mainJar) -join ","
if (-not $modules) { $modules = "java.base" }
Write-Host ("Required modules: {0}" -f $modules)

# Build jlink-trimmed runtime + app image via jpackage
$appDir = "target/app"
if (Test-Path $appDir) { Remove-Item -Recurse -Force $appDir }

Write-Host "Building app-image with jpackage (uses jlink internally)..." -ForegroundColor Cyan
jpackage `
    --type app-image `
    --name app `
    --input target/lib `
    --main-jar "../app.jar" `
    --main-class com.example.App `
    --add-modules $modules `
    --dest target

if (-not (Test-Path $appDir)) { throw "jpackage failed" }

$bytes = (Get-ChildItem $appDir -Recurse -File | Measure-Object -Property Length -Sum).Sum
Write-Host ("Artifact: {0}/  (folder)" -f $appDir)
Write-Host ("Size:     {0:N2} MB ({1:N0} bytes)" -f ($bytes / 1MB), $bytes)

$exe = "$appDir/app.exe"
if (-not (Test-Path $exe)) { $exe = "$appDir/bin/app" }

Write-Host "Verifying output..." -ForegroundColor Cyan
$output = & $exe
Write-Host ("Output:   {0}" -f $output)

Write-Host "Cold-start (3 runs)..." -ForegroundColor Cyan
1..3 | ForEach-Object {
    $ms = (Measure-Command { & $exe | Out-Null }).TotalMilliseconds
    Write-Host ("  run {0}: {1:N0} ms" -f $_, $ms)
}
