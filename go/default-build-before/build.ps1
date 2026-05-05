# default-build-before: default go build
$ErrorActionPreference = "Stop"

Write-Host "[default-build-before] go build" -ForegroundColor Cyan
go build -o app.exe .

if (-not (Test-Path app.exe)) { throw "Build failed: app.exe not found" }

$size = (Get-Item app.exe).Length
Write-Host ("Artifact: app.exe")
Write-Host ("Size:     {0:N2} MB ({1:N0} bytes)" -f ($size / 1MB), $size)

Write-Host "Verifying output..." -ForegroundColor Cyan
$output = & ./app.exe
Write-Host ("Output:   {0}" -f $output)

Write-Host "Cold-start (3 runs)..." -ForegroundColor Cyan
1..3 | ForEach-Object {
    $ms = (Measure-Command { & ./app.exe | Out-Null }).TotalMilliseconds
    Write-Host ("  run {0}: {1:N0} ms" -f $_, $ms)
}
