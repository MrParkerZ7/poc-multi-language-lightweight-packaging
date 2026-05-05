# build-all.ps1 — run every sub-project's build.ps1 and aggregate sizes
# Usage: ./build-all.ps1

$ErrorActionPreference = "Continue"
$root = $PSScriptRoot

$variants = @(
    @{ Lang = "java"   ; Path = "java-kotlin/spring-boot-fat-jar-before"  },
    @{ Lang = "java"   ; Path = "java-kotlin/jlink-after"                 },
    @{ Lang = "java"   ; Path = "java-kotlin/graalvm-native-after"        },
    @{ Lang = "csharp" ; Path = "csharp/self-contained-before"            },
    @{ Lang = "csharp" ; Path = "csharp/aot-after"                        },
    @{ Lang = "python" ; Path = "python/venv-deps-before"                 },
    @{ Lang = "python" ; Path = "python/zipapp-after"                     },
    @{ Lang = "python" ; Path = "python/pyinstaller-after"                },
    @{ Lang = "node"   ; Path = "node/npm-tsc-before"                     },
    @{ Lang = "node"   ; Path = "node/esbuild-after"                      },
    @{ Lang = "node"   ; Path = "node/esbuild-llrt-after"                 },
    @{ Lang = "go"     ; Path = "go/default-build-before"                 },
    @{ Lang = "go"     ; Path = "go/strip-upx-after"                      },
    @{ Lang = "rust"   ; Path = "rust/default-release-before"             },
    @{ Lang = "rust"   ; Path = "rust/size-profile-upx-after"             }
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
