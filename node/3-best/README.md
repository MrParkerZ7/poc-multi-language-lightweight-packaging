# Node / TypeScript — 3-best (smallest possible)

Switches the JS runtime from AWS llrt (~10 MB Rust-based subset) to **QuickJS-NG** (~1 MB pure-ECMAScript engine), then UPX-LZMA-compresses it.

## What's stacked on top of 2-amalgamate

The runtime itself is different here — `2-amalgamate` ships AWS llrt; `3-best` ships QuickJS-NG, a fork of Fabrice Bellard's QuickJS maintained by the open-source community.

| Lever | Effect |
|-------|--------|
| **QuickJS-NG** instead of llrt | ~1 MB binary vs. ~10 MB. Pure ECMAScript engine — full ES2023, no Node APIs. |
| esbuild `--platform=neutral` instead of `=node` | Tells esbuild not to assume Node built-ins are available; pure ECMAScript output. |
| esbuild `--target=es2023` | Latest ES features that QuickJS-NG supports (top-level await, error cause, etc.) — no down-leveling overhead. |
| Source rewritten to avoid `crypto.randomUUID()` etc. | QuickJS-NG doesn't ship Web Crypto. Uses `Math.random`-based UUIDv4 (not crypto-safe — see trade-offs). |
| Source rewritten to avoid `Date.toISOString` reliance | Manual `getUTCFullYear/Month/Date/Hours/...` formatting. |
| `cmake -DCMAKE_BUILD_TYPE=MinSizeRel` for QuickJS build | Build QuickJS itself in size-optimized mode. |
| `strip` + `upx --best --lzma` on the `qjs` binary | Final compression. |

## Trade-offs

- **No Node API surface** — `node:fs`, `node:http`, `node:crypto`, `node:path`, `node:os`, `process.env`, `Buffer`, the entire AWS SDK, etc. won't work. QuickJS-NG implements pure ECMAScript only. For our trivial CLI that's fine; for a real microservice you'd need to verify every import is portable.
- **`Math.random` UUID is not cryptographically secure** — the source includes a manual UUIDv4 generator using `Math.random`. Real apps using QuickJS-NG should bind a native crypto-RNG via QJS C-API or use a deterministic ID scheme.
- **No `console.log` lifecycle hooks** — QuickJS-NG is much more minimal than Node; observability (OpenTelemetry, tracing libs that hook stdout) won't work out of the box.
- **Smaller AND faster cold-start than llrt** — QuickJS-NG cold-starts in ~10-15 ms vs. llrt's ~30 ms.

## Target size

| Stage | Size |
|-------|-----:|
| `2-amalgamate` (esbuild + UPX-llrt + scratch) | ~6 MB |
| `3-best`: bundle + QuickJS-NG MinSizeRel build | ~3 MB before UPX |
| `3-best`: + UPX-LZMA on `qjs` | **~2 MB** |

(Bundle stays ~3-5 KB; the win is on the runtime side.)

## How to build

```powershell
./build.ps1                  # Local build (downloads QuickJS-NG release binary)
docker build -t app-node-3-best .   # Container build (compiles QuickJS-NG from source for guaranteed reproducibility)
```

## Prerequisites

- Node 20+ and npm (for esbuild during build)
- UPX on PATH (https://upx.github.io/)
- For local Windows build: prebuilt QuickJS-NG release (auto-downloaded). For reproducible builds, prefer the Docker path.
