# measure.ps1 — collect artifact sizes + cold-start times into a markdown table
# Usage: ./measure.ps1 > MEASUREMENTS.md

$root = $PSScriptRoot

$variants = @(
    @{ Lang = "Java/Kotlin (Spring Boot fat JAR)"           ; Artifact = "java-kotlin/before-spring-boot-fat-jar/target/app.jar"                       },
    @{ Lang = "Java/Kotlin (jlink runtime)"                 ; Artifact = "java-kotlin/after-jlink/target/app/bin/app"                                 },
    @{ Lang = "Java/Kotlin (GraalVM native)"                ; Artifact = "java-kotlin/after-graalvm-native/target/app.exe"                            },
    @{ Lang = "Java/Kotlin (Spring Native)"                 ; Artifact = "java-kotlin/after-spring-native/target/app.exe"                             },
    @{ Lang = "Java/Kotlin (Quarkus native)"                ; Artifact = "java-kotlin/after-quarkus-native/target/app-1.0.0-runner.exe"               },
    @{ Lang = "C# (.NET self-contained)"                    ; Artifact = "csharp/before-self-contained/publish/app.exe"                               },
    @{ Lang = "C# (PublishTrimmed, no AOT)"                 ; Artifact = "csharp/after-trimmed/publish/app.exe"                                       },
    @{ Lang = "C# (ReadyToRun precompiled)"                 ; Artifact = "csharp/after-r2r/publish/app.exe"                                           },
    @{ Lang = "C# (Native AOT)"                             ; Artifact = "csharp/after-aot/publish/app.exe"                                           },
    @{ Lang = "Python (venv + deps)"                        ; Artifact = "python/before-venv-deps/.venv"                                              },
    @{ Lang = "Python (zipapp)"                             ; Artifact = "python/after-zipapp/dist/app.pyz"                                           },
    @{ Lang = "Python (PyInstaller onefile)"                ; Artifact = "python/after-pyinstaller/dist/app.exe"                                      },
    @{ Lang = "Python (Nuitka onefile)"                     ; Artifact = "python/after-nuitka/dist/app.exe"                                           },
    @{ Lang = "Python (PEX)"                                ; Artifact = "python/after-pex/dist/app.pex"                                              },
    @{ Lang = "Node/TS (full project + node_modules)"       ; Artifact = "node/before-npm-tsc/node_modules"                                           },
    @{ Lang = "Node/TS (esbuild bundle)"                    ; Artifact = "node/after-esbuild/dist/app.mjs"                                            },
    @{ Lang = "Node/TS (esbuild + llrt)"                    ; Artifact = "node/after-esbuild-llrt/dist/app.mjs"                                       },
    @{ Lang = "Node/TS (webpack bundle)"                    ; Artifact = "node/after-webpack/dist/app.cjs"                                            },
    @{ Lang = "Node/TS (@vercel/ncc bundle)"                ; Artifact = "node/after-ncc/dist/index.js"                                               },
    @{ Lang = "Node/TS (bun --compile single binary)"       ; Artifact = "node/after-bun-compile/dist/app.exe"                                        },
    @{ Lang = "Go (default)"                                ; Artifact = "go/before-default-build/app.exe"                                            },
    @{ Lang = "Go (strip + UPX)"                            ; Artifact = "go/after-strip-upx/app.exe"                                                 },
    @{ Lang = "Go (TinyGo)"                                 ; Artifact = "go/after-tinygo/app.exe"                                                    },
    @{ Lang = "Rust (default)"                              ; Artifact = "rust/before-default-release/target/release/app.exe"                         },
    @{ Lang = "Rust (opt-z + strip + UPX)"                  ; Artifact = "rust/after-size-profile-upx/target/release/app.exe"                         },
    @{ Lang = "Rust (musl static — Linux)"                  ; Artifact = "rust/after-musl-static/target/x86_64-unknown-linux-musl/release/app"        }
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
