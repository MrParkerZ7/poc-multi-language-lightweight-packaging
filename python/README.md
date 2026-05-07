# Python — Lightweight Packaging

Same trivial CLI in six production-deployment shapes.

## The Problem

Python deployments ship the source tree + a venv + every transitive pip dependency. A typical enterprise service has 30–50 dependencies; `requests` alone pulls `urllib3`, `certifi`, `charset-normalizer`, `idna` — about 15 MB. Total deployed size of 100–300 MB is the norm, not the exception.

On top of that, **Python itself must be installed on every host** with the right minor version (3.11 vs 3.12 matters for some libs). Migrating a service across Python versions means coordinating with every machine that runs it.

The two distinct lightweight techniques attack different parts of this problem:

- **zipapp** removes the *unused dependency weight* — ship a single archive containing only the code that's actually used. But Python is still required on the host.
- **PyInstaller** removes the *Python install requirement* — bundle a stripped Python interpreter into the artifact itself. Larger binary, but runs on a vanilla machine with nothing pre-installed.

Both are legitimately deployed in production. The exec choice is "do we already provision Python on every host?" — if yes, zipapp; if no, PyInstaller.

## The Solution(s)

| Variant | Artifact | Target size | Runtime needed on host? | Cold-start | Technique |
|---------|----------|------------:|:------------------------|-----------:|-----------|
| `0-standard-venv-deps/` | source + venv + deps (folder) | ~84 MB | **Yes** (Python 3.11+) | ~70 ms | Default `pip install -r requirements.txt` into a venv, ship the whole thing |
| `1-optimize-zipapp/` | `app.pyz` (zipapp) | **~10 KB**–1.2 MB | **Yes** (Python 3.11+) | ~70 ms | `python -m zipapp` — single archive, stdlib-only or vendored deps |
| `1-optimize-pyinstaller/` | `app.exe` (PyInstaller) | **~9.8 MB** | **No** | ~110 ms | `pyinstaller --onefile` — bundles a stripped Python interpreter |
| `1-optimize-nuitka/` | `app.exe` (Nuitka onefile) | **~8 MB** | **No** | ~50 ms | `nuitka --onefile` — actually compiles Python → C → native binary; smaller and faster than PyInstaller |
| `1-optimize-pex/` | `app.pex` (PEX) | ~1 MB | **Yes** (Python 3.x) | ~80 ms | Twitter/Pants's "zipapp on steroids" — single .pex file with vendored deps |
| `2-amalgamate-nuitka/` | Nuitka onefile + LTO + every size flag | **~7 MB** | **No** | **~45 ms** | `nuitka --onefile --lto=yes --no-pyi-file --remove-output` (stacked). UPX skipped — Nuitka onefile uses self-extraction; UPX can break it. |
| `3-best-pyoxidizer/` | PyOxidizer + memory-only modules + stripped CPython + UPX-LZMA | **~4 MB** | **No** | **~25 ms** | Switches foundation to PyOxidizer (embeds CPython in a Rust binary, loads modules from RAM — no self-extraction). Adds `optimize_level=2`, drops site/user-site/env, and applies UPX-LZMA on Linux ELF. **Trade**: PyOxidizer build is finicky vs. Nuitka; C-extension wheels need explicit handling. |

## Why three variants?

Python's "lightweight" story splits into two distinct ops shapes:

- **zipapp** is the "smallest possible artifact" — for teams that already provision Python on every host. Useful for internal tooling, sysadmin scripts, anything where a managed Python is already part of the platform.
- **PyInstaller (or Nuitka, PyOxidizer)** is the "no install needed" shape — bundles a Python interpreter into the binary. Larger artifact, but executes on a vanilla machine.

The before/after spread is dramatic: `pip install` of typical enterprise deps (requests, rich, pydantic, etc.) easily exceeds 80 MB. The same CLI as a zipapp is ~10 KB if it uses only the stdlib.

## How to build

```powershell
# Show the typical naive deploy — venv + deps
cd 0-standard-venv-deps
./build.ps1

# zipapp (smallest artifact, needs Python)
cd 1-optimize-zipapp
./build.ps1

# PyInstaller onefile (no Python needed on host)
cd 1-optimize-pyinstaller
./build.ps1

# Nuitka onefile (Python -> C -> native, smaller + faster than PyInstaller)
cd 1-optimize-nuitka
./build.ps1

# PEX (zipapp+, single .pex file)
cd 1-optimize-pex
./build.ps1

# 2-amalgamate: Nuitka with LTO + every size flag stacked
cd 2-amalgamate-nuitka
./build.ps1

# 3-best: PyOxidizer + memory-only modules + UPX-LZMA (smallest possible)
cd 3-best-pyoxidizer
./build.ps1   # first run installs PyOxidizer via cargo install
```

## Prerequisites

- Python 3.11 or later (with `pip` and `venv`)
- For `1-optimize-pyinstaller/`: `pip install pyinstaller`
- For `1-optimize-nuitka/`: `pip install nuitka` (build script auto-installs if missing)
- For `1-optimize-pex/`: `pip install pex` (build script auto-installs if missing)

## Trade-offs (for the exec)

> "Why is the 'before' so big for a 30-line CLI?"

Because Python deployments in practice ship the source tree, the venv, and every transitive dependency. `requests` alone pulls `urllib3`, `charset-normalizer`, `certifi`, `idna` — ~15 MB. A typical enterprise Python service has 30–50 dependencies and ships 100–300 MB to prod. zipapp removes the unused weight; PyInstaller removes Python itself from the host.

> "What about Nuitka / PyOxidizer?"

Both are alternatives to PyInstaller — Nuitka actually compiles Python to C and tends to produce slightly smaller, faster binaries; PyOxidizer embeds the interpreter in a Rust binary. Same operational story (no Python install needed), just different trade-offs on build time and compatibility. PyInstaller is the most ubiquitous, so it's the headline here.
