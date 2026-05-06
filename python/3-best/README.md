# Python — 3-best (smallest possible)

Switches the foundation from Nuitka onefile to **PyOxidizer**, which embeds CPython in a Rust binary and loads modules from memory. Stacks UPX-LZMA on top.

## What's stacked on top of 2-amalgamate

The base technique itself is different here — `2-amalgamate` uses Nuitka's onefile (Python → C → native + self-extraction). `3-best` switches to PyOxidizer, which:

| Lever | Effect |
|-------|--------|
| **PyOxidizer** instead of Nuitka onefile | Embeds CPython interpreter directly into a Rust binary. No self-extraction step at startup. |
| `resources_location = "in-memory"` | Python modules are loaded from RAM (read directly out of the binary's data section), not extracted to a temp dir. Faster cold-start AND smaller artifact. |
| `optimize_level = 2` + `bytecode_optimize_level_two` | Pre-compile all bytecode at level 2 (asserts stripped, docstrings dropped). |
| `include_distribution_sources = False` | Don't ship CPython source files alongside the bundled bytecode — bytecode only. |
| `include_distribution_resources = False` | Drop the language-tag tables, locale data, etc. that ship with full CPython distributions. |
| `site_import = False` + `user_site_directory = False` + `use_environment = False` | Skip every "look around the host for config" step. Strips ~50 KB of import machinery. |
| `faulthandler = False` + `tracemalloc = False` | Drop runtime debug subsystems. |
| UPX `--best --lzma` (Linux) | LZMA compression on the produced ELF. |

## Trade-offs vs. `2-amalgamate` (Nuitka)

- **PyOxidizer is finicky** — Nuitka "just works" on most pure Python; PyOxidizer requires a `.bzl` config and tighter control over the dependency tree. C-extension wheels (numpy, pandas, lxml) need explicit handling.
- **Less mainstream** — Nuitka has more StackOverflow answers; PyOxidizer is a niche tool from the Indygreg / Mercurial community.
- **Smaller AND faster cold-start** — because there's no self-extraction, cold-start drops from ~45 ms (Nuitka onefile) to ~25 ms (PyOxidizer). Same code, better start.
- **No UPX on Nuitka onefile (in 2-amalgamate)** — Nuitka onefile uses self-extraction which UPX breaks. PyOxidizer doesn't self-extract, so UPX-LZMA is safe.

## Target size

| Stage | Size |
|-------|-----:|
| `2-amalgamate` (Nuitka onefile + LTO + size flags) | ~7 MB |
| `3-best` after PyOxidizer + memory-only modules | ~6 MB before UPX |
| `3-best` after UPX-LZMA on Linux | **~4 MB** |

## How to build

```powershell
./build.ps1
```

First run installs PyOxidizer via `cargo install pyoxidizer` (5-10 min). Subsequent builds are ~30s.

## Prerequisites

- Rust toolchain (`rustup` — for `cargo install pyoxidizer`)
- Python 3.11 (for `pip install` resource resolution during the build)
- UPX on PATH for Linux builds (https://upx.github.io/)
- For Docker build: nothing extra — handled inline
