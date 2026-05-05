# after-minimize-no-runtime: esbuild bundle + AWS llrt binary (no Node install needed on host)
$ErrorActionPreference = "Stop"

if (Test-Path dist) { Remove-Item -Recurse -Force dist }

Write-Host "[after-minimize-no-runtime] npm install (build-time only)" -ForegroundColor Cyan
npm install --silent --no-audit --no-fund | Out-Host

Write-Host "[after-minimize-no-runtime] npm run build (esbuild for llrt)" -ForegroundColor Cyan
npm run build | Out-Host

# Download llrt binary if missing
$llrtZip = "dist/llrt.zip"
$llrtExe = "dist/llrt.exe"
if (-not (Test-Path $llrtExe)) {
    Write-Host "Downloading AWS llrt..." -ForegroundColor Cyan
    $url = "https://github.com/awslabs/llrt/releases/latest/download/llrt-windows-x64.zip"
    Invoke-WebRequest -Uri $url -OutFile $llrtZip -UseBasicParsing
    Expand-Archive -Path $llrtZip -DestinationPath "dist" -Force
    Remove-Item $llrtZip
    if (-not (Test-Path $llrtExe)) {
        # zip layout sometimes differs — find any llrt*.exe
        $found = Get-ChildItem dist -Filter "llrt*.exe" -Recurse | Select-Object -First 1
        if ($found) { Move-Item $found.FullName $llrtExe -Force }
    }
    if (-not (Test-Path $llrtExe)) { throw "Could not extract llrt.exe from $url" }
}

$bundle = "dist/app.mjs"
if (-not (Test-Path $bundle)) { throw "Bundle failed: $bundle not found" }

$bundleSize = (Get-Item $bundle).Length
$llrtSize   = (Get-Item $llrtExe).Length
$total      = $bundleSize + $llrtSize

Write-Host ("Artifacts: {0} + {1}" -f $bundle, $llrtExe)
Write-Host ("Bundle:    {0:N1} KB ({1:N0} bytes)" -f ($bundleSize / 1KB), $bundleSize)
Write-Host ("llrt:      {0:N2} MB" -f ($llrtSize / 1MB))
Write-Host ("TOTAL:     {0:N2} MB ({1:N0} bytes)  — ship both, no Node install needed" -f ($total / 1MB), $total)

Write-Host "Verifying output..." -ForegroundColor Cyan
$output = & $llrtExe $bundle
Write-Host ("Output:   {0}" -f $output)

Write-Host "Cold-start (3 runs)..." -ForegroundColor Cyan
1..3 | ForEach-Object {
    $ms = (Measure-Command { & $llrtExe $bundle | Out-Null }).TotalMilliseconds
    Write-Host ("  run {0}: {1:N0} ms" -f $_, $ms)
}
