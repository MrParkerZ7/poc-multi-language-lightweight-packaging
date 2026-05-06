# build-all.ps1 — run every sub-project's build.ps1 and aggregate sizes
# Usage: ./build-all.ps1

$ErrorActionPreference = "Continue"
$root = $PSScriptRoot

$variants = @(
    @{ Lang = "java"   ; Path = "java-kotlin/before-spring-boot-fat-jar" },
    @{ Lang = "java"   ; Path = "java-kotlin/after-jlink"                },
    @{ Lang = "java"   ; Path = "java-kotlin/after-graalvm-native"       },
    @{ Lang = "csharp" ; Path = "csharp/before-self-contained"           },
    @{ Lang = "csharp" ; Path = "csharp/after-aot"                       },
    @{ Lang = "python" ; Path = "python/before-venv-deps"                },
    @{ Lang = "python" ; Path = "python/after-zipapp"                    },
    @{ Lang = "python" ; Path = "python/after-pyinstaller"               },
    @{ Lang = "node"   ; Path = "node/before-npm-tsc"                    },
    @{ Lang = "node"   ; Path = "node/after-esbuild"                     },
    @{ Lang = "node"   ; Path = "node/after-esbuild-llrt"                },
    @{ Lang = "go"     ; Path = "go/before-default-build"                },
    @{ Lang = "go"     ; Path = "go/after-strip-upx"                     },
    @{ Lang = "rust"   ; Path = "rust/before-default-release"            },
    @{ Lang = "rust"   ; Path = "rust/after-size-profile-upx"            }
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
