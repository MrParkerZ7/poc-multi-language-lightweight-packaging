# 1-optimize-musl-static: statically-linked Linux binary (suitable for FROM scratch container)
# musl libc statically linked — no dynamic dependencies, runs on any Linux distro
# Requires: rustup target add x86_64-unknown-linux-musl
$ErrorActionPreference = "Stop"

Write-Host "[1-optimize-musl-static] rustup target add x86_64-unknown-linux-musl" -ForegroundColor Cyan
rustup target add x86_64-unknown-linux-musl 2>&1 | Out-Host

Write-Host "[1-optimize-musl-static] cargo build --release --target x86_64-unknown-linux-musl" -ForegroundColor Cyan
Write-Host "(builds a static Linux binary even on Windows — for FROM scratch containers)" -ForegroundColor DarkGray
cargo build --release --target x86_64-unknown-linux-musl | Out-Host

$bin = "target/x86_64-unknown-linux-musl/release/app"
if (-not (Test-Path $bin)) { throw "musl build failed: $bin not found" }

$size = (Get-Item $bin).Length
Write-Host ("Artifact: {0}" -f $bin)
Write-Host ("Size:     {0:N2} MB ({1:N0} bytes)" -f ($size / 1MB), $size)
Write-Host ""
Write-Host "Note: this is a Linux ELF binary. Cannot execute directly on Windows." -ForegroundColor DarkGray
Write-Host "To verify, copy to a Linux host (or container FROM scratch) and run." -ForegroundColor DarkGray
