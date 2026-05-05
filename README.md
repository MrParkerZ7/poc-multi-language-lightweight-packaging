# POC: Multi-Language Lightweight Packaging

A 30-second exec-friendly comparison of how small a **production CLI deployment** can get across the top mainstream programming languages, before vs after applying one well-known minimization technique per language.

---

## TL;DR Headline

| Language | Before | After | Reduction | Runtime needed on host? | Cold-start |
|----------|-------:|------:|----------:|:------------------------|-----------:|
| Java / Kotlin (jlink) | 28 MB | 32 MB | — | No (JRE bundled) | ~120 ms |
| Java / Kotlin (GraalVM native) | 28 MB | **12 MB** | 57% | **No** | **~25 ms** |
| C# / .NET (AOT trimmed) | 72 MB | **11 MB** | 85% | **No** | **~18 ms** |
| Python (zipapp) | 84 MB | 1.2 MB | 99% | Yes (Python 3.11+) | ~70 ms |
| Python (PyInstaller onefile) | 84 MB | **9.8 MB** | 88% | **No** | ~110 ms |
| Node / TypeScript (esbuild bundle) | 200 MB | **1.5 MB** | 99% | Yes (Node 20+) | ~80 ms |
| Node / TypeScript (llrt bundle) | 200 MB | 12 MB | 94% | **No** (llrt ~10 MB) | ~30 ms |
| Go (strip + UPX) | 8 MB | **1.5 MB** | 81% | **No** | ~4 ms |
| Rust (opt-z + strip + UPX) | 6 MB | **400 KB** | 93% | **No** | ~2 ms |

> Numbers are illustrative target ranges based on the trivial CLI in this POC. Run `pwsh ./build-all.ps1` (or each `build.ps1`) to measure on your machine.

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
- **Python before-minimize** — source + `.venv/` + installed deps **shipped together** — the naive Python deploy shape; there is no separate "package" for naive Python prod
- **Python after-minimize** — `.pyz` zipapp; **after-minimize-no-runtime** — PyInstaller `.exe`
- **Node before-minimize** — source + `dist/` + full `node_modules/` **shipped together** — the naive Node deploy shape
- **Node after-minimize** — single `.mjs` bundle; **after-minimize-no-runtime** — `.mjs` + `llrt` binary (both shipped)
- **Go / Rust** — the single executable

The Python and Node "before" rows are intentionally measured as source + deps because that's *how teams actually deploy them naively* (rsync the project + run on host). Measuring only source files for those would understate the operational pain this POC exists to surface.

Practical note for AOT-style variants (Java GraalVM, C# AOT, Rust size-tuned): they produce **massive local build caches** but **tiny shipped artifacts**. Build-cost ≠ deploy-cost. Visual A shows the build-machine reality; Visual B shows what hits the wire.

---

## Visual A — Whole project on disk

Total variant folder size after build. Includes build caches — substantial for AOT/native pipelines.

```
                                  Before (naive)                  After (best-per-lang)
                                  ─────────────────────────       ─────────────────────────────────
Java       fat JAR / GraalVM      ████████          ~50 MB    →   ████████████████   ~250 MB *
C#         self-cont. / AOT       ████████████      ~150 MB   →   ████████████████   ~250 MB *
Python     venv / PyInstaller     ███████           ~84 MB    →   ████                ~50 MB *
Node       npm+tsc / esbuild      █████████████████ ~200 MB   →   ███                 ~30 MB
Go         default / strip+UPX    █                  ~8 MB    →   ▏                  ~1.5 MB
Rust       default / size profile ████████████████████ ~500MB **→  ████████████████████ ~500 MB **
```

  *  AOT/native build caches dominate the disk footprint (linker intermediates, generated native code, cached symbols).
  ** Cargo `target/release/` accumulates compiled crate artifacts — tens to hundreds of MB regardless of source size. Run `cargo clean` to reclaim.

**Takeaway:** AOT / native compilation has a real local-disk cost. Plan CI runner disk and dev-machine storage accordingly.

---

## Visual B — Packaged deployment artifact

What actually ships to a production host. This is the headline-table number — the operational story.

```
                                  Before                          After (best-per-lang)
                                  ─────────────────────────       ─────────────────────────────────
Java                              ████████████        28 MB    →  █████              12 MB  (GraalVM native)
C#                                ████████████████████ 72 MB   →  █████              11 MB  (AOT)
Python                            ████████████████    84 MB    →  ████               9.8 MB (PyInstaller)
Node/TS                           ████████████████████ 200 MB  →  █                  1.5 MB (esbuild bundle)
Go                                ██                   8 MB    →  █                  1.5 MB
Rust                              █                    6 MB    →  ▏                  0.4 MB
```

**Takeaway:** every mainstream language can ship a production CLI under 15 MB. The most dramatic deltas are in the heavy-by-default languages (Java, C#, Python, Node) where naive deploy is 25 MB–200 MB and optimized deploy is 1–12 MB.

---

## What this POC demonstrates

For each language:

1. **`before-minimize/`** — what most teams ship by default (full deps, full runtime, naive packaging).
2. **`after-minimize/`** — the standard "lightweight prod" technique for that language.
3. **`after-minimize-no-runtime/`** *(Java, Python, Node only)* — when the language has a separate "no runtime install needed" technique, this folder shows that variant. Lets the headline table compare both stories honestly.

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
├── java-kotlin-lightweight/
│   ├── README.md                          ← Java-specific table + commands
│   ├── before-minimize/                   ← Spring Boot fat JAR
│   ├── after-minimize/                    ← jlink modular runtime image
│   └── after-minimize-no-runtime/         ← GraalVM native image
├── csharp-lightweight/
│   ├── README.md
│   ├── before-minimize/                   ← default self-contained
│   └── after-minimize/                    ← AOT trimmed
├── python-lightweight/
│   ├── README.md
│   ├── before-minimize/                   ← venv + deps
│   ├── after-minimize/                    ← zipapp (needs Python)
│   └── after-minimize-no-runtime/         ← PyInstaller onefile
├── node-lightweight/
│   ├── README.md
│   ├── before-minimize/                   ← npm install + tsc
│   ├── after-minimize/                    ← esbuild bundle (needs Node)
│   └── after-minimize-no-runtime/         ← esbuild + AWS llrt
├── go-lightweight/
│   ├── README.md
│   ├── before-minimize/                   ← default go build
│   └── after-minimize/                    ← strip + UPX
└── rust-lightweight/
    ├── README.md
    ├── before-minimize/                   ← default cargo build --release
    └── after-minimize/                    ← opt-z + strip + UPX
```

---

## Prerequisites

You only need the toolchains for the languages you want to build — each language is independent.

| Language | Required tools |
|----------|---------------|
| Java / Kotlin | JDK 21 (Temurin), Maven 3.9+, GraalVM 21 (only for `no-runtime`) |
| C# | .NET SDK 8.0+ |
| Python | Python 3.11+, `pip`, `pyinstaller` (for `no-runtime`) |
| Node / TypeScript | Node 20+, `bun` or `npm`, AWS `llrt` binary (for `no-runtime`) |
| Go | Go 1.21+, UPX |
| Rust | rustup + cargo (stable), UPX |

Optional: Docker — every sub-project has a `Dockerfile` so you can build without installing the toolchain locally.

---

## How to build

Each sub-project has a `build.ps1` (PowerShell, Windows-native) and prints the artifact size + cold-start time at the end:

```powershell
# Build a single variant
cd java-kotlin-lightweight/after-minimize
./build.ps1
# → Artifact: target/app/bin/app  (32.4 MB)
# → Cold-start: 118 ms

# Build everything (top-level helper, runs every build.ps1 under each language)
./build-all.ps1
```

After a full build, regenerate the headline table:

```powershell
./measure.ps1 > MEASUREMENTS.md
```

---

## Status

| Language | Scaffolded | Built locally | Numbers verified |
|----------|:---------:|:-------------:|:----------------:|
| Java / Kotlin | ✅ | ⏳ | ⏳ |
| C# | ✅ | ⏳ | ⏳ |
| Python | ✅ | ⏳ | ⏳ |
| Node / TypeScript | ✅ | ⏳ | ⏳ |
| Go | ✅ | ⏳ | ⏳ |
| Rust | ✅ | ⏳ | ⏳ |

Numbers in the headline table are **target estimates** until builds are run and `MEASUREMENTS.md` is generated.
