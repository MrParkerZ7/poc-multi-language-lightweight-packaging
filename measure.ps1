# measure.ps1 — collect artifact sizes + cold-start times into a markdown table
# Usage: ./measure.ps1 > MEASUREMENTS.md

$root = $PSScriptRoot

$variants = @(
    @{ Lang = "Java/Kotlin (Spring Boot fat JAR)"                ; Artifact = "java-kotlin/0-before-spring-boot-fat-jar/target/app.jar"                       },
    @{ Lang = "Java/Kotlin (jlink runtime)"                       ; Artifact = "java-kotlin/1-after-jlink/target/app/bin/app"                                 },
    @{ Lang = "Java/Kotlin (GraalVM native)"                      ; Artifact = "java-kotlin/1-after-graalvm-native/target/app.exe"                            },
    @{ Lang = "Java/Kotlin (Spring Native)"                       ; Artifact = "java-kotlin/1-after-spring-native/target/app.exe"                             },
    @{ Lang = "Java/Kotlin (Quarkus native)"                      ; Artifact = "java-kotlin/1-after-quarkus-native/target/app-1.0.0-runner.exe"               },
    @{ Lang = "Java/Kotlin (2-amalgamate: GraalVM all-knobs)"     ; Artifact = "java-kotlin/2-amalgamate/target/app.exe"                                      },
    @{ Lang = "C# (.NET self-contained)"                          ; Artifact = "csharp/0-before-self-contained/publish/app.exe"                               },
    @{ Lang = "C# (PublishTrimmed, no AOT)"                       ; Artifact = "csharp/1-after-trimmed/publish/app.exe"                                       },
    @{ Lang = "C# (ReadyToRun precompiled)"                       ; Artifact = "csharp/1-after-r2r/publish/app.exe"                                           },
    @{ Lang = "C# (Native AOT)"                                   ; Artifact = "csharp/1-after-aot/publish/app.exe"                                           },
    @{ Lang = "C# (2-amalgamate: AOT all-knobs)"                  ; Artifact = "csharp/2-amalgamate/publish/app.exe"                                          },
    @{ Lang = "Python (venv + deps)"                              ; Artifact = "python/0-before-venv-deps/.venv"                                              },
    @{ Lang = "Python (zipapp)"                                   ; Artifact = "python/1-after-zipapp/dist/app.pyz"                                           },
    @{ Lang = "Python (PyInstaller onefile)"                      ; Artifact = "python/1-after-pyinstaller/dist/app.exe"                                      },
    @{ Lang = "Python (Nuitka onefile)"                           ; Artifact = "python/1-after-nuitka/dist/app.exe"                                           },
    @{ Lang = "Python (PEX)"                                      ; Artifact = "python/1-after-pex/dist/app.pex"                                              },
    @{ Lang = "Python (2-amalgamate: Nuitka LTO all-knobs)"       ; Artifact = "python/2-amalgamate/dist/app.exe"                                             },
    @{ Lang = "Node/TS (full project + node_modules)"             ; Artifact = "node/0-before-npm-tsc/node_modules"                                           },
    @{ Lang = "Node/TS (esbuild bundle)"                          ; Artifact = "node/1-after-esbuild/dist/app.mjs"                                            },
    @{ Lang = "Node/TS (esbuild + llrt)"                          ; Artifact = "node/1-after-esbuild-llrt/dist/app.mjs"                                       },
    @{ Lang = "Node/TS (webpack bundle)"                          ; Artifact = "node/1-after-webpack/dist/app.cjs"                                            },
    @{ Lang = "Node/TS (@vercel/ncc bundle)"                      ; Artifact = "node/1-after-ncc/dist/index.js"                                               },
    @{ Lang = "Node/TS (bun --compile single binary)"             ; Artifact = "node/1-after-bun-compile/dist/app.exe"                                        },
    @{ Lang = "Node/TS (2-amalgamate: esbuild + UPX-llrt)"        ; Artifact = "node/2-amalgamate/dist/app.mjs"                                               },
    @{ Lang = "Go (default)"                                      ; Artifact = "go/0-before-default-build/app.exe"                                            },
    @{ Lang = "Go (strip + UPX)"                                  ; Artifact = "go/1-after-strip-upx/app.exe"                                                 },
    @{ Lang = "Go (TinyGo)"                                       ; Artifact = "go/1-after-tinygo/app.exe"                                                    },
    @{ Lang = "Go (2-amalgamate: TinyGo + UPX)"                   ; Artifact = "go/2-amalgamate/app.exe"                                                      },
    @{ Lang = "Rust (default)"                                    ; Artifact = "rust/0-before-default-release/target/release/app.exe"                         },
    @{ Lang = "Rust (opt-z + strip + UPX)"                        ; Artifact = "rust/1-after-size-profile-upx/target/release/app.exe"                         },
    @{ Lang = "Rust (musl static — Linux)"                        ; Artifact = "rust/1-after-musl-static/target/x86_64-unknown-linux-musl/release/app"        },
    @{ Lang = "Rust (2-amalgamate: musl + all-knobs + UPX)"       ; Artifact = "rust/2-amalgamate/target/x86_64-unknown-linux-musl/release/app"               }
)

function Get-Size {
    param($path)
    $full = Join-Path $root $path
    if (-not (Test-Path $full)) { return "N/A" }
    if ((Get-Item $full).PSIsContainer) {
        $bytes = (Get-ChildItem $full -Recurse -File | Measure-Object -Property Length -Sum).Sum
    } else {
        $bytes = (Get-Item $full).Length
    }
    if ($bytes -ge 1MB) { return "{0:N1} MB" -f ($bytes / 1MB) }
    if ($bytes -ge 1KB) { return "{0:N1} KB" -f ($bytes / 1KB) }
    return "$bytes B"
}

"# Measurements"
""
"Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
""
"| Variant | Artifact size |"
"|---------|--------------:|"
foreach ($v in $variants) {
    $size = Get-Size $v.Artifact
    "| $($v.Lang) | $size |"
}
""
"> Cold-start times require running each artifact; see per-language README for `Measure-Command`-based timing."
