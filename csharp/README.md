# C# / .NET — Lightweight Packaging

Same trivial CLI in four production-deployment shapes.

## The Problem

Modern .NET CLIs are typically published "self-contained" so they don't require .NET to be installed on the host. The trade is artifact size — the entire .NET runtime (CLR, JIT, BCL, GC, plus a stripped sub-tree of dependencies) is bundled into the executable, producing 60–80 MB binaries for even trivial apps.

On top of that, cold-start carries JIT compilation overhead: the runtime walks the IL, optimizes hot paths, then runs. For serverless or short-lived CLIs you pay this on every invocation, not once per process.

So C# inherits the same dual-cost shape as Java, just with different numbers — large artifact (because the runtime is always shipped) plus JIT cold-start tax. Native AOT addresses both at the same time: smaller binary (no JIT, no full BCL, dead code trimmed) and instant start (no JIT pause).

## The Solution(s)

| Variant | Artifact | Target size | Runtime needed on host? | Cold-start | Technique |
|---------|----------|------------:|:------------------------|-----------:|-----------|
| `0-before-self-contained/` | self-contained .exe + folder | ~72 MB | **No** (full .NET runtime bundled) | ~80 ms | Default `dotnet publish -r win-x64 --self-contained -p:PublishSingleFile=true` |
| `1-after-trimmed/` | trimmed self-contained | ~25 MB | **No** | ~60 ms | `PublishTrimmed=true` — drops unused IL, keeps JIT runtime; full reflection still works on referenced types |
| `1-after-r2r/` | ReadyToRun precompiled | ~75 MB | **No** | ~50 ms | `PublishReadyToRun=true` — precompiles IL→native at publish; faster cold-start, slightly larger |
| `1-after-aot/` | Native AOT single .exe | **~11 MB** | **No** | **~18 ms** | `PublishAot=true` (.NET 8+) — full AOT compile, smallest + fastest |
| `2-amalgamate/` | Native AOT + every safe knob | **~9 MB** | **No** | **~15 ms** | AOT + `TrimMode=full` + `IlcDisableReflection` + `OptimizationPreference=Size` + EventSource/Metrics/Debugger off + `IlcFoldIdenticalMethodBodies` (stacked). UPX skipped — known incompatibility with .NET AOT loader. |

## Why no separate "no runtime" variant for C#?

Both variants are already "no runtime needed" on the host — .NET self-contained publishing always bundles the runtime. The interesting trade is **size and cold-start**, not runtime presence:

- **Self-contained** (.NET 8): bundles the full CLR + BCL → big artifact, JIT-compiled at startup, all reflection works.
- **Native AOT**: ahead-of-time compiles to a single platform binary with a stripped-down runtime → small artifact, instant start, but no dynamic code loading and limited reflection.

For most modern CLI/microservice workloads, AOT is the right answer in 2026. For apps that load plugins or rely heavily on runtime reflection (older EF Core providers, some serializers), self-contained is the safer path.

## How to build

```powershell
# Self-contained (naive baseline)
cd 0-before-self-contained
./build.ps1

# PublishTrimmed (no AOT) — middle ground
cd 1-after-trimmed
./build.ps1

# ReadyToRun precompiled (faster cold-start, slightly larger)
cd 1-after-r2r
./build.ps1

# Native AOT (~6× smaller, ~4× faster cold-start)
cd 1-after-aot
./build.ps1

# 2-amalgamate: every safe knob stacked (AOT + full trim + reflection off + size optimization)
cd 2-amalgamate
./build.ps1
```

## Prerequisites

- .NET SDK 8.0 or later
- For AOT on Windows: Visual Studio 2022 with "Desktop development with C++" workload (provides the linker `link.exe`).
- For AOT on Linux/macOS: clang/gcc + standard libc dev packages.

## Trade-offs (for the exec)

> "Why doesn't every C# app use AOT?"

- **Reflection limits**: AOT trims unused code aggressively. Libraries that build types/handlers at runtime (some ORMs, dynamic IoC scenarios) need explicit "trim warnings" cleanup.
- **Build time**: Self-contained publish takes ~5s. AOT publish takes ~30s–2min depending on app size (it's an actual native compile).
- **Platform-specific**: AOT binaries target one OS+arch combo. CI must build per platform.

> "Where does AOT shine?"

- Cloud-native CLIs, single-purpose microservices, AWS Lambda / Azure Functions where cold-start cost is real money. Container images shrink dramatically (no need for `mcr.microsoft.com/dotnet/runtime` base — you ship a `scratch`-based image with one binary).
