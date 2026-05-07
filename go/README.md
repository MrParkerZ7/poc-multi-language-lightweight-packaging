# Go — Lightweight Packaging

Same trivial CLI in three production-deployment shapes.

## The Problem

Go doesn't have the "needs a runtime installed on the host" problem at all — every `go build` produces a single static binary that runs on a vanilla machine. Most of the pain that Java, C#, Python, and Node face simply doesn't apply.

The remaining issue is **binary size**: Go's runtime, garbage collector, type metadata, and DWARF debug info contribute ~5 MB of overhead even for trivial programs. Default release binaries are 6–8 MB regardless of how much code you actually wrote.

For most teams this is already lighter than every other language's optimized output — Go's "before" is smaller than Java's "after" (jlink). It only matters when:

- Shipping to **extreme scale** — hundreds of services in a Kubernetes cluster, where image size × replicas × regions adds up
- Distributing to **bandwidth-constrained edges** — CDN edge functions, IoT firmware, embedded systems
- Cold-start sensitive workloads where binary load time matters at the 10-millisecond level

For those cases, stripping symbols and UPX-compressing brings Go to ~1.5 MB without losing any runtime behavior — same self-contained, same cold-start, just 4–5× smaller on disk.

## The Solution(s)

| Variant | Artifact | Target size | Runtime needed on host? | Cold-start | Technique |
|---------|----------|------------:|:------------------------|-----------:|-----------|
| `0-standard-default-build/` | `app.exe` (default `go build`) | ~6–8 MB | **No** (always) | ~5 ms | Default `go build` — already a single static binary |
| `1-optimize-strip-upx/` | `app.exe` (stripped + UPX-compressed) | **~1.5 MB** | **No** | ~4 ms | `go build -ldflags="-s -w" -trimpath` + `upx --best --lzma` |
| `1-optimize-tinygo/` | `app.exe` (TinyGo compiler) | **~0.5 MB** | **No** | ~4 ms | `tinygo build -opt=z` — alternative compiler, much smaller; trade-off: smaller stdlib coverage |
| `2-amalgamate-tinygo/` | TinyGo + opt=z + UPX | **~0.2 MB** | **No** | ~5 ms | TinyGo with `-opt=z -no-debug` then UPX `--best --lzma`, ships from `FROM scratch`. Note: UPX adds ~5–20 ms decompression to cold-start. |
| `3-best-leaking-gc/` | TinyGo + leaking GC + no scheduler + panic-trap + UPX-LZMA | **~0.12 MB** | **No** | ~6 ms | Adds `-gc=leaking` (no GC, leak everything) + `-scheduler=none` (single-threaded) + `-panic=trap` (silent crash). **Trade**: single-shot CLI only — must exit cleanly to release memory; no goroutines; crashes silently. |

## Why is "before" already lightweight?

Go produces single static binaries by default — the runtime, garbage collector, and stdlib all link statically into the executable. No JVM, no .NET host, no Python interpreter, no `node_modules/`. So the *runtime-needed* column is "No" for every Go build, and the *before/after* story is just "shrink the binary further":

- `-ldflags="-s -w"` strips the symbol table and DWARF debug info (~20–30% smaller).
- `-trimpath` removes filesystem paths from the binary (smaller, also a security/reproducibility win).
- `upx --best --lzma` compresses the binary at rest; it self-decompresses into memory at startup (small cold-start cost, ~3× smaller binary).

For exec audiences, the Go row is the "no minimization needed and it's already smaller than every other language's *after*" reference point. Add UPX if you want to make it dramatic.

## How to build

```powershell
# Default (naive baseline — already lightweight)
cd 0-standard-default-build
./build.ps1

# Stripped + UPX
cd 1-optimize-strip-upx
./build.ps1

# TinyGo compiler (much smaller, but smaller stdlib coverage)
cd 1-optimize-tinygo
./build.ps1   # requires tinygo: https://tinygo.org/

# 2-amalgamate: TinyGo + opt=z + UPX + scratch
cd 2-amalgamate-tinygo
./build.ps1

# 3-best: TinyGo + leaking GC + no scheduler + panic-trap + UPX-LZMA (smallest possible)
cd 3-best-leaking-gc
./build.ps1
```

## Prerequisites

- Go 1.21 or later
- For `1-optimize-strip-upx/`: UPX (https://upx.github.io/). On Windows: `choco install upx` or download the binary and put it on PATH.
- For `1-optimize-tinygo/`: TinyGo (https://tinygo.org/getting-started/install/). Note: `encoding/json` and a few stdlib packages have limited support in TinyGo — verify the trivial CLI builds before relying on it for richer code.

## Trade-offs (for the exec)

> "Should we always UPX in production?"

UPX has known anti-virus false-positive rates on Windows (some AV vendors flag UPX-packed binaries because malware also uses UPX). For internal CLIs and Linux containers UPX is fine. For widely-distributed Windows software, consider stripped binaries without UPX, or a code-signing certificate to mitigate the false-positive issue.

> "Anything beyond UPX?"

`-trimpath -buildvcs=false` for max reproducibility. Build tags to exclude unused stdlib paths (`netgo`, `osusergo`) for slightly smaller results. None of this gets you below ~1 MB though — Go's runtime floor is ~800 KB.
