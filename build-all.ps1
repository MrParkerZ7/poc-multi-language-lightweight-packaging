# build-all.ps1 — run every sub-project's build.ps1 and aggregate sizes
# Usage: ./build-all.ps1

$ErrorActionPreference = "Continue"
$root = $PSScriptRoot

$variants = @(
    @{ Lang = "java"   ; Path = "java-kotlin/0-before-spring-boot-fat-jar" },
    @{ Lang = "java"   ; Path = "java-kotlin/1-after-jlink"                },
    @{ Lang = "java"   ; Path = "java-kotlin/1-after-graalvm-native"       },
    @{ Lang = "java"   ; Path = "java-kotlin/1-after-spring-native"        },
    @{ Lang = "java"   ; Path = "java-kotlin/1-after-quarkus-native"       },
    @{ Lang = "java"   ; Path = "java-kotlin/2-amalgamate"                 },
    @{ Lang = "java"   ; Path = "java-kotlin/3-best"                       },
    @{ Lang = "csharp" ; Path = "csharp/0-before-self-contained"           },
    @{ Lang = "csharp" ; Path = "csharp/1-after-trimmed"                   },
    @{ Lang = "csharp" ; Path = "csharp/1-after-r2r"                       },
    @{ Lang = "csharp" ; Path = "csharp/1-after-aot"                       },
    @{ Lang = "csharp" ; Path = "csharp/2-amalgamate"                      },
    @{ Lang = "csharp" ; Path = "csharp/3-best"                            },
    @{ Lang = "python" ; Path = "python/0-before-venv-deps"                },
    @{ Lang = "python" ; Path = "python/1-after-zipapp"                    },
    @{ Lang = "python" ; Path = "python/1-after-pyinstaller"               },
    @{ Lang = "python" ; Path = "python/1-after-nuitka"                    },
    @{ Lang = "python" ; Path = "python/1-after-pex"                       },
    @{ Lang = "python" ; Path = "python/2-amalgamate"                      },
    @{ Lang = "python" ; Path = "python/3-best"                            },
    @{ Lang = "node"   ; Path = "node/0-before-npm-tsc"                    },
    @{ Lang = "node"   ; Path = "node/1-after-esbuild"                     },
    @{ Lang = "node"   ; Path = "node/1-after-esbuild-llrt"                },
    @{ Lang = "node"   ; Path = "node/1-after-webpack"                     },
    @{ Lang = "node"   ; Path = "node/1-after-ncc"                         },
    @{ Lang = "node"   ; Path = "node/1-after-bun-compile"                 },
    @{ Lang = "node"   ; Path = "node/2-amalgamate"                        },
    @{ Lang = "node"   ; Path = "node/3-best"                              },
    @{ Lang = "go"     ; Path = "go/0-before-default-build"                },
    @{ Lang = "go"     ; Path = "go/1-after-strip-upx"                     },
    @{ Lang = "go"     ; Path = "go/1-after-tinygo"                        },
    @{ Lang = "go"     ; Path = "go/2-amalgamate"                          },
    @{ Lang = "go"     ; Path = "go/3-best"                                },
    @{ Lang = "rust"   ; Path = "rust/0-before-default-release"            },
    @{ Lang = "rust"   ; Path = "rust/1-after-size-profile-upx"            },
    @{ Lang = "rust"   ; Path = "rust/1-after-musl-static"                 },
    @{ Lang = "rust"   ; Path = "rust/2-amalgamate"                        },
    @{ Lang = "rust"   ; Path = "rust/3-best"                              }
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
