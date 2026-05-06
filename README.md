# POC: Multi-Language Lightweight Packaging

A 30-second exec-friendly comparison of how small a **production CLI deployment** can get across the top mainstream programming languages — covering 32 variants across 6 languages, organized into three tiers (`0-before-*` naive baseline, `1-after-*` individual technique, `2-amalgamate` every-knob-stacked). Both **artifact size** and **container image size** measured per variant. Every variant ships its own multi-stage `Dockerfile` so you can produce real numbers without installing toolchains locally.

---

## TL;DR Headline

| Language | Before | After | Container image | Runtime needed on host? | Cold-start |
|----------|-------:|------:|----------------:|:------------------------|-----------:|
| Java / Kotlin (Spring fat JAR — naive) | 28 MB | — | ~200 MB (full JRE base) | Yes (JVM) | ~1.2 s |
| Java / Kotlin (jlink) | 28 MB | 32 MB | ~80 MB (debian-slim + jlink JRE) | No (JRE bundled) | ~120 ms |
| Java / Kotlin (GraalVM native) | 28 MB | **12 MB** | **~25 MB** (debian-slim) | **No** | **~25 ms** |
| Java / Kotlin (Spring Native) | 28 MB | 60 MB | ~70 MB (debian-slim) | **No** | ~35 ms |
| Java / Kotlin (Quarkus native) | 28 MB | 50 MB | ~60 MB (debian-slim) | **No** | **~20 ms** |
| **Java / Kotlin (2-amalgamate)** | 28 MB | **~10 MB** | **~12 MB** (debian-slim) | **No** | **~20 ms** |
| C# / .NET (self-contained — naive) | 72 MB | — | ~80 MB (alpine runtime-deps) | **No** | ~80 ms |
| C# / .NET (PublishTrimmed) | 72 MB | 25 MB | ~35 MB (alpine runtime-deps) | **No** | ~60 ms |
| C# / .NET (ReadyToRun) | 72 MB | 75 MB | ~85 MB (alpine runtime-deps) | **No** | ~50 ms |
| C# / .NET (AOT) | 72 MB | **11 MB** | **~15 MB** (alpine runtime-deps) | **No** | **~18 ms** |
| **C# / .NET (2-amalgamate)** | 72 MB | **~9 MB** | **~13 MB** (alpine runtime-deps) | **No** | **~15 ms** |
| Python (venv + deps — naive) | 84 MB | — | ~150 MB (python:3.11-slim) | Yes (Python) | ~70 ms |
| Python (zipapp) | 84 MB | 1.2 MB | ~50 MB (python:3.11-alpine) | Yes (Python 3.11+) | ~70 ms |
| Python (PyInstaller) | 84 MB | 9.8 MB | ~80 MB (debian-slim + glibc) | **No** | ~110 ms |
| Python (Nuitka) | 84 MB | **8 MB** | ~80 MB (debian-slim + glibc) | **No** | ~50 ms |
| Python (PEX) | 84 MB | 1 MB | ~50 MB (python:3.11-alpine) | Yes (Python 3.x) | ~80 ms |
| **Python (2-amalgamate)** | 84 MB | **~7 MB** | **~10 MB** (debian-slim) | **No** | **~45 ms** |
| Node / TypeScript (npm + tsc — naive) | 200 MB | — | ~250 MB (node:20-alpine + node_modules) | Yes (Node) | ~120 ms |
| Node / TypeScript (esbuild) | 200 MB | **1.5 MB** | ~45 MB (node:20-alpine) | Yes (Node 20+) | ~80 ms |
| Node / TypeScript (esbuild + llrt) | 200 MB | 12 MB | **~12 MB** (debian-slim) | **No** | ~30 ms |
| Node / TypeScript (webpack) | 200 MB | 2 MB | ~45 MB (node:20-alpine) | Yes (Node 20+) | ~90 ms |
| Node / TypeScript (@vercel/ncc) | 200 MB | 2.5 MB | ~45 MB (node:20-alpine) | Yes (Node 20+) | ~85 ms |
| Node / TypeScript (bun --compile) | 200 MB | 60 MB | ~70 MB (debian-slim) | **No** | ~30 ms |
| **Node / TypeScript (2-amalgamate)** | 200 MB | **~6 MB** | **~7 MB** (debian-slim) | **No** | **~25 ms** |
| Go (default) | 8 MB | — | **~10 MB** (FROM scratch) | **No** | ~5 ms |
| Go (strip + UPX) | 8 MB | **1.5 MB** | **~2 MB** (FROM scratch) | **No** | ~4 ms |
| Go (TinyGo) | 8 MB | **0.5 MB** | **~0.6 MB** (FROM scratch) | **No** | ~4 ms |
| **Go (2-amalgamate)** | 8 MB | **~0.2 MB** | **~0.3 MB** (FROM scratch) | **No** | ~5 ms |
| Rust (default) | 6 MB | — | ~7 MB (FROM scratch) | **No** | ~3 ms |
| Rust (opt-z + UPX) | 6 MB | **400 KB** | **~0.5 MB** (FROM scratch) | **No** | ~2 ms |
| Rust (musl static) | 6 MB | 4 MB | ~4 MB (FROM scratch) | **No** | ~3 ms |
| **Rust (2-amalgamate)** | 6 MB | **~0.3 MB** | **~0.3 MB** (FROM scratch) | **No** | ~5 ms |

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
- **Python `0-before-venv-deps/`** — source + `.venv/` + installed deps **shipped together** — the naive Python deploy shape; there is no separate "package" for naive Python prod
- **Python `1-after-zipapp/`** — `.pyz` zipapp; **`1-after-pyinstaller/`** — PyInstaller `.exe`
- **Node `0-before-npm-tsc/`** — source + `dist/` + full `node_modules/` **shipped together** — the naive Node deploy shape
- **Node `1-after-esbuild/`** — single `.mjs` bundle; **`1-after-esbuild-llrt/`** — `.mjs` + `llrt` binary (both shipped)
- **Go / Rust** — the single executable

The Python and Node "before" rows are intentionally measured as source + deps because that's *how teams actually deploy them naively* (rsync the project + run on host). Measuring only source files for those would understate the operational pain this POC exists to surface.

Practical note for AOT-style variants (Java GraalVM, C# AOT, Rust size-tuned): they produce **massive local build caches** but **tiny shipped artifacts**. Build-cost ≠ deploy-cost. Visual A shows the build-machine reality; Visual B shows what hits the wire.

---

## Visual A — Whole project on disk

Total variant folder size after build. Includes build caches — substantial for AOT/native pipelines.
Picks the *best lightweight variant* per language (smallest shipping artifact); see TL;DR headline for the full 32-row table.

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

## Visual B — Packaged deployment artifact

What actually ships to a production host. Picks the *smallest viable* variant per language; see TL;DR headline for the full 32-row table including alternatives (jlink, Spring Native, Quarkus, R2R, Nuitka, PEX, webpack, ncc, bun-compile, musl-static, plus 2-amalgamate which stacks every safe knob per language).

```
                                  Before                          After (best-per-lang)
                                  ─────────────────────────       ─────────────────────────────────
Java                              ████████████        28 MB    →  █████              12 MB  (GraalVM native)
C#                                ████████████████████ 72 MB   →  █████              11 MB  (AOT)
Python                            ████████████████    84 MB    →  ████               8 MB   (Nuitka)
Node/TS                           ████████████████████ 200 MB  →  █                  1.5 MB (esbuild bundle)
Go                                ██                   8 MB    →  ▏                  0.5 MB (TinyGo)
Rust                              █                    6 MB    →  ▏                  0.4 MB (opt-z + UPX)
```

```
                                  Container image (Dockerfile per variant)
                                  ───────────────────────────────────────────────────
Java       Spring fat JAR         ████████████████████ ~200 MB
Java       GraalVM native         ███             ~25 MB     (debian-slim)
C#         AOT                    ██              ~15 MB     (alpine runtime-deps)
Python     PyInstaller            ██████████      ~80 MB     (debian-slim)
Node       esbuild + llrt         ██               ~12 MB    (debian-slim)
Go         TinyGo                 ▏                ~0.6 MB   (FROM scratch)
Rust       musl static            ▏                ~4 MB     (FROM scratch)
Rust       opt-z + UPX            ▏                ~0.5 MB   (FROM scratch)
```

**Takeaway:** every mainstream language can ship a production CLI under 15 MB. The most dramatic deltas are in the heavy-by-default languages (Java, C#, Python, Node) where naive deploy is 25 MB–200 MB and optimized deploy is 1–12 MB. **Native binaries on `FROM scratch` collapse the container image to almost the artifact size**, which is why Go and Rust dominate the container-image column.

---

## What this POC demonstrates

Each language folder contains three tiers of variants:

1. **`0-before-<solution>/`** — the *naive default* deployment for that language (e.g., `0-before-spring-boot-fat-jar/`, `0-before-npm-tsc/`). What most teams ship without thinking about size.
2. **`1-after-<solution>/`** — an *individual optimization technique* (e.g., `1-after-graalvm-native/`, `1-after-esbuild/`). Each language has 1–5 of these, each isolating one technique so you can compare them side by side.
3. **`2-amalgamate/`** — *every applicable technique stacked* on the same source: native compile + size flags + UPX (where compatible) + `FROM scratch` container. The smallest reasonable deployment shape achievable per language, all knobs in the same direction.

The numeric prefix forces useful sort order: when you `ls` a language folder, the naive baseline appears first, individual optimizations next, and the amalgamated "everything stacked" at the bottom. The folder name after the prefix tells you the technique at a glance — no need to open the README to know what `csharp/1-after-aot/` or `node/1-after-esbuild-llrt/` is.

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
│   ├── 0-before-spring-boot-fat-jar/        ← Spring Boot fat JAR (naive baseline)
│   ├── 1-after-jlink/                       ← jlink modular runtime image
│   ├── 1-after-graalvm-native/              ← GraalVM native (plain Java)
│   ├── 1-after-spring-native/               ← Spring Boot 3 + GraalVM
│   ├── 1-after-quarkus-native/              ← Quarkus native-first framework
│   └── 2-amalgamate/                        ← stack every safe knob (GraalVM + size flags + scratch)
├── csharp/
│   ├── README.md
│   ├── 0-before-self-contained/             ← default self-contained (naive baseline)
│   ├── 1-after-trimmed/                     ← PublishTrimmed (no AOT)
│   ├── 1-after-r2r/                         ← ReadyToRun precompiled
│   ├── 1-after-aot/                         ← Native AOT trimmed
│   └── 2-amalgamate/                        ← stack every safe knob (AOT + trim + reflection-off + size-opt)
├── python/
│   ├── README.md
│   ├── 0-before-venv-deps/                  ← venv + deps (naive baseline)
│   ├── 1-after-zipapp/                      ← zipapp (needs Python)
│   ├── 1-after-pyinstaller/                 ← PyInstaller onefile
│   ├── 1-after-nuitka/                      ← Nuitka (Python → C → native)
│   ├── 1-after-pex/                         ← PEX (zipapp+)
│   └── 2-amalgamate/                        ← stack every safe knob (Nuitka + LTO + size flags + scratch)
├── node/
│   ├── README.md
│   ├── 0-before-npm-tsc/                    ← npm install + tsc (naive baseline)
│   ├── 1-after-esbuild/                     ← esbuild bundle (needs Node)
│   ├── 1-after-esbuild-llrt/                ← esbuild + AWS llrt
│   ├── 1-after-webpack/                     ← webpack + Terser
│   ├── 1-after-ncc/                         ← @vercel/ncc
│   ├── 1-after-bun-compile/                 ← bun --compile single binary
│   └── 2-amalgamate/                        ← stack every safe knob (esbuild + UPX-llrt + scratch)
├── go/
│   ├── README.md
│   ├── 0-before-default-build/              ← default go build (naive baseline)
│   ├── 1-after-strip-upx/                   ← strip + UPX
│   ├── 1-after-tinygo/                      ← TinyGo compiler (smaller stdlib)
│   └── 2-amalgamate/                        ← stack every safe knob (TinyGo + opt=z + UPX + scratch)
└── rust/
    ├── README.md
    ├── 0-before-default-release/            ← default cargo build --release (naive baseline)
    ├── 1-after-size-profile-upx/            ← opt-z + LTO + strip + UPX
    ├── 1-after-musl-static/                 ← musl static (Linux, FROM scratch ready)
    └── 2-amalgamate/                        ← stack every safe knob (musl + opt-z + LTO=fat + UPX + scratch)
```

---

## Prerequisites

You only need the toolchains for the languages and variants you want to build — each variant is independent. Or use **Docker only** (every variant ships a multi-stage `Dockerfile` that compiles inside the container — no local toolchains needed at all).

| Language | Variant | Required local tool |
|----------|---------|--------------------|
| Java / Kotlin | `0-before-spring-boot-fat-jar`, `after-jlink` | JDK 21 (Temurin), Maven 3.9+ |
| Java / Kotlin | `1-after-graalvm-native` | + GraalVM 21 with `native-image` (`gu install native-image`) |
| Java / Kotlin | `1-after-spring-native` | + GraalVM 21 (Spring Boot 3 has built-in native plugin) |
| Java / Kotlin | `1-after-quarkus-native` | + GraalVM 21 |
| C# | `0-before-self-contained`, `1-after-trimmed`, `1-after-r2r` | .NET SDK 8.0+ |
| C# | `1-after-aot` | + VS 2022 C++ workload (Windows) or clang/gcc (Linux/macOS) |
| Python | `0-before-venv-deps` | Python 3.11+ with `pip` and `venv` |
| Python | `1-after-zipapp` | Python 3.11+ |
| Python | `1-after-pyinstaller` | Python 3.11+, auto-installs `pyinstaller` |
| Python | `1-after-nuitka` | Python 3.11+, auto-installs `nuitka` (needs C compiler) |
| Python | `1-after-pex` | Python 3.11+, auto-installs `pex` |
| Node / TS | `0-before-npm-tsc`, `1-after-esbuild`, `1-after-webpack`, `1-after-ncc` | Node 20+, npm |
| Node / TS | `1-after-esbuild-llrt` | + auto-downloads AWS `llrt` from GitHub release |
| Node / TS | `1-after-bun-compile` | + `bun` (https://bun.sh/) |
| Go | `0-before-default-build`, `1-after-strip-upx` | Go 1.21+ (UPX for the `1-after-strip-upx` variant) |
| Go | `1-after-tinygo` | + TinyGo (https://tinygo.org/) |
| Rust | `0-before-default-release`, `1-after-size-profile-upx` | rustup + cargo (UPX for `1-after-size-profile-upx`) |
| Rust | `1-after-musl-static` | + `rustup target add x86_64-unknown-linux-musl` (auto-runs in build script) |

UPX install: `choco install upx` (Windows), `apt install upx-ucl` (Debian/Ubuntu), `brew install upx` (macOS).

---

## How to build

Each sub-project has a `build.ps1` (PowerShell, Windows-native) and prints the artifact size + cold-start time at the end:

```powershell
# Build a single variant
cd java-kotlin/after-jlink
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
docker build -t poc-lightweight/rust-musl-static rust/1-after-musl-static

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
| Java / Kotlin (6 variants: 1 + 4 + 1 amalgamate) | ✅ | ⏳ | ⏳ | ⏳ |
| C# (5 variants: 1 + 3 + 1 amalgamate) | ✅ | ⏳ | ⏳ | ⏳ |
| Python (6 variants: 1 + 4 + 1 amalgamate) | ✅ | ⏳ | ⏳ | ⏳ |
| Node / TypeScript (7 variants: 1 + 5 + 1 amalgamate) | ✅ | ⏳ | ⏳ | ⏳ |
| Go (4 variants: 1 + 2 + 1 amalgamate) | ✅ | ⏳ | ⏳ | ⏳ |
| Rust (4 variants: 1 + 2 + 1 amalgamate) | ✅ | ⏳ | ⏳ | ⏳ |
| **Total** | **32 variants** (6 baseline + 20 individual + 6 amalgamate) | | | |

Numbers in the TL;DR headline table (artifact + container image) are **target estimates** until you run:

```powershell
./build-all.ps1            # all 26 build.ps1 scripts
./measure.ps1 > MEASUREMENTS.md
./docker-build-all.ps1     # all 26 Dockerfiles
./docker-measure.ps1 > DOCKER_MEASUREMENTS.md
```
