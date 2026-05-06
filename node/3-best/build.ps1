# 3-best (Node): esbuild max minify + QuickJS-NG runtime (~1 MB) + UPX-LZMA + scratch-ready
# Trade: QuickJS-NG covers ECMAScript core but NOT Node APIs (no `node:fs`, no `node:http`, no `node:crypto`).
#        Source must use only pure-ECMAScript built-ins. Smaller and faster cold-start than llrt
#        when your code happens to fit in this constraint.
$ErrorActionPreference = "Stop"

if (Test-Path dist) { Remove-Item -Recurse -Force dist }
New-Item -ItemType Directory -Path dist | Out-Null

Write-Host "[3-best] npm install (build-time only)" -ForegroundColor Cyan
npm install --silent --no-audit --no-fund | Out-Host

Write-Host "[3-best] esbuild bundle + max minify (platform=neutral, target=es2023)" -ForegroundColor Cyan
npm run build | Out-Host

# Download QuickJS-NG release (precompiled binary)
$qjsExe = "dist/qjs.exe"
if (-not (Test-Path $qjsExe)) {
    Write-Host "[3-best] downloading QuickJS-NG" -ForegroundColor Cyan
    $url = "https://github.com/quickjs-ng/quickjs/releases/latest/download/qjs-windows-x64.exe"
    try {
        Invoke-WebRequest -Uri $url -OutFile $qjsExe -UseBasicParsing
    } catch {
        Write-Warning "QuickJS-NG release not found at expected URL; falling back to building from source via WSL/Docker recommended."
        Write-Host "Attempting alternate URL..." -ForegroundColor Cyan
        $url2 = "https://github.com/quickjs-ng/quickjs/releases/download/v0.5.0/quickjs-windows-x64.zip"
        Invoke-WebRequest -Uri $url2 -OutFile "dist/qjs.zip" -UseBasicParsing -ErrorAction SilentlyContinue
        if (Test-Path "dist/qjs.zip") {
            Expand-Archive -Path "dist/qjs.zip" -DestinationPath "dist" -Force
            $found = Get-ChildItem dist -Filter "qjs*.exe" -Recurse | Select-Object -First 1
            if ($found) { Move-Item $found.FullName $qjsExe -Force }
        }
    }
}

# UPX-LZMA on QuickJS binary
$upx = (Get-Command upx -ErrorAction SilentlyContinue)
if ($upx -and (Test-Path $qjsExe)) {
    Write-Host "[3-best] upx --best --lzma qjs.exe" -ForegroundColor Cyan
    upx --best --lzma $qjsExe 2>&1 | Out-Host
} elseif (-not $upx) {
    Write-Warning "UPX not on PATH — skipping qjs compression."
}

$bundle = "dist/app.mjs"
$bundleSize = (Get-Item $bundle).Length
$qjsSize    = if (Test-Path $qjsExe) { (Get-Item $qjsExe).Length } else { 0 }
$total      = $bundleSize + $qjsSize

Write-Host ("Artifacts: {0} + {1}" -f $bundle, $qjsExe)
Write-Host ("Bundle:    {0:N1} KB" -f ($bundleSize / 1KB))
Write-Host ("qjs (UPX): {0:N2} MB" -f ($qjsSize / 1MB))
Write-Host ("TOTAL:     {0:N2} MB ({1:N0} bytes)" -f ($total / 1MB), $total)

if (Test-Path $qjsExe) {
    Write-Host "Verifying output..." -ForegroundColor Cyan
    $output = & $qjsExe $bundle
    Write-Host ("Output:   {0}" -f $output)

    Write-Host "Cold-start (3 runs)..." -ForegroundColor Cyan
    1..3 | ForEach-Object {
        $ms = (Measure-Command { & $qjsExe $bundle | Out-Null }).TotalMilliseconds
        Write-Host ("  run {0}: {1:N0} ms" -f $_, $ms)
    }
}
