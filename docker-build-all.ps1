# docker-build-all.ps1 — build a Docker image for every variant and report image size
# Usage: ./docker-build-all.ps1

$ErrorActionPreference = "Continue"
$root = $PSScriptRoot

$variants = @(
    @{ Path = "java-kotlin/0-before-spring-boot-fat-jar" ; Tag = "poc-lightweight/java-spring-boot-fat-jar"  },
    @{ Path = "java-kotlin/1-after-jlink"                ; Tag = "poc-lightweight/java-jlink"                },
    @{ Path = "java-kotlin/1-after-graalvm-native"       ; Tag = "poc-lightweight/java-graalvm-native"       },
    @{ Path = "java-kotlin/1-after-spring-native"        ; Tag = "poc-lightweight/java-spring-native"        },
    @{ Path = "java-kotlin/1-after-quarkus-native"       ; Tag = "poc-lightweight/java-quarkus-native"       },
    @{ Path = "java-kotlin/2-amalgamate"                 ; Tag = "poc-lightweight/java-amalgamate"           },
    @{ Path = "java-kotlin/3-best"                       ; Tag = "poc-lightweight/java-3-best"               },
    @{ Path = "csharp/0-before-self-contained"           ; Tag = "poc-lightweight/csharp-self-contained"     },
    @{ Path = "csharp/1-after-trimmed"                   ; Tag = "poc-lightweight/csharp-trimmed"            },
    @{ Path = "csharp/1-after-r2r"                       ; Tag = "poc-lightweight/csharp-r2r"                },
    @{ Path = "csharp/1-after-aot"                       ; Tag = "poc-lightweight/csharp-aot"                },
    @{ Path = "csharp/2-amalgamate"                      ; Tag = "poc-lightweight/csharp-amalgamate"         },
    @{ Path = "csharp/3-best"                            ; Tag = "poc-lightweight/csharp-3-best"             },
    @{ Path = "python/0-before-venv-deps"                ; Tag = "poc-lightweight/python-venv-deps"          },
    @{ Path = "python/1-after-zipapp"                    ; Tag = "poc-lightweight/python-zipapp"             },
    @{ Path = "python/1-after-pyinstaller"               ; Tag = "poc-lightweight/python-pyinstaller"        },
    @{ Path = "python/1-after-nuitka"                    ; Tag = "poc-lightweight/python-nuitka"             },
    @{ Path = "python/1-after-pex"                       ; Tag = "poc-lightweight/python-pex"                },
    @{ Path = "python/2-amalgamate"                      ; Tag = "poc-lightweight/python-amalgamate"         },
    @{ Path = "python/3-best"                            ; Tag = "poc-lightweight/python-3-best"             },
    @{ Path = "node/0-before-npm-tsc"                    ; Tag = "poc-lightweight/node-npm-tsc"              },
    @{ Path = "node/1-after-esbuild"                     ; Tag = "poc-lightweight/node-esbuild"              },
    @{ Path = "node/1-after-esbuild-llrt"                ; Tag = "poc-lightweight/node-esbuild-llrt"         },
    @{ Path = "node/1-after-webpack"                     ; Tag = "poc-lightweight/node-webpack"              },
    @{ Path = "node/1-after-ncc"                         ; Tag = "poc-lightweight/node-ncc"                  },
    @{ Path = "node/1-after-bun-compile"                 ; Tag = "poc-lightweight/node-bun-compile"          },
    @{ Path = "node/2-amalgamate"                        ; Tag = "poc-lightweight/node-amalgamate"           },
    @{ Path = "node/3-best"                              ; Tag = "poc-lightweight/node-3-best"               },
    @{ Path = "go/0-before-default-build"                ; Tag = "poc-lightweight/go-default-build"          },
    @{ Path = "go/1-after-strip-upx"                     ; Tag = "poc-lightweight/go-strip-upx"              },
    @{ Path = "go/1-after-tinygo"                        ; Tag = "poc-lightweight/go-tinygo"                 },
    @{ Path = "go/2-amalgamate"                          ; Tag = "poc-lightweight/go-amalgamate"             },
    @{ Path = "go/3-best"                                ; Tag = "poc-lightweight/go-3-best"                 },
    @{ Path = "rust/0-before-default-release"            ; Tag = "poc-lightweight/rust-default-release"      },
    @{ Path = "rust/1-after-size-profile-upx"            ; Tag = "poc-lightweight/rust-size-profile-upx"     },
    @{ Path = "rust/1-after-musl-static"                 ; Tag = "poc-lightweight/rust-musl-static"          },
    @{ Path = "rust/2-amalgamate"                        ; Tag = "poc-lightweight/rust-amalgamate"           },
    @{ Path = "rust/3-best"                              ; Tag = "poc-lightweight/rust-3-best"               }
)

$docker = Get-Command docker -ErrorAction SilentlyContinue
if (-not $docker) { throw "docker not found on PATH. Install Docker Desktop or Docker Engine first." }

Write-Host ""
Write-Host "================================================================"
Write-Host " POC: Multi-Language Lightweight Packaging — docker build all"
Write-Host "================================================================"
Write-Host ""

$results = @()

foreach ($v in $variants) {
    $dockerfile = Join-Path $root $v.Path "Dockerfile"
    if (-not (Test-Path $dockerfile)) {
        Write-Warning "Skipped (no Dockerfile): $($v.Path)"
        continue
    }
    Write-Host "--- $($v.Path) -> $($v.Tag) ---" -ForegroundColor Cyan
    $context = Join-Path $root $v.Path
    docker build -t $v.Tag $context
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "docker build failed for $($v.Path)"
        $results += [pscustomobject]@{ Variant = $v.Path ; Tag = $v.Tag ; Size = "BUILD FAILED" }
        continue
    }
    $bytes = (docker image inspect $v.Tag --format '{{.Size}}') -as [long]
    $sizeMB = "{0:N1} MB" -f ($bytes / 1MB)
    $results += [pscustomobject]@{ Variant = $v.Path ; Tag = $v.Tag ; Size = $sizeMB }
    Write-Host ""
}

Write-Host ""
Write-Host "================================================================"
Write-Host " Image sizes"
Write-Host "================================================================"
$results | Format-Table -AutoSize
