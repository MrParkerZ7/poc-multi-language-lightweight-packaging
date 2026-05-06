# Java / Kotlin — 3-best (smallest possible)

Stacks every `2-amalgamate` flag, then swaps the GC for epsilon (no-op) and accepts the UPX-on-native-binary risk.

## What's stacked on top of 2-amalgamate

| Lever | Effect |
|-------|--------|
| `--gc=epsilon` | No-op GC. Allocations succeed until heap fills, then abort. Fine for a process that exits in <100 ms. |
| `-R:MaxHeapSize=8m` | Cap the heap at 8 MB — small fixed footprint, fails fast if the CLI ever leaks. |
| `-H:-IncludeMethodData` | Strip method-name metadata used by stack traces. |
| `--strict-image-heap` | Disallow runtime heap allocations of types that weren't initialized at build-time. Forces every type through build-time init. |
| `-H:+RemoveSaturatedTypeFlows` | Aggressive type-flow analysis pruning during AOT compilation. |
| `--enable-monitoring=` (empty) | Drop JFR / heap dump / VM inspection (was implicit on by default). |
| `upx --best --lzma` (Linux only) | LZMA compression. Skipped on Windows native-image (PE relocation issues). |

Plus every flag already in `2-amalgamate`: native AOT + `-Os` + `--gc=serial` (now epsilon) + build-time init + `-H:Optimize=2` + `-H:-IncludeAllTimeZones`.

## Trade-offs

- **No GC** — `--gc=epsilon` means any allocation past 8 MB aborts the process. For our trivial CLI that's never triggered (peak ~1 MB), but it's a hard line: can't be used for any service that runs longer than one request, can't be used for code that does meaningful object churn.
- **No stack traces** — `-H:-IncludeMethodData` + `--strict-image-heap` + `--enable-monitoring=` strips most diagnostic affordances. Crashes show addresses, not Java method names.
- **UPX on native binaries is risky** — works on most Linux ELF, breaks on some Windows PE due to relocation tables. Build script applies UPX only on Linux. Final container ships from `FROM scratch`.
- **Build time ~3-6 min** — strictest type-flow analysis pushes GraalVM compile time up.

## Target size

| Stage | Size |
|-------|-----:|
| `2-amalgamate` (GraalVM + every safe flag) | ~10 MB |
| `3-best` after epsilon GC + max trim, before UPX | ~7 MB |
| `3-best` after UPX-LZMA on Linux | **~6 MB** |

## How to build

```powershell
./build.ps1                  # Local build
docker build -t app-java-kotlin-3-best .   # Container build (always Linux + UPX applied)
```

## Prerequisites

- GraalVM 21 with `native-image` on PATH
- Maven 3.9+
- UPX on PATH for Linux builds (https://upx.github.io/) — automatically installed in the Docker build
