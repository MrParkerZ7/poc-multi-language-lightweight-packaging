# build-all.ps1 — run every sub-project's build.ps1 and aggregate sizes
# Usage: ./build-all.ps1

$ErrorActionPreference = "Continue"
$root = $PSScriptRoot

$variants = @(
    @{ Lang = "java"   ; Path = "java-kotlin/0-standard-spring-boot-fat-jar" },
    @{ Lang = "java"   ; Path = "java-kotlin/1-optimize-jlink"                },
    @{ Lang = "java"   ; Path = "java-kotlin/1-optimize-graalvm-native"       },
    @{ Lang = "java"   ; Path = "java-kotlin/1-optimize-spring-native"        },
    @{ Lang = "java"   ; Path = "java-kotlin/1-optimize-quarkus-native"       },
    @{ Lang = "java"   ; Path = "java-kotlin/2-amalgamate-graalvm-native"     },
    @{ Lang = "java"   ; Path = "java-kotlin/3-best-epsilon-gc"               },
    @{ Lang = "csharp" ; Path = "csharp/0-standard-self-contained"            },
    @{ Lang = "csharp" ; Path = "csharp/1-optimize-trimmed"                   },
    @{ Lang = "csharp" ; Path = "csharp/1-optimize-r2r"                       },
    @{ Lang = "csharp" ; Path = "csharp/1-optimize-aot"                       },
    @{ Lang = "csharp" ; Path = "csharp/2-amalgamate-aot"                     },
    @{ Lang = "csharp" ; Path = "csharp/3-best-max-trim"                      },
    @{ Lang = "python" ; Path = "python/0-standard-venv-deps"                 },
    @{ Lang = "python" ; Path = "python/1-optimize-zipapp"                    },
    @{ Lang = "python" ; Path = "python/1-optimize-pyinstaller"               },
    @{ Lang = "python" ; Path = "python/1-optimize-nuitka"                    },
    @{ Lang = "python" ; Path = "python/1-optimize-pex"                       },
    @{ Lang = "python" ; Path = "python/2-amalgamate-nuitka"                  },
    @{ Lang = "python" ; Path = "python/3-best-pyoxidizer"                    },
    @{ Lang = "node"   ; Path = "node/0-standard-npm-tsc"                     },
    @{ Lang = "node"   ; Path = "node/1-optimize-esbuild"                     },
    @{ Lang = "node"   ; Path = "node/1-optimize-esbuild-llrt"                },
    @{ Lang = "node"   ; Path = "node/1-optimize-webpack"                     },
    @{ Lang = "node"   ; Path = "node/1-optimize-ncc"                         },
    @{ Lang = "node"   ; Path = "node/1-optimize-bun-compile"                 },
    @{ Lang = "node"   ; Path = "node/2-amalgamate-llrt"                      },
    @{ Lang = "node"   ; Path = "node/3-best-quickjs"                         },
    @{ Lang = "go"     ; Path = "go/0-standard-default-build"                 },
    @{ Lang = "go"     ; Path = "go/1-optimize-strip-upx"                     },
    @{ Lang = "go"     ; Path = "go/1-optimize-tinygo"                        },
    @{ Lang = "go"     ; Path = "go/2-amalgamate-tinygo"                      },
    @{ Lang = "go"     ; Path = "go/3-best-leaking-gc"                        },
    @{ Lang = "rust"   ; Path = "rust/0-standard-default-release"             },
    @{ Lang = "rust"   ; Path = "rust/1-optimize-size-profile-upx"            },
    @{ Lang = "rust"   ; Path = "rust/1-optimize-musl-static"                 },
    @{ Lang = "rust"   ; Path = "rust/2-amalgamate-musl"                      },
    @{ Lang = "rust"   ; Path = "rust/3-best-build-std"                       }
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
