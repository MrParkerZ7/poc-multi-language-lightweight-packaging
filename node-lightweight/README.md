# Node / TypeScript — Lightweight Packaging

Same trivial CLI in three production-deployment shapes.

## The Problem

`node_modules` is famously heavy because npm installs every transitive dependency eagerly — and most teams `npm install` (which keeps dev deps) instead of `npm ci --omit=dev` on the deploy box. A typical TypeScript service ships 150–500 MB to production: the source, the compiled `dist/`, the type definitions, the test framework, the linter, plus the full transitive dependency tree of every runtime lib.

On top of that, **Node must be installed on every host**. The "self-contained" packaging options that exist for Node — `bun build --compile`, `node --experimental-sea`, `pkg` — all bundle the *full* Node/Bun runtime, producing 50–60 MB single binaries. They solve the runtime-install problem but make the size problem worse, not better.

The two distinct lightweight techniques attack different parts of this:

- **esbuild bundle + minify** is the "smallest possible artifact" answer — tree-shake to a single 1–2 MB `.mjs`, ship just that file. Host still needs Node, but the artifact is dramatic.
- **AWS `llrt`** is the "no runtime install needed" answer — a Rust-based ~10 MB JS-subset runtime that runs the bundle directly. Total deploy ~12 MB self-contained, matching Java GraalVM and C# AOT in operational shape.

The trade is API coverage: llrt implements a subset of Node APIs (most stdlib, basic fs/http/crypto, AWS SDK). Pure JS code and modern serverless workloads run fine; legacy Node code that uses native modules or worker threads may not.

## The Solution(s)

| Variant | Artifact | Target size | Runtime needed on host? | Cold-start | Technique |
|---------|----------|------------:|:------------------------|-----------:|-----------|
| `before-minimize/` | source + `node_modules/` + `dist/` (folder) | ~150–200 MB | **Yes** (Node 20+) | ~120 ms | Default `npm install && tsc` deployment — ship everything |
| `after-minimize/` | `dist/app.mjs` (esbuild bundle) | **~1.5 MB** | **Yes** (Node 20+) | ~80 ms | `esbuild --bundle --minify --platform=node` — single JS file with all deps tree-shaken and minified |
| `after-minimize-no-runtime/` | `dist/app.mjs` + AWS `llrt` binary | **~12 MB** total | **No** (llrt bundled, ~10 MB) | ~30 ms | Same esbuild bundle, executed by AWS `llrt` (Rust-based JS subset runtime) |

## Why three variants?

Node's "lightweight prod deploy" splits into two production techniques, both legitimately deployed:

- **esbuild bundle (needs Node)** — the smallest possible artifact (~1–2 MB). Ship one `.mjs` file. Host needs Node installed (or you use a Node Docker base image like `node:20-alpine` ~40 MB). This is what most teams should do.
- **`llrt` (no runtime needed)** — AWS's Rust-based JS runtime. Single ~10 MB binary that runs JS files. Implements a subset of Node APIs (most stdlib, most fs/http) but not 100% Node-compatible. Used by AWS for sub-100 ms Lambda cold-starts. Total deploy: ~12 MB self-contained. The "zero runtime install" answer for Node, matching Java GraalVM and C# AOT.

> Why not `bun build --compile` or `node --experimental-sea`?
>
> Both bundle the entire Bun/Node runtime → ~50–60 MB single binary. Heavier than both esbuild and llrt, with no real cold-start advantage over llrt. They exist; they're just not the right pick for "lightweight".

## How to build

```powershell
# Default deployment (the "before" story)
cd before-minimize
./build.ps1

# esbuild bundle (smallest, needs Node)
cd after-minimize
./build.ps1

# esbuild + llrt (no runtime install needed)
cd after-minimize-no-runtime
./build.ps1   # downloads llrt binary on first run
```

## Prerequisites

- Node 20 or later, npm
- For `after-minimize-no-runtime/`: the build script auto-downloads `llrt` from the AWS GitHub release. No manual install needed.

## Trade-offs (for the exec)

> "Why is the 'before' so big?"

`node_modules` is famously heavy because npm installs every transitive dep eagerly. A typical TypeScript service ships `tsc`, type definitions, dev tooling, and the full runtime dep tree — 150–500 MB is normal. Tree-shaking + minification compresses the actually-used code to ~1–2 MB; the rest was overhead.

> "What's the catch with `llrt`?"

It's a JS *subset*. Pure JS code, basic stdlib (fs, http, crypto, url, buffer), and AWS SDK work. Native Node modules (anything that compiles C++ via node-gyp), child_process spawning, worker threads, and some newer Node APIs may not. For CLIs, microservices, and serverless functions the coverage is excellent. For legacy Node apps, validate compatibility before committing.

> "Can we get even smaller than 1.5 MB?"

For our trivial CLI (no deps used), yes — the bundled `.mjs` would be ~5 KB. The 1.5 MB number reflects what a *real* CLI looks like once you bundle in `axios` / `zod` / `uuid` / `dayjs` (the deps in `before-minimize`'s `package.json`). Shows what minification actually achieves on a representative codebase, not a Hello World.
