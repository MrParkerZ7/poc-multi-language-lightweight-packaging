$12-amalgamate-musl (Rust): musl static + opt-z + LTO=fat + strip + panic=abort + UPX + scratch
# The smallest reasonable Rust deployment shape — every applicable knob in the same direction.
$ErrorActionPreference = "Stop"

Write-Host "[2-amalgamate-musl] rustup target add x86_64-unknown-linux-musl" -ForegroundColor Cyan
rustup target add x86_64-unknown-linux-musl 2>&1 | Out-Host

Write-Host "[2-amalgamate-musl] cargo build --release --target x86_64-unknown-linux-musl" -ForegroundColor Cyan
cargo build --release --target x86_64-unknown-linux-musl | Out-Host

$bin = "target/x86_64-unknown-linux-musl/release/app"
if (-not (Test-Path $bin)) { throw "musl build failed: $bin not found" }
$preUpxSize = (Get-Item $bin).Length

$upx = (Get-Command upx -ErrorAction SilentlyContinue)
if ($upx) {
    Write-Host "[2-amalgamate-musl] upx --best --lzma" -ForegroundColor Cyan
    upx --best --lzma $bin | Out-Host
}
$size = (Get-Item $bin).Length

Write-Host ("Artifact: {0}" -f $bin)
Write-Host ("After musl + Cargo size profile: {0:N1} KB" -f ($preUpxSize / 1KB))
Write-Host ("After UPX:                       {0:N1} KB ({1:N0} bytes)" -f ($size / 1KB), $size)
Write-Host ""
Write-Host "Note: Linux ELF binary (cross-compiled). Run on a Linux host or container FROM scratch." -ForegroundColor DarkGray
