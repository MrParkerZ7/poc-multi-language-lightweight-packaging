# C# / .NET — Lightweight Packaging

Same trivial CLI in two production-deployment shapes.

| Variant | Artifact | Target size | Runtime needed on host? | Cold-start | Technique |
|---------|----------|------------:|:------------------------|-----------:|-----------|
| `before-minimize/` | self-contained .exe + folder | ~72 MB | **No** (full .NET runtime bundled) | ~80 ms | Default `dotnet publish -r win-x64 --self-contained -p:PublishSingleFile=true` |
| `after-minimize/` | AOT-compiled single .exe | **~11 MB** | **No** | **~18 ms** | `dotnet publish -c Release -r win-x64 -p:PublishAot=true` (Native AOT, .NET 8+) |

## Why no `after-minimize-no-runtime/` for C#?

Both variants are already "no runtime needed" on the host — .NET self-contained publishing always bundles the runtime. The interesting trade is **size and cold-start**, not runtime presence:

- **Self-contained** (.NET 8): bundles the full CLR + BCL → big artifact, JIT-compiled at startup, all reflection works.
- **Native AOT**: ahead-of-time compiles to a single platform binary with a stripped-down runtime → small artifact, instant start, but no dynamic code loading and limited reflection.

For most modern CLI/microservice workloads, AOT is the right answer in 2026. For apps that load plugins or rely heavily on runtime reflection (older EF Core providers, some serializers), self-contained is the safer path.

## How to build

```powershell
# Self-contained (default)
cd before-minimize
./build.ps1

# Native AOT (~6× smaller, ~4× faster cold-start)
cd after-minimize
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
