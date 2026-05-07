# docker-build-all.ps1 — build a Docker image for every variant and report image size
# Usage: ./docker-build-all.ps1

$ErrorActionPreference = "Continue"
$root = $PSScriptRoot

$variants = @(
    @{ Path = "java-kotlin/0-standard-spring-boot-fat-jar" ; Tag = "poc-lightweight/java-spring-boot-fat-jar"  },
    @{ Path = "java-kotlin/1-optimize-jlink"               ; Tag = "poc-lightweight/java-jlink"                },
    @{ Path = "java-kotlin/1-optimize-graalvm-native"      ; Tag = "poc-lightweight/java-graalvm-native"       },
    @{ Path = "java-kotlin/1-optimize-spring-native"       ; Tag = "poc-lightweight/java-spring-native"        },
    @{ Path = "java-kotlin/1-optimize-quarkus-native"      ; Tag = "poc-lightweight/java-quarkus-native"       },
    @{ Path = "java-kotlin/2-amalgamate-graalvm-native"    ; Tag = "poc-lightweight/java-amalgamate"           },
    @{ Path = "java-kotlin/3-best-epsilon-gc"              ; Tag = "poc-lightweight/java-3-best"               },
    @{ Path = "csharp/0-standard-self-contained"           ; Tag = "poc-lightweight/csharp-self-contained"     },
    @{ Path = "csharp/1-optimize-trimmed"                  ; Tag = "poc-lightweight/csharp-trimmed"            },
    @{ Path = "csharp/1-optimize-r2r"                      ; Tag = "poc-lightweight/csharp-r2r"                },
    @{ Path = "csharp/1-optimize-aot"                      ; Tag = "poc-lightweight/csharp-aot"                },
    @{ Path = "csharp/2-amalgamate-aot"                    ; Tag = "poc-lightweight/csharp-amalgamate"         },
    @{ Path = "csharp/3-best-max-trim"                     ; Tag = "poc-lightweight/csharp-3-best"             },
    @{ Path = "python/0-standard-venv-deps"                ; Tag = "poc-lightweight/python-venv-deps"          },
    @{ Path = "python/1-optimize-zipapp"                   ; Tag = "poc-lightweight/python-zipapp"             },
    @{ Path = "python/1-optimize-pyinstaller"              ; Tag = "poc-lightweight/python-pyinstaller"        },
    @{ Path = "python/1-optimize-nuitka"                   ; Tag = "poc-lightweight/python-nuitka"             },
    @{ Path = "python/1-optimize-pex"                      ; Tag = "poc-lightweight/python-pex"                },
    @{ Path = "python/2-amalgamate-nuitka"                 ; Tag = "poc-lightweight/python-amalgamate"         },
    @{ Path = "python/3-best-pyoxidizer"                   ; Tag = "poc-lightweight/python-3-best"             },
    @{ Path = "node/0-standard-npm-tsc"                    ; Tag = "poc-lightweight/node-npm-tsc"              },
    @{ Path = "node/1-optimize-esbuild"                    ; Tag = "poc-lightweight/node-esbuild"              },
    @{ Path = "node/1-optimize-esbuild-llrt"               ; Tag = "poc-lightweight/node-esbuild-llrt"         },
    @{ Path = "node/1-optimize-webpack"                    ; Tag = "poc-lightweight/node-webpack"              },
    @{ Path = "node/1-optimize-ncc"                        ; Tag = "poc-lightweight/node-ncc"                  },
    @{ Path = "node/1-optimize-bun-compile"                ; Tag = "poc-lightweight/node-bun-compile"          },
    @{ Path = "node/2-amalgamate-llrt"                     ; Tag = "poc-lightweight/node-amalgamate"           },
    @{ Path = "node/3-best-quickjs"                        ; Tag = "poc-lightweight/node-3-best"               },
    @{ Path = "go/0-standard-default-build"                ; Tag = "poc-lightweight/go-default-build"          },
    @{ Path = "go/1-optimize-strip-upx"                    ; Tag = "poc-lightweight/go-strip-upx"              },
    @{ Path = "go/1-optimize-tinygo"                       ; Tag = "poc-lightweight/go-tinygo"                 },
    @{ Path = "go/2-amalgamate-tinygo"                     ; Tag = "poc-lightweight/go-amalgamate"             },
    @{ Path = "go/3-best-leaking-gc"                       ; Tag = "poc-lightweight/go-3-best"                 },
    @{ Path = "rust/0-standard-default-release"            ; Tag = "poc-lightweight/rust-default-release"      },
    @{ Path = "rust/1-optimize-size-profile-upx"           ; Tag = "poc-lightweight/rust-size-profile-upx"     },
    @{ Path = "rust/1-optimize-musl-static"                ; Tag = "poc-lightweight/rust-musl-static"          },
    @{ Path = "rust/2-amalgamate-musl"                     ; Tag = "poc-lightweight/rust-amalgamate"           },
    @{ Path = "rust/3-best-build-std"                      ; Tag = "poc-lightweight/rust-3-best"               }
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
