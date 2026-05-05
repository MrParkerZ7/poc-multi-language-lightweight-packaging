# Go — Lightweight Packaging

Same trivial CLI in two production-deployment shapes.

| Variant | Artifact | Target size | Runtime needed on host? | Cold-start | Technique |
|---------|----------|------------:|:------------------------|-----------:|-----------|
| `before-minimize/` | `app.exe` (default `go build`) | ~6–8 MB | **No** (always) | ~5 ms | Default `go build` — already a single static binary |
| `after-minimize/` | `app.exe` (stripped + UPX-compressed) | **~1.5 MB** | **No** | ~4 ms | `go build -ldflags="-s -w" -trimpath` + `upx --best --lzma` |

## Why is "before" already lightweight?

Go produces single static binaries by default — the runtime, garbage collector, and stdlib all link statically into the executable. No JVM, no .NET host, no Python interpreter, no `node_modules/`. So the *runtime-needed* column is "No" for every Go build, and the *before/after* story is just "shrink the binary further":

- `-ldflags="-s -w"` strips the symbol table and DWARF debug info (~20–30% smaller).
- `-trimpath` removes filesystem paths from the binary (smaller, also a security/reproducibility win).
- `upx --best --lzma` compresses the binary at rest; it self-decompresses into memory at startup (small cold-start cost, ~3× smaller binary).

For exec audiences, the Go row is the "no minimization needed and it's already smaller than every other language's *after*" reference point. Add UPX if you want to make it dramatic.

## How to build

```powershell
# Default (already lightweight)
cd before-minimize
./build.ps1

# Stripped + UPX
cd after-minimize
./build.ps1
```

## Prerequisites

- Go 1.21 or later
- For `after-minimize/`: UPX (https://upx.github.io/). On Windows: `choco install upx` or download the binary and put it on PATH.

## Trade-offs (for the exec)

> "Should we always UPX in production?"

UPX has known anti-virus false-positive rates on Windows (some AV vendors flag UPX-packed binaries because malware also uses UPX). For internal CLIs and Linux containers UPX is fine. For widely-distributed Windows software, consider stripped binaries without UPX, or a code-signing certificate to mitigate the false-positive issue.

> "Anything beyond UPX?"

`-trimpath -buildvcs=false` for max reproducibility. Build tags to exclude unused stdlib paths (`netgo`, `osusergo`) for slightly smaller results. None of this gets you below ~1 MB though — Go's runtime floor is ~800 KB.
