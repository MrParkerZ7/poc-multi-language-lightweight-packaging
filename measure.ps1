# measure.ps1 — collect artifact sizes + cold-start times into a markdown table
# Usage: ./measure.ps1 > MEASUREMENTS.md

$root = $PSScriptRoot

$variants = @(
    @{ Lang = "Java/Kotlin (Spring Boot fat JAR)"           ; Artifact = "java-kotlin/before-spring-boot-fat-jar/target/app.jar"             ; Run = "java -jar `"<artifact>`"" },
    @{ Lang = "Java/Kotlin (jlink runtime)"                 ; Artifact = "java-kotlin/after-jlink/target/app/bin/app"                       ; Run = "`"<artifact>`""           },
    @{ Lang = "Java/Kotlin (GraalVM native)"                ; Artifact = "java-kotlin/after-graalvm-native/target/app.exe"                  ; Run = "`"<artifact>`""           },
    @{ Lang = "C# (.NET self-contained)"                    ; Artifact = "csharp/before-self-contained/publish/app.exe"                     ; Run = "`"<artifact>`""           },
    @{ Lang = "C# (AOT trimmed)"                            ; Artifact = "csharp/after-aot/publish/app.exe"                                 ; Run = "`"<artifact>`""           },
    @{ Lang = "Python (venv + deps)"                        ; Artifact = "python/before-venv-deps/.venv"                                    ; Run = "python -m app"            },
    @{ Lang = "Python (zipapp)"                             ; Artifact = "python/after-zipapp/dist/app.pyz"                                 ; Run = "python `"<artifact>`""    },
    @{ Lang = "Python (PyInstaller onefile)"                ; Artifact = "python/after-pyinstaller/dist/app.exe"                            ; Run = "`"<artifact>`""           },
    @{ Lang = "Node/TS (full project + node_modules)"       ; Artifact = "node/before-npm-tsc/node_modules"                                 ; Run = "node dist/main.js"        },
    @{ Lang = "Node/TS (esbuild bundle)"                    ; Artifact = "node/after-esbuild/dist/app.mjs"                                  ; Run = "node `"<artifact>`""      },
    @{ Lang = "Node/TS (llrt bundle)"                       ; Artifact = "node/after-esbuild-llrt/dist/app.mjs"                             ; Run = "llrt `"<artifact>`""      },
    @{ Lang = "Go (default)"                                ; Artifact = "go/before-default-build/app.exe"                                  ; Run = "`"<artifact>`""           },
    @{ Lang = "Go (strip + UPX)"                            ; Artifact = "go/after-strip-upx/app.exe"                                       ; Run = "`"<artifact>`""           },
    @{ Lang = "Rust (default)"                              ; Artifact = "rust/before-default-release/target/release/app.exe"               ; Run = "`"<artifact>`""           },
    @{ Lang = "Rust (opt-z + strip + UPX)"                  ; Artifact = "rust/after-size-profile-upx/target/release/app.exe"               ; Run = "`"<artifact>`""           }
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
