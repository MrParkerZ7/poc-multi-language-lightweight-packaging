# Rust — 3-best (smallest possible)

Stacks every `2-amalgamate` knob, then adds nightly-only levers that rebuild `std` itself with size optimizations.

## What's stacked on top of 2-amalgamate

| Lever | Effect |
|-------|--------|
| `-Z build-std=std,panic_abort` (nightly) | Rebuild std/alloc/core from source with the same `opt-level=z` / LTO settings as our crate |
| `-Z build-std-features=panic_immediate_abort` | Replace every panic site with an immediate `abort` instead of formatted unwind text |
| `-Z build-std-features=optimize_for_size` | Pass size hints to the std rebuild (overrides std's default speed-tilted opt-level) |
| `-Zlocation-detail=none` | Strip file:line metadata used by panic messages |
| `-Zfmt-debug=none` | Drop derived `Debug` formatting code |
| `upx --best --lzma` | Final LZMA compression pass |

Plus every flag already in `2-amalgamate`: musl static target, `opt-level="z"`, `lto="fat"`, `codegen-units=1`, `panic="abort"`, `strip="symbols"`, `overflow-checks=false`.

## Trade-offs

- **Nightly Rust required** — pinned via `rust-toolchain.toml`. Stable users can't reproduce.
- **Panic messages are uninformative** — `panic_immediate_abort` collapses every panic to a single `abort()` call. No backtrace, no message text.
- **Build time ~3-6 min on first run** — rebuilding std is expensive. Subsequent builds use the cached `target/` artifacts.
- **No `#![no_std]` rewrite needed** — keeps the same source as `2-amalgamate`, so behavior is identical when nothing panics.

## Why not `#![no_std]`?

`#![no_std]` would force dropping `chrono` / `serde_json` / `uuid` (they all transitively need std) and writing manual JSON serialization + manual UUIDv4 + manual time formatting. That'd shave another ~30-40 KB but turns the demo from "production-shaped CLI" into a research-grade exercise. `build-std` keeps the realistic dependency tree while still rebuilding the std those deps pull in.

## Target size

| Stage | Size |
|-------|-----:|
| `2-amalgamate` (musl + cargo size profile + UPX) | ~300 KB |
| `3-best` after `build-std` + `panic_immediate_abort` + size flags | ~140 KB |
| `3-best` after final UPX `--best --lzma` | **~80 KB** |

## How to build

```powershell
./build.ps1
```

The build script reads `rust-toolchain.toml` (nightly channel + rust-src component + musl target) and `.cargo/config.toml` (build-std flags). No manual setup beyond `rustup`.

## Prerequisites

- `rustup` (the toolchain itself is installed automatically from `rust-toolchain.toml`)
- UPX on PATH (https://upx.github.io/)
- For Docker build: nothing extra — the Dockerfile uses `rustlang/rust:nightly-alpine`
