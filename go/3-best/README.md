# Go — 3-best (smallest possible)

Stacks every `2-amalgamate` knob, then drops Go runtime features that aren't strictly needed for a single-shot CLI.

## What's stacked on top of 2-amalgamate

| Lever | Effect |
|-------|--------|
| `-gc=leaking` | No GC at all — every allocation is leaked. Fine for a process that exits after one print. Removes the GC code entirely (~20-30% of TinyGo runtime). |
| `-scheduler=none` | Drop the goroutine scheduler. Single-threaded only — no `go func()`, no channels-as-blocking, no async I/O. |
| `-panic=trap` | Replace panic-print machinery with a single SIGTRAP/CPU trap instruction. Crashes silently with no message. |
| `upx --best --lzma` | LZMA compression (vs `2-amalgamate`'s default `--best`) |

Plus every flag already in `2-amalgamate`: `-opt=z`, `-no-debug`, then UPX.

## Trade-offs

- **Single-shot CLI only** — leaking GC + no scheduler means this profile is wrong for any long-running service or anything that uses goroutines. Process must exit cleanly to release memory back to the OS.
- **Silent crash on panic** — `panic=trap` produces no stack trace, no error message. Just SIGTRAP. Debugging requires running the binary under gdb/lldb or rebuilding with `2-amalgamate` flags.
- **No `encoding/json` GC pressure?** — Yes, `json.Marshal` allocates. With `gc=leaking` those allocations stick around for the entire process lifetime. For a 5 ms CLI run that's ~2 KB total leaked — irrelevant.

## Target size

| Stage | Size |
|-------|-----:|
| `2-amalgamate` (TinyGo + opt=z + UPX) | ~200 KB |
| `3-best` after dropping GC + scheduler + panic | ~280 KB before UPX, ~150 KB after default UPX |
| `3-best` after final UPX `--best --lzma` | **~120 KB** |

## How to build

```powershell
./build.ps1
```

## Prerequisites

- TinyGo (https://tinygo.org/getting-started/install/)
- UPX on PATH (https://upx.github.io/)
