# build-all.ps1 — run every sub-project's build.ps1 and aggregate sizes
# Usage: ./build-all.ps1

$ErrorActionPreference = "Continue"
$root = $PSScriptRoot

$variants = @(
    @{ Lang = "java"   ; Path = "java-kotlin-lightweight/before-minimize"           },
    @{ Lang = "java"   ; Path = "java-kotlin-lightweight/after-minimize"            },
    @{ Lang = "java"   ; Path = "java-kotlin-lightweight/after-minimize-no-runtime" },
    @{ Lang = "csharp" ; Path = "csharp-lightweight/before-minimize"                },
    @{ Lang = "csharp" ; Path = "csharp-lightweight/after-minimize"                 },
    @{ Lang = "python" ; Path = "python-lightweight/before-minimize"                },
    @{ Lang = "python" ; Path = "python-lightweight/after-minimize"                 },
    @{ Lang = "python" ; Path = "python-lightweight/after-minimize-no-runtime"      },
    @{ Lang = "node"   ; Path = "node-lightweight/before-minimize"                  },
    @{ Lang = "node"   ; Path = "node-lightweight/after-minimize"                   },
    @{ Lang = "node"   ; Path = "node-lightweight/after-minimize-no-runtime"        },
    @{ Lang = "go"     ; Path = "go-lightweight/before-minimize"                    },
    @{ Lang = "go"     ; Path = "go-lightweight/after-minimize"                     },
    @{ Lang = "rust"   ; Path = "rust-lightweight/before-minimize"                  },
    @{ Lang = "rust"   ; Path = "rust-lightweight/after-minimize"                   }
)

Write-Host ""
Write-Host "================================================================"
Write-Host " POC: Multi-Language Lightweight Packaging — full build"
Write-Host "================================================================"
Write-Host ""

foreach ($v in $variants) {
    $script = Join-Path $root $v.Path "build.ps1"
    if (Test-Path $script) {
        Write-Host "--- $($v.Path) ---" -ForegroundColor Cyan
        Push-Location (Join-Path $root $v.Path)
        try { & ./build.ps1 } catch { Write-Warning "Build failed: $_" }
        Pop-Location
        Write-Host ""
    } else {
        Write-Warning "Skipped (no build.ps1): $($v.Path)"
    }
}

Write-Host "Done. Run ./measure.ps1 to refresh MEASUREMENTS.md"
