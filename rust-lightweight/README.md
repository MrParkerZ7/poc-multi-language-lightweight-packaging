# Rust — Lightweight Packaging

Same trivial CLI in two production-deployment shapes.

## The Problem

Rust shares Go's situation: single static binary by default, no runtime installed anywhere. The "before" is already lightweight by Java/Python/Node standards.

The remaining issue is **default release builds optimize for speed, not size**. The linker keeps panic-unwinding machinery, debug symbols, and per-crate compilation units (which limits cross-crate inlining). Default `cargo build --release` produces 4–6 MB binaries even for trivial CLIs.

Where Rust differs from Go is how *much* room exists to shrink. Rust's `Cargo.toml` exposes very granular optimization levers — `opt-level = "z"`, `lto = true`, `codegen-units = 1`, `panic = "abort"`, `strip = true` — that combine to produce binaries 5–10× smaller than the default. That's because Rust monomorphizes generics aggressively (great for speed, bad for size) and the size flags reverse those choices.

For exec audiences this becomes the most dramatic "after" in the table: ~400 KB for the same logic that Python ships at 80 MB. Same operational shape (no runtime, instant start), but at a different order of magnitude on disk and bandwidth.

## The Solution(s)

| Variant | Artifact | Target size | Runtime needed on host? | Cold-start | Technique |
|---------|----------|------------:|:------------------------|-----------:|-----------|
| `before-minimize/` | `app.exe` (default `cargo build --release`) | ~4–6 MB | **No** (always) | ~3 ms | Default release build |
| `after-minimize/` | `app.exe` (opt-z + LTO + strip + UPX) | **~400 KB** | **No** | ~2 ms | `opt-level="z"`, `lto=true`, `strip=true`, `panic="abort"`, `codegen-units=1`, then UPX |

## Why is "before" already lightweight?

Like Go, Rust produces single static binaries — no runtime needed, ever. The before/after story is again "shrink the binary further", but Rust pushes much harder than Go because:

- **`opt-level = "z"`** — optimize for size instead of speed (often nearly free in real cold-start cost).
- **`lto = true`** (link-time optimization) — cross-crate inlining + dead code elimination.
- **`strip = true`** — drop symbols/debug info.
- **`panic = "abort"`** — replace panic-unwind machinery with immediate abort (smaller, sometimes faster).
- **`codegen-units = 1`** — single compilation unit, more aggressive optimization.
- **UPX** — final compression pass.

Combined, these can turn a 5 MB default release into a ~300–500 KB binary. For exec-friendly numbers, this is the most dramatic "after" in the table.

## How to build

```powershell
# Default release (already lightweight)
cd before-minimize
./build.ps1

# Aggressive size optimization + UPX
cd after-minimize
./build.ps1
```

## Prerequisites

- rustup + cargo (stable channel)
- For `after-minimize/`: UPX (https://upx.github.io/)

## Trade-offs (for the exec)

> "Are these size flags safe for production?"

Yes — all of them are mainstream and used in shipped Rust binaries. `panic="abort"` is the only one that changes runtime behavior: instead of unwinding the stack on panic (allowing destructors and panic handlers), the program exits immediately. For a CLI this is fine; for a long-running service that uses `catch_unwind`, weigh carefully.

> "What's UPX cost at runtime?"

Decompression at process start: typically 5–20 ms on modern hardware. For an already 2 ms cold-start CLI that's a 5–10× relative slowdown but still faster than every other language's optimized cold-start. For Lambda or edge functions billed per-millisecond, measure first.
