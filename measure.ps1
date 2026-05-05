# measure.ps1 — collect artifact sizes + cold-start times into a markdown table
# Usage: ./measure.ps1 > MEASUREMENTS.md

$root = $PSScriptRoot

$variants = @(
    @{ Lang = "Java/Kotlin (Spring Boot fat JAR)"           ; Artifact = "java-kotlin/spring-boot-fat-jar-before/target/app.jar"             ; Run = "java -jar `"<artifact>`"" },
    @{ Lang = "Java/Kotlin (jlink runtime)"                 ; Artifact = "java-kotlin/jlink-after/target/app/bin/app"                       ; Run = "`"<artifact>`""           },
    @{ Lang = "Java/Kotlin (GraalVM native)"                ; Artifact = "java-kotlin/graalvm-native-after/target/app.exe"                  ; Run = "`"<artifact>`""           },
    @{ Lang = "C# (.NET self-contained)"                    ; Artifact = "csharp/self-contained-before/publish/app.exe"                     ; Run = "`"<artifact>`""           },
    @{ Lang = "C# (AOT trimmed)"                            ; Artifact = "csharp/aot-after/publish/app.exe"                                 ; Run = "`"<artifact>`""           },
    @{ Lang = "Python (venv + deps)"                        ; Artifact = "python/venv-deps-before/.venv"                                    ; Run = "python -m app"            },
    @{ Lang = "Python (zipapp)"                             ; Artifact = "python/zipapp-after/dist/app.pyz"                                 ; Run = "python `"<artifact>`""    },
    @{ Lang = "Python (PyInstaller onefile)"                ; Artifact = "python/pyinstaller-after/dist/app.exe"                            ; Run = "`"<artifact>`""           },
    @{ Lang = "Node/TS (full project + node_modules)"       ; Artifact = "node/npm-tsc-before/node_modules"                                 ; Run = "node dist/main.js"        },
    @{ Lang = "Node/TS (esbuild bundle)"                    ; Artifact = "node/esbuild-after/dist/app.mjs"                                  ; Run = "node `"<artifact>`""      },
    @{ Lang = "Node/TS (llrt bundle)"                       ; Artifact = "node/esbuild-llrt-after/dist/app.mjs"                             ; Run = "llrt `"<artifact>`""      },
    @{ Lang = "Go (default)"                                ; Artifact = "go/default-build-before/app.exe"                                  ; Run = "`"<artifact>`""           },
    @{ Lang = "Go (strip + UPX)"                            ; Artifact = "go/strip-upx-after/app.exe"                                       ; Run = "`"<artifact>`""           },
    @{ Lang = "Rust (default)"                              ; Artifact = "rust/default-release-before/target/release/app.exe"               ; Run = "`"<artifact>`""           },
    @{ Lang = "Rust (opt-z + strip + UPX)"                  ; Artifact = "rust/size-profile-upx-after/target/release/app.exe"               ; Run = "`"<artifact>`""           }
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
