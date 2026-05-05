# before-minimize: venv + installed deps (the typical "ship everything" Python deployment)
$ErrorActionPreference = "Stop"

if (Test-Path .venv) { Remove-Item -Recurse -Force .venv }

Write-Host "[before-minimize] python -m venv .venv" -ForegroundColor Cyan
python -m venv .venv

Write-Host "[before-minimize] pip install -r requirements.txt" -ForegroundColor Cyan
& .\.venv\Scripts\python.exe -m pip install --quiet --upgrade pip
& .\.venv\Scripts\python.exe -m pip install --quiet -r requirements.txt

$bytes = (Get-ChildItem .venv -Recurse -File | Measure-Object -Property Length -Sum).Sum
$srcBytes = (Get-Item app.py).Length + (Get-Item requirements.txt).Length
$total = $bytes + $srcBytes

Write-Host ("Artifact: source + .venv/  (folder shipped together)")
Write-Host ("Source:     {0:N0} bytes" -f $srcBytes)
Write-Host ("venv + deps: {0:N2} MB" -f ($bytes / 1MB))
Write-Host ("TOTAL:       {0:N2} MB ({1:N0} bytes)" -f ($total / 1MB), $total)

Write-Host "Verifying output..." -ForegroundColor Cyan
$output = & .\.venv\Scripts\python.exe app.py
Write-Host ("Output:   {0}" -f $output)

Write-Host "Cold-start (3 runs)..." -ForegroundColor Cyan
1..3 | ForEach-Object {
    $ms = (Measure-Command { & .\.venv\Scripts\python.exe app.py | Out-Null }).TotalMilliseconds
    Write-Host ("  run {0}: {1:N0} ms" -f $_, $ms)
}
