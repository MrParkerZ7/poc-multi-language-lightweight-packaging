# 3-best (Java/Kotlin): GraalVM native + every 2-amalgamate flag + epsilon GC + UPX (LZMA)
# Trade: epsilon GC = no garbage collection, process must exit before heap fills (8 MB cap).
#        UPX may trip Windows AV scanners — use Linux container in production.
$ErrorActionPreference = "Stop"

Write-Host "[3-best] mvn -Pnative clean package -DskipTests" -ForegroundColor Cyan
Write-Host "(GraalVM native + epsilon GC + max trim - expect 3-6 min build)" -ForegroundColor DarkGray
mvn -q -Pnative clean package -DskipTests | Out-Host

$exe = if ($IsWindows -or $env:OS -eq "Windows_NT") { "target/app.exe" } else { "target/app" }
if (-not (Test-Path $exe)) { throw "Native build failed: $exe not found. Confirm GraalVM is installed and native-image is on PATH." }
$preUpxSize = (Get-Item $exe).Length

# UPX on GraalVM native: usually works on Linux ELF; risky on Windows PE (relocations).
# 3-best accepts this risk explicitly; for safer profile use 2-amalgamate.
$upx = (Get-Command upx -ErrorAction SilentlyContinue)
if ($upx -and ($IsLinux -or ($env:OS -ne "Windows_NT"))) {
    Write-Host "[3-best] upx --best --lzma" -ForegroundColor Cyan
    upx --best --lzma $exe 2>&1 | Out-Host
} elseif ($upx) {
    Write-Warning "Skipping UPX on Windows native-image (PE relocation issues). Linux container will UPX."
}

$size = (Get-Item $exe).Length
Write-Host ("Artifact: {0}" -f $exe)
Write-Host ("After GraalVM + epsilon GC + max trim: {0:N2} MB" -f ($preUpxSize / 1MB))
Write-Host ("After UPX (if applied):                {0:N2} MB ({1:N0} bytes)" -f ($size / 1MB), $size)

Write-Host "Verifying output..." -ForegroundColor Cyan
$output = & $exe
Write-Host ("Output:   {0}" -f $output)

Write-Host "Cold-start (3 runs)..." -ForegroundColor Cyan
1..3 | ForEach-Object {
    $ms = (Measure-Command { & $exe | Out-Null }).TotalMilliseconds
    Write-Host ("  run {0}: {1:N0} ms" -f $_, $ms)
}
