# after-trimmed: PublishTrimmed (no AOT) — drops unused IL while keeping the JIT runtime
# Middle-ground between self-contained (big, full reflection) and AOT (small, restricted reflection)
$ErrorActionPreference = "Stop"

Write-Host "[after-trimmed] dotnet publish -c Release -r win-x64" -ForegroundColor Cyan
dotnet publish -c Release -r win-x64 -o publish | Out-Host

$exe = "publish/app.exe"
if (-not (Test-Path $exe)) { throw "Trimmed publish failed: $exe not found" }

$size = (Get-Item $exe).Length
$folder = (Get-ChildItem "publish" -Recurse -File | Measure-Object -Property Length -Sum).Sum
Write-Host ("Artifact: {0}" -f $exe)
Write-Host ("Single file size:  {0:N2} MB ({1:N0} bytes)" -f ($size / 1MB), $size)
Write-Host ("Total publish dir: {0:N2} MB" -f ($folder / 1MB))

Write-Host "Verifying output..." -ForegroundColor Cyan
$output = & $exe
Write-Host ("Output:   {0}" -f $output)

Write-Host "Cold-start (3 runs)..." -ForegroundColor Cyan
1..3 | ForEach-Object {
    $ms = (Measure-Command { & $exe | Out-Null }).TotalMilliseconds
    Write-Host ("  run {0}: {1:N0} ms" -f $_, $ms)
}
