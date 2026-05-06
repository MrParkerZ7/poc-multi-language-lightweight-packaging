# 0-before-spring-boot-fat-jar: Spring Boot fat JAR
$ErrorActionPreference = "Stop"

Write-Host "[0-before-spring-boot-fat-jar] mvn clean package -DskipTests" -ForegroundColor Cyan
mvn -q clean package -DskipTests

$jar = "target/app.jar"
if (-not (Test-Path $jar)) { throw "Build failed: $jar not found" }

$size = (Get-Item $jar).Length
Write-Host ("Artifact: {0}" -f $jar)
Write-Host ("Size:     {0:N2} MB ({1:N0} bytes)" -f ($size / 1MB), $size)

Write-Host "Verifying output..." -ForegroundColor Cyan
$output = & java -jar $jar
Write-Host ("Output:   {0}" -f $output)

Write-Host "Cold-start (3 runs)..." -ForegroundColor Cyan
1..3 | ForEach-Object {
    $ms = (Measure-Command { & java -jar $jar | Out-Null }).TotalMilliseconds
    Write-Host ("  run {0}: {1:N0} ms" -f $_, $ms)
}
