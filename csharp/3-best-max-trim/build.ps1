$13-best-max-trim (C#): AOT + every 2-amalgamate flag + extra trim + stack-trace data off
# Skips UPX — known incompatibility with .NET AOT loader (UPX corrupts the segment layout).
$ErrorActionPreference = "Stop"

Write-Host "[3-best-max-trim] dotnet publish -c Release -r win-x64" -ForegroundColor Cyan
Write-Host "(AOT compile with most aggressive trim - expect 1-3 min)" -ForegroundColor DarkGray
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
