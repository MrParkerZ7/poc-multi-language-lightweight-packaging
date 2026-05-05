# Python — Lightweight Packaging

Same trivial CLI in three production-deployment shapes.

| Variant | Artifact | Target size | Runtime needed on host? | Cold-start | Technique |
|---------|----------|------------:|:------------------------|-----------:|-----------|
| `before-minimize/` | source + venv + deps (folder) | ~84 MB | **Yes** (Python 3.11+) | ~70 ms | Default `pip install -r requirements.txt` into a venv, ship the whole thing |
| `after-minimize/` | `app.pyz` (zipapp) | **~10 KB**–1.2 MB | **Yes** (Python 3.11+) | ~70 ms | `python -m zipapp` — single archive, stdlib-only or vendored deps |
| `after-minimize-no-runtime/` | `app.exe` (PyInstaller) | **~9.8 MB** | **No** | ~110 ms | `pyinstaller --onefile` — bundles a stripped Python interpreter |

## Why three variants?

Python's "lightweight" story splits into two distinct ops shapes:

- **zipapp** is the "smallest possible artifact" — for teams that already provision Python on every host. Useful for internal tooling, sysadmin scripts, anything where a managed Python is already part of the platform.
- **PyInstaller (or Nuitka, PyOxidizer)** is the "no install needed" shape — bundles a Python interpreter into the binary. Larger artifact, but executes on a vanilla machine.

The before/after spread is dramatic: `pip install` of typical enterprise deps (requests, rich, pydantic, etc.) easily exceeds 80 MB. The same CLI as a zipapp is ~10 KB if it uses only the stdlib.

## How to build

```powershell
# Show the typical "before" — venv + deps
cd before-minimize
./build.ps1

# zipapp (smallest artifact, needs Python)
cd after-minimize
./build.ps1

# PyInstaller onefile (no Python needed on host)
cd after-minimize-no-runtime
./build.ps1
```

## Prerequisites

- Python 3.11 or later (with `pip` and `venv`)
- For `after-minimize-no-runtime/`: `pip install pyinstaller`

## Trade-offs (for the exec)

> "Why is the 'before' so big for a 30-line CLI?"

Because Python deployments in practice ship the source tree, the venv, and every transitive dependency. `requests` alone pulls `urllib3`, `charset-normalizer`, `certifi`, `idna` — ~15 MB. A typical enterprise Python service has 30–50 dependencies and ships 100–300 MB to prod. zipapp removes the unused weight; PyInstaller removes Python itself from the host.

> "What about Nuitka / PyOxidizer?"

Both are alternatives to PyInstaller — Nuitka actually compiles Python to C and tends to produce slightly smaller, faster binaries; PyOxidizer embeds the interpreter in a Rust binary. Same operational story (no Python install needed), just different trade-offs on build time and compatibility. PyInstaller is the most ubiquitous, so it's the headline here.
