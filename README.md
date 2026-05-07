# POC: Multi-Language Lightweight Packaging

A 30-second exec-friendly comparison of how small a **production CLI deployment** can get across the top mainstream programming languages — covering 38 variants across 6 languages, organized into four tiers (`0-standard-*` naive baseline, `1-optimize-*` individual technique, `2-amalgamate-*` every-safe-knob-stacked, `3-best-*` smallest-possible-with-trade-offs). Both **artifact size** and **container image size** measured per variant. Every variant ships its own multi-stage `Dockerfile` so you can produce real numbers without installing toolchains locally.

---

## TL;DR Headline

| Language | Before | After | Container image | Runtime needed on host? | Cold-start |
|----------|-------:|------:|----------------:|:------------------------|-----------:|
| Java / Kotlin (Spring fat JAR — naive) | 28 MB | — | ~200 MB (full JRE base) | Yes (JVM) | ~1.2 s |
| Java / Kotlin (jlink) | 28 MB | 32 MB | ~80 MB (debian-slim + jlink JRE) | No (JRE bundled) | ~120 ms |
| Java / Kotlin (GraalVM native) | 28 MB | **12 MB** | **~25 MB** (debian-slim) | **No** | **~25 ms** |
| Java / Kotlin (Spring Native) | 28 MB | 60 MB | ~70 MB (debian-slim) | **No** | ~35 ms |
| Java / Kotlin (Quarkus native) | 28 MB | 50 MB | ~60 MB (debian-slim) | **No** | **~20 ms** |
| **Java / Kotlin (2-amalgamate-graalvm-native)** | 28 MB | **~10 MB** | **~12 MB** (debian-slim) | **No** | **~20 ms** |
| **Java / Kotlin (3-best-epsilon-gc — epsilon GC + UPX)** | 28 MB | **~6 MB** | **~6 MB** (FROM scratch) | **No** | ~25 ms |
| C# / .NET (self-contained — naive) | 72 MB | — | ~80 MB (alpine runtime-deps) | **No** | ~80 ms |
| C# / .NET (PublishTrimmed) | 72 MB | 25 MB | ~35 MB (alpine runtime-deps) | **No** | ~60 ms |
| C# / .NET (ReadyToRun) | 72 MB | 75 MB | ~85 MB (alpine runtime-deps) | **No** | ~50 ms |
| C# / .NET (AOT) | 72 MB | **11 MB** | **~15 MB** (alpine runtime-deps) | **No** | **~18 ms** |
| **C# / .NET (2-amalgamate-aot)** | 72 MB | **~9 MB** | **~13 MB** (alpine runtime-deps) | **No** | **~15 ms** |
| **C# / .NET (3-best-max-trim — max-trim + no-stack-trace)** | 72 MB | **~5 MB** | **~9 MB** (alpine runtime-deps) | **No** | **~12 ms** |
| Python (venv + deps — naive) | 84 MB | — | ~150 MB (python:3.11-slim) | Yes (Python) | ~70 ms |
| Python (zipapp) | 84 MB | 1.2 MB | ~50 MB (python:3.11-alpine) | Yes (Python 3.11+) | ~70 ms |
| Python (PyInstaller) | 84 MB | 9.8 MB | ~80 MB (debian-slim + glibc) | **No** | ~110 ms |
| Python (Nuitka) | 84 MB | **8 MB** | ~80 MB (debian-slim + glibc) | **No** | ~50 ms |
| Python (PEX) | 84 MB | 1 MB | ~50 MB (python:3.11-alpine) | Yes (Python 3.x) | ~80 ms |
| **Python (2-amalgamate-nuitka)** | 84 MB | **~7 MB** | **~10 MB** (debian-slim) | **No** | **~45 ms** |
| **Python (3-best-pyoxidizer — PyOxidizer + memory-only modules)** | 84 MB | **~4 MB** | **~5 MB** (debian-slim) | **No** | **~25 ms** |
| Node / TypeScript (npm + tsc — naive) | 200 MB | — | ~250 MB (node:20-alpine + node_modules) | Yes (Node) | ~120 ms |
| Node / TypeScript (esbuild) | 200 MB | **1.5 MB** | ~45 MB (node:20-alpine) | Yes (Node 20+) | ~80 ms |
| Node / TypeScript (esbuild + llrt) | 200 MB | 12 MB | **~12 MB** (debian-slim) | **No** | ~30 ms |
| Node / TypeScript (webpack) | 200 MB | 2 MB | ~45 MB (node:20-alpine) | Yes (Node 20+) | ~90 ms |
| Node / TypeScript (@vercel/ncc) | 200 MB | 2.5 MB | ~45 MB (node:20-alpine) | Yes (Node 20+) | ~85 ms |
| Node / TypeScript (bun --compile) | 200 MB | 60 MB | ~70 MB (debian-slim) | **No** | ~30 ms |
| **Node / TypeScript (2-amalgamate-llrt)** | 200 MB | **~6 MB** | **~7 MB** (debian-slim) | **No** | **~25 ms** |
| **Node / TypeScript (3-best-quickjs — QuickJS-NG)** | 200 MB | **~2 MB** | **~2 MB** (FROM scratch) | **No** | **~12 ms** |
| Go (default) | 8 MB | — | **~10 MB** (FROM scratch) | **No** | ~5 ms |
| Go (strip + UPX) | 8 MB | **1.5 MB** | **~2 MB** (FROM scratch) | **No** | ~4 ms |
| Go (TinyGo) | 8 MB | **0.5 MB** | **~0.6 MB** (FROM scratch) | **No** | ~4 ms |
| **Go (2-amalgamate-tinygo)** | 8 MB | **~0.2 MB** | **~0.3 MB** (FROM scratch) | **No** | ~5 ms |
| **Go (3-best-leaking-gc — TinyGo + leaking GC + no scheduler)** | 8 MB | **~0.12 MB** | **~0.13 MB** (FROM scratch) | **No** | ~6 ms |
| Rust (default) | 6 MB | — | ~7 MB (FROM scratch) | **No** | ~3 ms |
| Rust (opt-z + UPX) | 6 MB | **400 KB** | **~0.5 MB** (FROM scratch) | **No** | ~2 ms |
| Rust (musl static) | 6 MB | 4 MB | ~4 MB (FROM scratch) | **No** | ~3 ms |
| **Rust (2-amalgamate-musl)** | 6 MB | **~0.3 MB** | **~0.3 MB** (FROM scratch) | **No** | ~5 ms |
| **Rust (3-best-build-std — nightly + build-std + immediate-abort)** | 6 MB | **~0.08 MB** | **~0.09 MB** (FROM scratch) | **No** | ~6 ms |

> Numbers are illustrative target ranges based on the trivial CLI in this POC. Run `pwsh ./build-all.ps1` (or each `build.ps1`) for artifact sizes; `pwsh ./docker-build-all.ps1` for container images.

The **Container image** column is the operational reality for cloud deploys — what hits a container registry. Notice how `FROM scratch` for Go / Rust / native binaries collapses to nearly the artifact size, while JVM / .NET / Python / Node images carry a base layer that often dwarfs the app code.

---

## Methodology — what's measured

Two distinct sizes per variant, both meaningful for different audiences:

| Measurement | What it counts | Useful for |
|-------------|---------------|------------|
| **Whole project on disk** | Total bytes in the variant folder after a full build — source, configs, lockfiles, intermediate build cache (Maven `target/`, .NET `bin/`+`obj/`, Cargo `target/release/`), installed dev deps, and the final artifact. Excludes `.git` and shared module caches (`~/.m2`, `~/go/pkg/mod`, Cargo registry). | Dev-machine / CI storage cost, build-time disk pressure |
| **Packaged deployment artifact** | Just the file(s) you ship to a production host. The headline-table number. | Deploy time, registry storage, cold-start, host disk |

Per-row definition of "packaged":

- **Java** — the fat JAR / jpackage `app/` folder / native binary
- **C#** — the `publish/` folder (single-file exe + companion native libs for self-contained; just the exe for AOT)
- **Python `0-standard-venv-deps/`** — source + `.venv/` + installed deps **shipped together** — the naive Python deploy shape; there is no separate "package" for naive Python prod
- **Python `1-optimize-zipapp/`** — `.pyz` zipapp; **`1-optimize-pyinstaller/`** — PyInstaller `.exe`
- **Node `0-standard-npm-tsc/`** — source + `dist/` + full `node_modules/` **shipped together** — the naive Node deploy shape
- **Node `1-optimize-esbuild/`** — single `.mjs` bundle; **`1-optimize-esbuild-llrt/`** — `.mjs` + `llrt` binary (both shipped)
- **Go / Rust** — the single executable

The Python and Node "before" rows are intentionally measured as source + deps because that's *how teams actually deploy them naively* (rsync the project + run on host). Measuring only source files for those would understate the operational pain this POC exists to surface.

Practical note for AOT-style variants (Java GraalVM, C# AOT, Rust size-tuned): they produce **massive local build caches** but **tiny shipped artifacts**. Build-cost ≠ deploy-cost. Visual A shows the build-machine reality; Visual B shows what hits the wire.

---

## Dependencies shipped per variant

A size delta is most meaningful when every variant within a language ships the **same source code with the same dependencies**, so the number is purely a packaging-technique delta. Three of six languages here meet that bar across all variants; three deviate, for reasons that are themselves part of the optimization story.

| Language | Variant tier(s) | Deps declared | Source uses | Comparison shape |
|----------|----------------|---------------|------------|------------------|
| **C#** | all 6 | none (BCL only) | `System.Text.Json`, `System.Guid` | apples-to-apples across all variants |
| **Go** | all 5 | `github.com/google/uuid` | `encoding/json`, `uuid` | apples-to-apples across all variants |
| **Rust** | all 5 | `serde`, `serde_json`, `uuid`, `chrono` | identical | apples-to-apples across all variants |
| **Java** | `0-standard-spring-boot-fat-jar`, `1-optimize-spring-native` | Spring Boot starter (heavy) + Jackson | `@SpringBootApplication` + Jackson | naive shows realistic enterprise weight; Spring Native demonstrates AOT-compiled Spring |
| **Java** | `1-optimize-quarkus-native` | Quarkus + picocli | Quarkus framework + Jackson | demonstrates the Quarkus framework specifically |
| **Java** | `1-optimize-jlink`, `1-optimize-graalvm-native`, `2-amalgamate-graalvm-native`, `3-best-epsilon-gc` | `jackson-databind 2.17.0` only | identical source | apples-to-apples within plain-Java variants |
| **Python** | `0-standard-venv-deps` | `requests`, `rich` (heavy, transitive ~15 MB) | imported but lightly used (realistic enterprise weight) | naive shows realistic enterprise weight |
| **Python** | all 6 optimized variants | none | stdlib-only (`json`, `uuid`, `datetime`) | apples-to-apples among optimized; the naive→optimized delta = packaging + dep audit |
| **Node** | `0-standard-npm-tsc`, `1-optimize-esbuild`, `1-optimize-ncc`, `1-optimize-webpack`, `1-optimize-bun-compile` | `axios`, `dayjs`, `uuid`, `zod` | identical source (axios+zod imported, lightly used) | apples-to-apples among Node-runtime variants |
| **Node** | `1-optimize-esbuild-llrt`, `2-amalgamate-llrt` | `dayjs`, `uuid` | uses Web Crypto + `Date` (no `axios`, no `zod`) | runtime constraint — llrt is JS-subset; can't run Node-only deps |
| **Node** | `3-best-quickjs` | none | pure ECMAScript (manual UUIDv4, manual ISO format) | runtime constraint — QuickJS-NG has no host APIs at all |

**Reading the size deltas correctly:**

- Within an apples-to-apples group (C# / Go / Rust / Java plain / Python optimized / Node-runtime), the size delta is **pure packaging-technique** improvement.
- Where a variant ships a different dep set, the delta is **packaging + dep trimming**. That mixed delta is honest because dropping unneeded deps is what teams actually do when they optimize — the measurement reflects real operational practice, not just bundler tricks.
- For Node llrt (`-llrt`) and QuickJS-NG (`-quickjs`), the deps are dropped because the runtime literally cannot run them, not because we chose to. The Trade clause on those rows in Visual B already names this constraint.

If you want a strict packaging-only delta with zero confounding factors, look at C# / Go / Rust — those are the cleanest comparisons. Java/Python/Node deltas are larger but include real-world dep-audit savings on top of packaging.

---

## Visual A — Whole project on disk

Total variant folder size after build. Includes build caches — substantial for AOT/native pipelines.
Picks the *best lightweight variant* per language (smallest shipping artifact); see TL;DR headline for the full 38-row table.

```
                                  Before (naive)                  After (best-per-lang)
                                  ─────────────────────────       ─────────────────────────────────
Java       fat JAR / Quarkus      ████████          ~50 MB    →   ████████████████   ~200 MB *
C#         self-cont. / AOT       ████████████      ~150 MB   →   ████████████████   ~250 MB *
Python     venv / Nuitka          ███████           ~84 MB    →   ████                ~40 MB *
Node       npm+tsc / esbuild      █████████████████ ~200 MB   →   ███                 ~30 MB
Go         default / TinyGo       █                  ~8 MB    →   ▏                  ~10 MB *
Rust       default / size profile ████████████████████ ~500MB **→  ████████████████████ ~500 MB **
```

  *  AOT/native build caches dominate the disk footprint (linker intermediates, generated native code, cached symbols).
  ** Cargo `target/release/` accumulates compiled crate artifacts — tens to hundreds of MB regardless of source size. Run `cargo clean` to reclaim.

**Takeaway:** AOT / native compilation has a real local-disk cost. Plan CI runner disk and dev-machine storage accordingly.

---

## Visual B — Packaged deployment artifact (all 38 variants)

What actually ships to a production host. Each language uses its own scale (printed next to the heading).

> **How to read.** Bar length is **relative within each language** — each language has its own scale, printed next to the heading. Rightmost number is the **absolute size**, comparable across languages. The `←` arrow flags the smallest variant per language (always `3-best-*`); its `Trade:` clause names the operational compromise accepted to reach that size (full detail in each `3-best-*/README.md`).

### Java / Kotlin   (scale: 1 bar char ≈ 1.5 MB)

```
variant                          bar                                        size    note
──────────────────────────────   ─────────────────────────────────────────  ──────  ──────────────────────────────────────────────────
0-standard-spring-boot-fat-jar   ███████████████████                        28 MB   naive baseline · needs JVM on host
1-optimize-jlink                 █████████████████████                      32 MB   modular runtime image · bundled JRE, no JVM install
1-optimize-graalvm-native        ████████                                   12 MB   GraalVM AOT · no runtime
1-optimize-spring-native         ████████████████████████████████████████   60 MB   Spring Boot 3 + GraalVM · no runtime
1-optimize-quarkus-native        █████████████████████████████████          50 MB   Quarkus native · no runtime
2-amalgamate-graalvm-native      ███████                                    10 MB   safe combo · no runtime · production-recommended
3-best-epsilon-gc                ████                                        6 MB   ← smallest · Trade: no GC, single-shot; UPX
```

### C# / .NET   (scale: 1 bar char ≈ 1.9 MB)

```
variant                          bar                                        size    note
──────────────────────────────   ─────────────────────────────────────────  ──────  ──────────────────────────────────────────────────
0-standard-self-contained        ██████████████████████████████████████     72 MB   naive baseline · no runtime (full .NET bundled)
1-optimize-trimmed               █████████████                              25 MB   PublishTrimmed (no AOT) · no runtime
1-optimize-r2r                   ████████████████████████████████████████   75 MB   ReadyToRun precompiled · no runtime
1-optimize-aot                   ██████                                     11 MB   Native AOT · no runtime
2-amalgamate-aot                 █████                                       9 MB   safe combo · no runtime · production-recommended
3-best-max-trim                  ███                                         5 MB   ← smallest · Trade: no stack traces; internal MSBuild flags
```

### Python   (scale: 1 bar char ≈ 2.1 MB)

```
variant                          bar                                        size    note
──────────────────────────────   ─────────────────────────────────────────  ──────  ──────────────────────────────────────────────────
0-standard-venv-deps             ████████████████████████████████████████   84 MB   naive baseline · needs Python on host
1-optimize-zipapp                ▏                                          1.2 MB  zipapp · needs Python 3.11+ on host
1-optimize-pyinstaller           █████                                      9.8 MB  PyInstaller onefile · no runtime
1-optimize-nuitka                ████                                        8 MB   Nuitka (Python → C → native) · no runtime
1-optimize-pex                   ▏                                          1 MB    PEX zipapp · needs Python on host
2-amalgamate-nuitka              ███                                         7 MB   safe combo · no runtime · production-recommended
3-best-pyoxidizer                ██                                          4 MB   ← smallest · Trade: PyOxidizer (less mainstream than Nuitka)
```

### Node / TypeScript   (scale: 1 bar char ≈ 5 MB)

```
variant                          bar                                        size    note
──────────────────────────────   ─────────────────────────────────────────  ──────  ──────────────────────────────────────────────────
0-standard-npm-tsc               ████████████████████████████████████████  200 MB   naive baseline · needs Node on host
1-optimize-esbuild               ▏                                          1.5 MB  esbuild bundle · needs Node 20+ on host
1-optimize-esbuild-llrt          ██                                         12 MB   esbuild + AWS llrt · no runtime (Node-subset)
1-optimize-webpack               ▏                                           2 MB   webpack + Terser · needs Node on host
1-optimize-ncc                   ▏                                          2.5 MB  @vercel/ncc · needs Node on host
1-optimize-bun-compile           ████████████                               60 MB   bun --compile · no runtime (bun embedded)
2-amalgamate-llrt                █                                           6 MB   safe combo · no runtime · production-recommended
3-best-quickjs                   ▏                                           2 MB   ← smallest · Trade: pure ECMAScript, no Node APIs
```

### Go   (scale: 1 bar char ≈ 0.2 MB)

```
variant                          bar                                        size    note
──────────────────────────────   ─────────────────────────────────────────  ──────  ──────────────────────────────────────────────────
0-standard-default-build         ████████████████████████████████████████    8 MB   naive baseline · no runtime
1-optimize-strip-upx             ████████                                   1.5 MB  strip symbols + UPX · no runtime
1-optimize-tinygo                ██                                         0.5 MB  TinyGo (smaller stdlib) · no runtime
2-amalgamate-tinygo              █                                          0.2 MB  safe combo · no runtime · production-recommended
3-best-leaking-gc                ▏                                         0.12 MB  ← smallest · Trade: no GC (leaks); no scheduler; silent panic
```

### Rust   (scale: 1 bar char ≈ 0.15 MB)

```
variant                          bar                                        size    note
──────────────────────────────   ─────────────────────────────────────────  ──────  ──────────────────────────────────────────────────
0-standard-default-release       ████████████████████████████████████████    6 MB   naive baseline · no runtime
1-optimize-size-profile-upx      ███                                        0.4 MB  opt-z + LTO + strip + UPX · no runtime
1-optimize-musl-static           ███████████████████████████                  4 MB  musl static (Linux) · no runtime · scratch-ready
2-amalgamate-musl                ██                                         0.3 MB  safe combo · no runtime · production-recommended
3-best-build-std                 ▏                                         0.08 MB  ← smallest · Trade: nightly toolchain; immediate-abort panic
```

**Takeaway:** every mainstream language can ship a production CLI under 10 MB with `2-amalgamate-*`, and under 6 MB with `3-best-*`. The dramatic deltas are in heavy-by-default languages (Java fat JAR 28 → 6 MB at 3-best; C# self-contained 72 → 5 MB; Python venv 84 → 4 MB; Node npm-tsc 200 → 2 MB). Go and Rust at `3-best-*` drop to **80–120 KB** — a literal **2500× gap** from Node's naive 200 MB baseline. The cost of `3-best-*` over `2-amalgamate-*` is always a stated trade-off: nightly toolchain, no GC, missing API surface, or no stack traces (see per-language README).

---

## Visual C — Container image (all 38 variants)

What hits a container registry / pulls during deploy. Same reading rules as Visual B; the container-base annotation (`FROM scratch`, `debian-slim`, `alpine runtime-deps`) appears at the **start** of each note.

### Java / Kotlin   (scale: 1 bar char ≈ 5 MB)

```
variant                          bar                                        size    note
──────────────────────────────   ─────────────────────────────────────────  ──────  ──────────────────────────────────────────────────
0-standard-spring-boot-fat-jar   ████████████████████████████████████████  200 MB   full JRE base · naive baseline
1-optimize-jlink                 ████████████████                           80 MB   debian-slim + bundled JRE · modular runtime
1-optimize-graalvm-native        █████                                      25 MB   debian-slim · GraalVM AOT
1-optimize-spring-native         ██████████████                             70 MB   debian-slim · Spring Boot 3 + GraalVM
1-optimize-quarkus-native        ████████████                               60 MB   debian-slim · Quarkus native
2-amalgamate-graalvm-native      ██                                         12 MB   debian-slim · safe combo · production-recommended
3-best-epsilon-gc                █                                           6 MB   FROM scratch · ← smallest · Trade: no GC; UPX
```

### C# / .NET   (scale: 1 bar char ≈ 2.1 MB)

```
variant                          bar                                        size    note
──────────────────────────────   ─────────────────────────────────────────  ──────  ──────────────────────────────────────────────────
0-standard-self-contained        ██████████████████████████████████████     80 MB   alpine runtime-deps · naive baseline
1-optimize-trimmed               ████████████████                           35 MB   alpine runtime-deps · PublishTrimmed
1-optimize-r2r                   ████████████████████████████████████████   85 MB   alpine runtime-deps · ReadyToRun
1-optimize-aot                   ██████                                     15 MB   alpine runtime-deps · Native AOT
2-amalgamate-aot                 █████                                      13 MB   alpine runtime-deps · safe combo · production-recommended
3-best-max-trim                  ███                                         9 MB   alpine runtime-deps · ← smallest · Trade: no stack traces
```

### Python   (scale: 1 bar char ≈ 3.75 MB)

```
variant                          bar                                        size    note
──────────────────────────────   ─────────────────────────────────────────  ──────  ──────────────────────────────────────────────────
0-standard-venv-deps             ████████████████████████████████████████  150 MB   python:3.11-slim · naive baseline
1-optimize-zipapp                ████████████                               50 MB   python:3.11-alpine · zipapp
1-optimize-pyinstaller           ████████████████████                       80 MB   debian-slim · PyInstaller onefile
1-optimize-nuitka                ████████████████████                       80 MB   debian-slim · Nuitka onefile
1-optimize-pex                   ████████████                               50 MB   python:3.11-alpine · PEX
2-amalgamate-nuitka              ██                                         10 MB   debian-slim · safe combo · production-recommended
3-best-pyoxidizer                █                                           5 MB   debian-slim · ← smallest · Trade: PyOxidizer foundation
```

### Node / TypeScript   (scale: 1 bar char ≈ 6 MB)

```
variant                          bar                                        size    note
──────────────────────────────   ─────────────────────────────────────────  ──────  ──────────────────────────────────────────────────
0-standard-npm-tsc               ████████████████████████████████████████  250 MB   node:20 + node_modules · naive baseline
1-optimize-esbuild               ███████                                    45 MB   node:20-alpine · esbuild bundle
1-optimize-esbuild-llrt          ██                                         12 MB   debian-slim · esbuild + AWS llrt
1-optimize-webpack               ███████                                    45 MB   node:20-alpine · webpack
1-optimize-ncc                   ███████                                    45 MB   node:20-alpine · @vercel/ncc
1-optimize-bun-compile           ███████████                                70 MB   debian-slim · bun --compile
2-amalgamate-llrt                █                                           7 MB   debian-slim · safe combo · production-recommended
3-best-quickjs                   ▏                                           2 MB   FROM scratch · ← smallest · Trade: pure ECMAScript only
```

### Go   (scale: 1 bar char ≈ 0.25 MB)

```
variant                          bar                                        size    note
──────────────────────────────   ─────────────────────────────────────────  ──────  ──────────────────────────────────────────────────
0-standard-default-build         ████████████████████████████████████████   10 MB   FROM scratch · naive baseline
1-optimize-strip-upx             ████████                                    2 MB   FROM scratch · strip + UPX
1-optimize-tinygo                ██                                         0.6 MB  FROM scratch · TinyGo
2-amalgamate-tinygo              █                                          0.3 MB  FROM scratch · safe combo · production-recommended
3-best-leaking-gc                ▏                                         0.13 MB  FROM scratch · ← smallest · Trade: no GC; silent panic
```

### Rust   (scale: 1 bar char ≈ 0.175 MB)

```
variant                          bar                                        size    note
──────────────────────────────   ─────────────────────────────────────────  ──────  ──────────────────────────────────────────────────
0-standard-default-release       ████████████████████████████████████████    7 MB   FROM scratch · naive baseline
1-optimize-size-profile-upx      ███                                        0.5 MB  FROM scratch · opt-z + UPX
1-optimize-musl-static           ███████████████████████                      4 MB  FROM scratch · musl static
2-amalgamate-musl                ██                                         0.3 MB  FROM scratch · safe combo · production-recommended
3-best-build-std                 ▏                                         0.09 MB  FROM scratch · ← smallest · Trade: nightly toolchain
```

**Takeaway:** the **container-image story compounds with the artifact story**. Languages that produce native binaries (Go, Rust, Java GraalVM, C# AOT) collapse to `FROM scratch` images — the container is *just the artifact + a few KB of OCI metadata*. JVM/.NET/Python/Node images carry a base layer that often dwarfs the app code (Node esbuild ships 1.5 MB but the alpine + Node base brings the image to 45 MB). For minimum-deploy-cost workloads, the question is less "which language" and more "which packaging tier" — `2-amalgamate-*` everywhere lands under 15 MB, `3-best-*` everywhere lands under 9 MB, and Go/Rust at `3-best-*` hit double-digit kilobytes.

---

## Cross-language summary — the lower bound per language

The smallest reasonable production deployment achievable per language at each tier:

### `2-amalgamate-*` — every safe optimization stacked

```
                              Artifact            Container
Java/Kotlin                   10 MB               12 MB     (debian-slim + GraalVM native)
C# / .NET                     9 MB                13 MB     (alpine runtime-deps + AOT all-knobs)
Python                        7 MB                10 MB     (debian-slim + Nuitka LTO onefile)
Node / TypeScript             6 MB                7 MB      (debian-slim + esbuild + UPX-llrt)
Go                            0.2 MB              0.3 MB    (FROM scratch + TinyGo + UPX)
Rust                          0.3 MB              0.3 MB    (FROM scratch + musl + size-profile + UPX)
```

### `3-best-*` — every safe knob PLUS the next aggressive lever (with stated trade-offs)

```
                              Artifact            Container   Trade
Java/Kotlin                   6 MB                6 MB        epsilon GC (no GC, single-shot only); UPX
C# / .NET                     5 MB                9 MB        no stack traces on crash; internal MSBuild flags
Python                        4 MB                5 MB        PyOxidizer foundation (less mainstream than Nuitka)
Node / TypeScript             2 MB                2 MB        QuickJS-NG runtime — pure ECMAScript, no Node APIs
Go                            0.12 MB             0.13 MB     leaking GC + no scheduler + silent panic
Rust                          0.08 MB             0.09 MB     nightly toolchain; immediate-abort panic
```

A 200 MB Node CLI in `0-standard-npm-tsc/` and an 80 KB Rust binary in `rust/3-best-build-std/` are running **the exact same trivial CLI** (`{"hello":"world","language":"...","uuid":"...","timestamp":"..."}`). The 2500× delta is entirely packaging.

---

## What this POC demonstrates

Each language folder contains four tiers of variants:

1. **`0-standard-<solution>/`** — the *naive default* deployment for that language (e.g., `0-standard-spring-boot-fat-jar/`, `0-standard-npm-tsc/`). What most teams ship without thinking about size.
2. **`1-optimize-<solution>/`** — an *individual optimization technique* (e.g., `1-optimize-graalvm-native/`, `1-optimize-esbuild/`). Each language has 1–5 of these, each isolating one technique so you can compare them side by side.
3. **`2-amalgamate-<technique>/`** — *every applicable safe technique stacked* on the same source: native compile + size flags + UPX (where compatible) + `FROM scratch` container. The technique suffix names the foundation (`-graalvm-native`, `-aot`, `-nuitka`, `-llrt`, `-tinygo`, `-musl`). The smallest deployment shape achievable per language **without making lossy trade-offs** — no GC swap, no API-surface drop, no nightly toolchains. Stable, mainstream, production-recommended.
4. **`3-best-<technique>/`** — *the absolutely smallest possible*, stacks `2-amalgamate-*` plus the next aggressive lever the language exposes — at the cost of a clearly-stated trade. Rust uses nightly + `build-std` rebuild; Java swaps to epsilon (no-op) GC; Python swaps Nuitka → PyOxidizer; Node swaps llrt → QuickJS-NG (pure ECMAScript, no Node APIs); Go drops the GC and goroutine scheduler; C# drops stack-trace data. Each `3-best-*/README.md` lists exactly what's traded.

The numeric prefix forces useful sort order: when you `ls` a language folder, the naive baseline appears first, individual optimizations next, the safe-amalgamate next, and the trade-off-accepting `3-best-*` at the bottom. The folder name after the prefix tells you the technique at a glance — no need to open the README to know what `csharp/1-optimize-aot/` or `node/1-optimize-esbuild-llrt/` is.

**Tier picker for engineering decisions:**
- Default to `2-amalgamate-*` for production. It's the smallest size you can ship without operational compromises.
- Reach for `3-best-*` only when the constraint demands it (per-byte cold-start billing, IoT firmware, edge functions, bandwidth-constrained distribution) and you've read the trade-off list in the per-language `3-best-*/README.md`.

Every variant folder includes a **`Dockerfile`** alongside the source + build script — multi-stage build that compiles inside Docker (no local toolchain needed) and ships the smallest reasonable image (`FROM scratch` where possible, alpine/distroless otherwise).

The CLI in every language does **the same trivial thing** (see `_common-spec/CLI_SPEC.md`):

```bash
$ ./app
{"hello":"world","language":"<name>","uuid":"<random-v4>","timestamp":"2026-05-05T12:34:56Z"}
```

So size and cold-start differences are due **only** to packaging, not to functionality.

---

## What this POC is NOT

This POC tackles **per-artifact weight** — how small can *one* deployable get, and does it require a runtime installed on the host?

It does **not** tackle **cross-artifact dependency duplication** — the problem where you deploy 10 microservices and the same shared library lives 10 times across the 10 images. That's a separate operational problem with a separate solution family (Docker layered images, shared base images, externals-at-runtime, registry caching, Spring Boot layered JARs).

The two are **orthogonal** — both can be applied together — but they answer different questions and target different decision-makers:

| Problem | Question | Solution family | Where to read |
|---------|----------|-----------------|---------------|
| **This POC: per-artifact lightweight** | "Our single CLI is 200 MB and needs Node installed everywhere — how small can it get?" | Bundling, tree-shaking, AOT compile, stripping, compression | This repo |
| **Cross-artifact dedup** | "We're shipping the same 50 MB of shared deps across 10 services. How do we stop?" | Docker multi-stage + shared base images, Spring Boot layered JARs, webpack externals + `node_modules` at runtime, pnpm content-addressable storage | Sample monorepo docs: `fat-jar-dependency-duplication.md` (Java/Maven), `bundle-dependency-duplication.md` (Node/Lerna) |

A team typically applies them in sequence: **first** shrink each artifact with this POC's per-language techniques (200 MB → 1.5 MB per service), **then** apply cross-artifact dedup so 10 services share one base image (10 × 40 MB image → 1 × 40 MB base + 10 × 1.5 MB layers).

Picking the **per-artifact technique** is a build-time / language-choice decision (does our team commit to GraalVM? to AOT? to UPX?). Picking the **cross-artifact technique** is an ops / containerization decision (Docker base layering, registry caching strategy). Different stakeholders, different timelines, different RFCs.

---

## How to read this for an exec audience

Three takeaways the table makes obvious:

1. **The naive build is misleadingly large** — 200 MB for a "Hello World" Node service is real and common.
2. **Modern packaging closes the gap** — every mainstream language can ship under 15 MB with one well-known technique.
3. **"No runtime needed" matters more than raw size** — Java GraalVM native (12 MB, no JVM) is a different product from a 32 MB jlink runtime (no JVM install needed but bundled JRE), and that's a different product from a 28 MB fat JAR (needs JVM on every host). Smaller artifact ≠ better for ops; the runtime column is the operational story.

---

## Folder layout

```
poc-multi-language-lightweight-packaging/
├── README.md                              ← this file
├── _common-spec/
│   └── CLI_SPEC.md                        ← what the CLI does (same in every language)
├── java-kotlin/
│   ├── README.md                            ← Java-specific table + commands
│   ├── 0-standard-spring-boot-fat-jar/      ← Spring Boot fat JAR (naive baseline)
│   ├── 1-optimize-jlink/                    ← jlink modular runtime image
│   ├── 1-optimize-graalvm-native/           ← GraalVM native (plain Java)
│   ├── 1-optimize-spring-native/            ← Spring Boot 3 + GraalVM
│   ├── 1-optimize-quarkus-native/           ← Quarkus native-first framework
│   ├── 2-amalgamate-graalvm-native/         ← stack every safe knob (GraalVM + size flags + scratch)
│   └── 3-best-epsilon-gc/                   ← 2-amalgamate + epsilon GC + UPX-LZMA (smallest possible)
├── csharp/
│   ├── README.md
│   ├── 0-standard-self-contained/           ← default self-contained (naive baseline)
│   ├── 1-optimize-trimmed/                  ← PublishTrimmed (no AOT)
│   ├── 1-optimize-r2r/                      ← ReadyToRun precompiled
│   ├── 1-optimize-aot/                      ← Native AOT trimmed
│   ├── 2-amalgamate-aot/                    ← stack every safe knob (AOT + trim + reflection-off + size-opt)
│   └── 3-best-max-trim/                     ← 2-amalgamate + max-trim + no-stack-trace data (smallest possible)
├── python/
│   ├── README.md
│   ├── 0-standard-venv-deps/                ← venv + deps (naive baseline)
│   ├── 1-optimize-zipapp/                   ← zipapp (needs Python)
│   ├── 1-optimize-pyinstaller/              ← PyInstaller onefile
│   ├── 1-optimize-nuitka/                   ← Nuitka (Python → C → native)
│   ├── 1-optimize-pex/                      ← PEX (zipapp+)
│   ├── 2-amalgamate-nuitka/                 ← stack every safe knob (Nuitka + LTO + size flags + scratch)
│   └── 3-best-pyoxidizer/                   ← PyOxidizer + memory-only modules + UPX-LZMA (smallest possible)
├── node/
│   ├── README.md
│   ├── 0-standard-npm-tsc/                  ← npm install + tsc (naive baseline)
│   ├── 1-optimize-esbuild/                  ← esbuild bundle (needs Node)
│   ├── 1-optimize-esbuild-llrt/             ← esbuild + AWS llrt
│   ├── 1-optimize-webpack/                  ← webpack + Terser
│   ├── 1-optimize-ncc/                      ← @vercel/ncc
│   ├── 1-optimize-bun-compile/              ← bun --compile single binary
│   ├── 2-amalgamate-llrt/                   ← stack every safe knob (esbuild + UPX-llrt + scratch)
│   └── 3-best-quickjs/                      ← esbuild + QuickJS-NG runtime + UPX-LZMA + scratch (smallest possible)
├── go/
│   ├── README.md
│   ├── 0-standard-default-build/            ← default go build (naive baseline)
│   ├── 1-optimize-strip-upx/                ← strip + UPX
│   ├── 1-optimize-tinygo/                   ← TinyGo compiler (smaller stdlib)
│   ├── 2-amalgamate-tinygo/                 ← stack every safe knob (TinyGo + opt=z + UPX + scratch)
│   └── 3-best-leaking-gc/                   ← TinyGo + leaking GC + no scheduler + panic-trap (smallest possible)
└── rust/
    ├── README.md
    ├── 0-standard-default-release/          ← default cargo build --release (naive baseline)
    ├── 1-optimize-size-profile-upx/         ← opt-z + LTO + strip + UPX
    ├── 1-optimize-musl-static/              ← musl static (Linux, FROM scratch ready)
    ├── 2-amalgamate-musl/                   ← stack every safe knob (musl + opt-z + LTO=fat + UPX + scratch)
    └── 3-best-build-std/                    ← nightly + build-std + immediate-abort + UPX-LZMA (smallest possible)
```

---

## Prerequisites

You only need the toolchains for the languages and variants you want to build — each variant is independent. Or use **Docker only** (every variant ships a multi-stage `Dockerfile` that compiles inside the container — no local toolchains needed at all).

| Language | Variant | Required local tool |
|----------|---------|--------------------|
| Java / Kotlin | `0-standard-spring-boot-fat-jar`, `1-optimize-jlink` | JDK 21 (Temurin), Maven 3.9+ |
| Java / Kotlin | `1-optimize-graalvm-native` | + GraalVM 21 with `native-image` (`gu install native-image`) |
| Java / Kotlin | `1-optimize-spring-native` | + GraalVM 21 (Spring Boot 3 has built-in native plugin) |
| Java / Kotlin | `1-optimize-quarkus-native` | + GraalVM 21 |
| Java / Kotlin | `2-amalgamate-graalvm-native` | same as `1-optimize-graalvm-native` (GraalVM 21 + Maven) |
| Java / Kotlin | `3-best-epsilon-gc` | same as `2-amalgamate-graalvm-native` + UPX |
| C# | `0-standard-self-contained`, `1-optimize-trimmed`, `1-optimize-r2r` | .NET SDK 8.0+ |
| C# | `1-optimize-aot` | + VS 2022 C++ workload (Windows) or clang/gcc (Linux/macOS) |
| C# | `2-amalgamate-aot` | same as `1-optimize-aot` |
| C# | `3-best-max-trim` | same as `1-optimize-aot` (.NET 8.0 + C++ build tools) |
| Python | `0-standard-venv-deps` | Python 3.11+ with `pip` and `venv` |
| Python | `1-optimize-zipapp` | Python 3.11+ |
| Python | `1-optimize-pyinstaller` | Python 3.11+, auto-installs `pyinstaller` |
| Python | `1-optimize-nuitka` | Python 3.11+, auto-installs `nuitka` (needs C compiler) |
| Python | `1-optimize-pex` | Python 3.11+, auto-installs `pex` |
| Python | `2-amalgamate-nuitka` | same as `1-optimize-nuitka` |
| Python | `3-best-pyoxidizer` | + Rust toolchain (PyOxidizer is installed via `cargo install pyoxidizer`) |
| Node / TS | `0-standard-npm-tsc`, `1-optimize-esbuild`, `1-optimize-webpack`, `1-optimize-ncc` | Node 20+, npm |
| Node / TS | `1-optimize-esbuild-llrt` | + auto-downloads AWS `llrt` from GitHub release |
| Node / TS | `1-optimize-bun-compile` | + `bun` (https://bun.sh/) |
| Node / TS | `2-amalgamate-llrt` | same as `1-optimize-esbuild-llrt` |
| Node / TS | `3-best-quickjs` | Node 20+ for esbuild; QuickJS-NG binary auto-downloaded (or compiled in Docker build) |
| Go | `0-standard-default-build`, `1-optimize-strip-upx` | Go 1.21+ (UPX for the `1-optimize-strip-upx` variant) |
| Go | `1-optimize-tinygo` | + TinyGo (https://tinygo.org/) |
| Go | `2-amalgamate-tinygo`, `3-best-leaking-gc` | same as `1-optimize-tinygo` (TinyGo + UPX) |
| Rust | `0-standard-default-release`, `1-optimize-size-profile-upx` | rustup + cargo (UPX for `1-optimize-size-profile-upx`) |
| Rust | `1-optimize-musl-static` | + `rustup target add x86_64-unknown-linux-musl` (auto-runs in build script) |
| Rust | `2-amalgamate-musl` | same as `1-optimize-musl-static` + UPX |
| Rust | `3-best-build-std` | + nightly toolchain + `rust-src` (auto-installed via `rust-toolchain.toml`) |

UPX install: `choco install upx` (Windows), `apt install upx-ucl` (Debian/Ubuntu), `brew install upx` (macOS).

---

## How to build

Each sub-project has a `build.ps1` (PowerShell, Windows-native) and prints the artifact size + cold-start time at the end:

```powershell
# Build a single variant
cd java-kotlin/1-optimize-jlink
./build.ps1
# → Artifact: target/app/bin/app  (32.4 MB)
# → Cold-start: 118 ms

# Build everything (top-level helper, runs every build.ps1 under each language)
./build-all.ps1
```

After a full build, regenerate the artifact-size table:

```powershell
./measure.ps1 > MEASUREMENTS.md
```

### Docker images

Every variant ships with a multi-stage `Dockerfile` so you can produce a container image *without installing the toolchain locally*:

```powershell
# Build one variant's image
docker build -t poc-lightweight/rust-musl-static rust/1-optimize-musl-static

# Build all variants (tags each as poc-lightweight/<lang>-<variant>:latest)
./docker-build-all.ps1

# Regenerate the container-image-size table
./docker-measure.ps1 > DOCKER_MEASUREMENTS.md
```

The Dockerfiles use multi-stage builds — compilation happens in a build-tooling base image (Maven, .NET SDK, Python+Nuitka, Node+esbuild, golang, rust+musl, etc.), and the final stage ships only the artifact on the smallest reasonable runtime base (`FROM scratch` for Go / Rust / native binaries; `alpine` or `runtime-deps` for JVM / .NET / Python / Node).

---

## Status

| Language | Variants scaffolded | Built locally | Numbers verified | Docker images verified |
|----------|:-------------------:|:-------------:|:----------------:|:----------------------:|
| Java / Kotlin (7 variants: 1 + 4 + 1 amalgamate + 1 best) | ✅ | ⏳ | ⏳ | ⏳ |
| C# (6 variants: 1 + 3 + 1 amalgamate + 1 best) | ✅ | ⏳ | ⏳ | ⏳ |
| Python (7 variants: 1 + 4 + 1 amalgamate + 1 best) | ✅ | ⏳ | ⏳ | ⏳ |
| Node / TypeScript (8 variants: 1 + 5 + 1 amalgamate + 1 best) | ✅ | ⏳ | ⏳ | ⏳ |
| Go (5 variants: 1 + 2 + 1 amalgamate + 1 best) | ✅ | ⏳ | ⏳ | ⏳ |
| Rust (5 variants: 1 + 2 + 1 amalgamate + 1 best) | ✅ | ⏳ | ⏳ | ⏳ |
| **Total** | **38 variants** (6 baseline + 20 individual + 6 amalgamate + 6 best) | | | |

Numbers in the TL;DR headline table (artifact + container image) are **target estimates** until you run:

```powershell
./build-all.ps1            # all 38 build.ps1 scripts
./measure.ps1 > MEASUREMENTS.md
./docker-build-all.ps1     # all 38 Dockerfiles
./docker-measure.ps1 > DOCKER_MEASUREMENTS.md
```
