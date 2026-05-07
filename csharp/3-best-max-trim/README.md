# C# / .NET — 3-best (smallest possible)

Stacks every `2-amalgamate` flag, then turns off every additional runtime feature that isn't needed for "serialize a dict to stdout".

## What's stacked on top of 2-amalgamate

| Lever | Effect |
|-------|--------|
| `IlcGenerateStackTraceData=false` | No stack-trace string data in the binary. Crash dumps show addresses, not method names. |
| `StackTraceSupport=false` | Drops `System.Diagnostics.StackTrace` rooted code from the trim graph. |
| `IlcDisableUnhandledExceptionExperience=true` | Drop the friendly "Unhandled exception in app" formatter — uncaught throws abort raw. |
| `BuiltInComInteropSupport=false` | No COM interop (Windows-only feature, useless for a CLI). |
| `CustomResourceTypesSupport=false` | Resource manager only handles built-in types. |
| `NullabilityInfoContextSupport=false` | Drop reflection-based nullability info. |
| `AutoreleasePoolSupport=false` | macOS-specific, drop on every platform. |
| `UseNativeHttpHandler=false` | We don't make HTTP calls; drop the native handler binding. |
| `_AggressiveAttributeTrimming=true` | Aggressively strip metadata attributes from trimmed types (internal MSBuild flag). |

Plus every flag already in `2-amalgamate`: AOT + `TrimMode=full` + `InvariantGlobalization` + `IlcDisableReflection` + `OptimizationPreference=Size` + EventSource/Metrics off + `UseSystemResourceKeys`.

## Trade-offs

- **No stack traces on crash** — `dotnet-dump` or a debugger required to diagnose production exceptions. For an exec audience: in exchange for ~3 MB you lose the most useful debugging affordance .NET ships.
- **No nullability reflection** — libraries that scan attributes to enforce nullability at runtime won't work.
- **Internal MSBuild flag (`_AggressiveAttributeTrimming`)** — leading underscore = subject to change between SDK versions. Pin to .NET 8 specifically.
- **Still no UPX** — UPX-packing breaks .NET AOT binaries. The size win you'd hope for from compression isn't accessible here.

## Target size

| Stage | Size |
|-------|-----:|
| `2-amalgamate` (AOT + every safe flag) | ~9 MB |
| `3-best` after dropping stack-trace data | ~7 MB |
| `3-best` after dropping every optional feature | **~5 MB** |

(For comparison, raw self-contained publish is ~72 MB, so this is **~14× smaller**.)

## How to build

```powershell
./build.ps1
```

## Prerequisites

- .NET SDK 8.0 (newer .NET versions may rename the internal flags — verify before upgrading)
- Visual Studio 2022 with "Desktop development with C++" workload (for AOT linker on Windows)
- For Linux/macOS: clang/gcc + standard libc dev packages
