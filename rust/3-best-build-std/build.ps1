$13-best-build-std (Rust): nightly + build-std + panic_immediate_abort + optimize_for_size
#                + everything in 2-amalgamate (musl static, opt-z, LTO=fat, strip, panic=abort)
#                + UPX --best --lzma
# Trade: nightly Rust required. Some panic messages collapse to a single immediate-abort site
#        (smaller binary, less debug info on panic). Major code rewrite NOT required —
#        rebuilds std/alloc/core with the size flags rather than dropping std.
$ErrorActionPreference = "Stop"

# rustup toolchain installs come from rust-toolchain.toml (nightly + rust-src + musl target).
Write-Host "[3-best-build-std] ensure nightly + rust-src + musl target" -ForegroundColor Cyan
rustup show active-toolchain 2>&1 | Out-Host

Write-Host "[3-best-build-std] cargo +nightly build --release --target x86_64-unknown-linux-musl" -ForegroundColor Cyan
Write-Host "(rebuilds std with size flags - expect 3-6 min on first run)" -ForegroundColor DarkGray
cargo +nightly build --release --target x86_64-unknown-linux-musl | Out-Host

$bin = "target/x86_64-unknown-linux-musl/release/app"
if (-not (Test-Path $bin)) { throw "build-std build failed: $bin not found" }
$preUpxSize = (Get-Item $bin).Length

$upx = (Get-Command upx -ErrorAction SilentlyContinue)
if ($upx) {
    Write-Host "[3-best-build-std] upx --best --lzma" -ForegroundColor Cyan
    upx --best --lzma $bin | Out-Host
}
$size = (Get-Item $bin).Length

Write-Host ("Artifact: {0}" -f $bin)
Write-Host ("After build-std + size profile: {0:N1} KB" -f ($preUpxSize / 1KB))
Write-Host ("After UPX --best --lzma:        {0:N1} KB ({1:N0} bytes)" -f ($size / 1KB), $size)
Write-Host ""
Write-Host "Note: Linux ELF binary (cross-compiled). Run on a Linux host or container FROM scratch." -ForegroundColor DarkGray
