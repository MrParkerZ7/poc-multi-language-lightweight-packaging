# docker-measure.ps1 — collect docker image sizes into a markdown table
# Usage: ./docker-measure.ps1 > DOCKER_MEASUREMENTS.md
# Prerequisite: run ./docker-build-all.ps1 first to build all images.

$variants = @(
    @{ Lang = "Java/Kotlin (Spring Boot fat JAR)"                ; Tag = "poc-lightweight/java-spring-boot-fat-jar"  },
    @{ Lang = "Java/Kotlin (jlink)"                              ; Tag = "poc-lightweight/java-jlink"                },
    @{ Lang = "Java/Kotlin (GraalVM native)"                     ; Tag = "poc-lightweight/java-graalvm-native"       },
    @{ Lang = "Java/Kotlin (Spring Native)"                      ; Tag = "poc-lightweight/java-spring-native"        },
    @{ Lang = "Java/Kotlin (Quarkus native)"                     ; Tag = "poc-lightweight/java-quarkus-native"       },
    @{ Lang = "Java/Kotlin (2-amalgamate)"                       ; Tag = "poc-lightweight/java-amalgamate"           },
    @{ Lang = "C# (.NET self-contained)"                         ; Tag = "poc-lightweight/csharp-self-contained"     },
    @{ Lang = "C# (PublishTrimmed)"                              ; Tag = "poc-lightweight/csharp-trimmed"            },
    @{ Lang = "C# (ReadyToRun)"                                  ; Tag = "poc-lightweight/csharp-r2r"                },
    @{ Lang = "C# (Native AOT)"                                  ; Tag = "poc-lightweight/csharp-aot"                },
    @{ Lang = "C# (2-amalgamate)"                                ; Tag = "poc-lightweight/csharp-amalgamate"         },
    @{ Lang = "Python (venv + deps)"                             ; Tag = "poc-lightweight/python-venv-deps"          },
    @{ Lang = "Python (zipapp)"                                  ; Tag = "poc-lightweight/python-zipapp"             },
    @{ Lang = "Python (PyInstaller)"                             ; Tag = "poc-lightweight/python-pyinstaller"        },
    @{ Lang = "Python (Nuitka)"                                  ; Tag = "poc-lightweight/python-nuitka"             },
    @{ Lang = "Python (PEX)"                                     ; Tag = "poc-lightweight/python-pex"                },
    @{ Lang = "Python (2-amalgamate)"                            ; Tag = "poc-lightweight/python-amalgamate"         },
    @{ Lang = "Node/TS (full project + node_modules)"            ; Tag = "poc-lightweight/node-npm-tsc"              },
    @{ Lang = "Node/TS (esbuild bundle)"                         ; Tag = "poc-lightweight/node-esbuild"              },
    @{ Lang = "Node/TS (esbuild + llrt)"                         ; Tag = "poc-lightweight/node-esbuild-llrt"         },
    @{ Lang = "Node/TS (webpack)"                                ; Tag = "poc-lightweight/node-webpack"              },
    @{ Lang = "Node/TS (@vercel/ncc)"                            ; Tag = "poc-lightweight/node-ncc"                  },
    @{ Lang = "Node/TS (bun --compile)"                          ; Tag = "poc-lightweight/node-bun-compile"          },
    @{ Lang = "Node/TS (2-amalgamate)"                           ; Tag = "poc-lightweight/node-amalgamate"           },
    @{ Lang = "Go (default)"                                     ; Tag = "poc-lightweight/go-default-build"          },
    @{ Lang = "Go (strip + UPX)"                                 ; Tag = "poc-lightweight/go-strip-upx"              },
    @{ Lang = "Go (TinyGo)"                                      ; Tag = "poc-lightweight/go-tinygo"                 },
    @{ Lang = "Go (2-amalgamate)"                                ; Tag = "poc-lightweight/go-amalgamate"             },
    @{ Lang = "Rust (default)"                                   ; Tag = "poc-lightweight/rust-default-release"      },
    @{ Lang = "Rust (opt-z + strip + UPX)"                       ; Tag = "poc-lightweight/rust-size-profile-upx"     },
    @{ Lang = "Rust (musl static)"                               ; Tag = "poc-lightweight/rust-musl-static"          },
    @{ Lang = "Rust (2-amalgamate)"                              ; Tag = "poc-lightweight/rust-amalgamate"           }
)

function Get-ImageSize {
    param($tag)
    $bytes = docker image inspect $tag --format '{{.Size}}' 2>$null
    if (-not $bytes) { return "N/A" }
    $b = [long]$bytes
    if ($b -ge 1GB) { return "{0:N2} GB" -f ($b / 1GB) }
    if ($b -ge 1MB) { return "{0:N1} MB" -f ($b / 1MB) }
    if ($b -ge 1KB) { return "{0:N1} KB" -f ($b / 1KB) }
    return "$b B"
}

"# Docker Image Measurements"
""
"Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
""
"| Variant | Image size |"
"|---------|-----------:|"
foreach ($v in $variants) {
    $size = Get-ImageSize $v.Tag
    "| $($v.Lang) | $size |"
}
""
"> Build all images first with `./docker-build-all.ps1`. Image sizes are reported by `docker image inspect`."
