# docker-build-all.ps1 — build a Docker image for every variant and report image size
# Usage: ./docker-build-all.ps1
#
# Tags each image as poc-lightweight/<lang>-<variant>:latest
# Prints final image sizes at the end. Skips variants whose Dockerfile is missing.

$ErrorActionPreference = "Continue"
$root = $PSScriptRoot

$variants = @(
    @{ Path = "java-kotlin/before-spring-boot-fat-jar" ; Tag = "poc-lightweight/java-spring-boot-fat-jar"  },
    @{ Path = "java-kotlin/after-jlink"                ; Tag = "poc-lightweight/java-jlink"                },
    @{ Path = "java-kotlin/after-graalvm-native"       ; Tag = "poc-lightweight/java-graalvm-native"       },
    @{ Path = "java-kotlin/after-spring-native"        ; Tag = "poc-lightweight/java-spring-native"        },
    @{ Path = "java-kotlin/after-quarkus-native"       ; Tag = "poc-lightweight/java-quarkus-native"       },
    @{ Path = "csharp/before-self-contained"           ; Tag = "poc-lightweight/csharp-self-contained"     },
    @{ Path = "csharp/after-trimmed"                   ; Tag = "poc-lightweight/csharp-trimmed"            },
    @{ Path = "csharp/after-r2r"                       ; Tag = "poc-lightweight/csharp-r2r"                },
    @{ Path = "csharp/after-aot"                       ; Tag = "poc-lightweight/csharp-aot"                },
    @{ Path = "python/before-venv-deps"                ; Tag = "poc-lightweight/python-venv-deps"          },
    @{ Path = "python/after-zipapp"                    ; Tag = "poc-lightweight/python-zipapp"             },
    @{ Path = "python/after-pyinstaller"               ; Tag = "poc-lightweight/python-pyinstaller"        },
    @{ Path = "python/after-nuitka"                    ; Tag = "poc-lightweight/python-nuitka"             },
    @{ Path = "python/after-pex"                       ; Tag = "poc-lightweight/python-pex"                },
    @{ Path = "node/before-npm-tsc"                    ; Tag = "poc-lightweight/node-npm-tsc"              },
    @{ Path = "node/after-esbuild"                     ; Tag = "poc-lightweight/node-esbuild"              },
    @{ Path = "node/after-esbuild-llrt"                ; Tag = "poc-lightweight/node-esbuild-llrt"         },
    @{ Path = "node/after-webpack"                     ; Tag = "poc-lightweight/node-webpack"              },
    @{ Path = "node/after-ncc"                         ; Tag = "poc-lightweight/node-ncc"                  },
    @{ Path = "node/after-bun-compile"                 ; Tag = "poc-lightweight/node-bun-compile"          },
    @{ Path = "go/before-default-build"                ; Tag = "poc-lightweight/go-default-build"          },
    @{ Path = "go/after-strip-upx"                     ; Tag = "poc-lightweight/go-strip-upx"              },
    @{ Path = "go/after-tinygo"                        ; Tag = "poc-lightweight/go-tinygo"                 },
    @{ Path = "rust/before-default-release"            ; Tag = "poc-lightweight/rust-default-release"      },
    @{ Path = "rust/after-size-profile-upx"            ; Tag = "poc-lightweight/rust-size-profile-upx"     },
    @{ Path = "rust/after-musl-static"                 ; Tag = "poc-lightweight/rust-musl-static"          }
)

# Verify Docker is available
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
    # Get image size
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
