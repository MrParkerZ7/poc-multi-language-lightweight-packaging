$12-amalgamate-llrt (Node): esbuild max minify + llrt + UPX-compress llrt + scratch-ready
# Stacks: bundle + minify + tree-shake + legal-comments=none + llrt + UPX on llrt binary
$ErrorActionPreference = "Stop"

if (Test-Path dist) { Remove-Item -Recurse -Force dist }
New-Item -ItemType Directory -Path dist | Out-Null

Write-Host "[2-amalgamate-llrt] npm install (build-time only)" -ForegroundColor Cyan
npm install --silent --no-audit --no-fund | Out-Host

Write-Host "[2-amalgamate-llrt] esbuild bundle + max minify" -ForegroundColor Cyan
npm run build | Out-Host

# Download llrt
$llrtZip = "dist/llrt.zip"
$llrtExe = "dist/llrt.exe"
if (-not (Test-Path $llrtExe)) {
    Write-Host "[2-amalgamate-llrt] downloading AWS llrt" -ForegroundColor Cyan
    $url = "https://github.com/awslabs/llrt/releases/latest/download/llrt-windows-x64.zip"
    Invoke-WebRequest -Uri $url -OutFile $llrtZip -UseBasicParsing
    Expand-Archive -Path $llrtZip -DestinationPath "dist" -Force
    Remove-Item $llrtZip
    if (-not (Test-Path $llrtExe)) {
        $found = Get-ChildItem dist -Filter "llrt*.exe" -Recurse | Select-Object -First 1
        if ($found) { Move-Item $found.FullName $llrtExe -Force }
    }
}

# UPX-compress llrt to shrink the runtime side of the deploy
$upx = (Get-Command upx -ErrorAction SilentlyContinue)
if ($upx) {
    Write-Host "[2-amalgamate-llrt] upx --best --lzma llrt.exe" -ForegroundColor Cyan
    upx --best --lzma $llrtExe 2>&1 | Out-Host
} else {
    Write-Warning "UPX not on PATH — skipping llrt compression."
}

$bundle = "dist/app.mjs"
$bundleSize = (Get-Item $bundle).Length
$llrtSize   = (Get-Item $llrtExe).Length
$total      = $bundleSize + $llrtSize

Write-Host ("Artifacts: {0} + {1}" -f $bundle, $llrtExe)
Write-Host ("Bundle:     {0:N1} KB" -f ($bundleSize / 1KB))
Write-Host ("llrt (UPX): {0:N2} MB" -f ($llrtSize / 1MB))
Write-Host ("TOTAL:      {0:N2} MB ({1:N0} bytes)  — ship both, no Node install needed" -f ($total / 1MB), $total)

Write-Host "Verifying output..." -ForegroundColor Cyan
$output = & $llrtExe $bundle
Write-Host ("Output:   {0}" -f $output)

Write-Host "Cold-start (3 runs)..." -ForegroundColor Cyan
1..3 | ForEach-Object {
    $ms = (Measure-Command { & $llrtExe $bundle | Out-Null }).TotalMilliseconds
    Write-Host ("  run {0}: {1:N0} ms" -f $_, $ms)
}
