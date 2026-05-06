# Java / Kotlin — Lightweight Packaging

Same trivial CLI in five production-deployment shapes.

## The Problem

JVM apps ship two distinct production costs:

1. **The JVM must be installed on every deployment host** (or bundled with the app, ~150 MB JDK). This is operational overhead — version management, security patching, and CVE coordination across the entire fleet.
2. **Spring Boot apps include reflection-based auto-configuration scanning**, producing 25–30 MB fat JARs even for trivial CLIs. Cold-start is ~1+ seconds because the JVM warms up, loads classes, then runs Spring's bean initialization graph.

For exec-friendly cloud workloads (Lambda, edge functions, serverless containers, ephemeral CLIs), both costs hurt at the same time: the artifact is too big to deploy fast, *and* the cold-start blows the latency budget.

The Java row is dramatic in the headline table because the *naive* enterprise build (Spring Boot fat JAR) is the maximum-pain shape — and the gap to the optimized shape (GraalVM native at ~12 MB, ~25 ms cold-start, no JVM needed) shows what's possible when both costs are attacked at once.

## The Solution(s)

| Variant | Artifact | Target size | Runtime needed on host? | Cold-start | Technique |
|---------|----------|------------:|:------------------------|-----------:|-----------|
| `0-before-spring-boot-fat-jar/` | Spring Boot fat JAR | ~28 MB | **Yes** (JDK/JRE 21) | ~1.2 s | Default `spring-boot-maven-plugin repackage` |
| `after-jlink/` | jlink runtime image (folder) | ~32 MB | **No** (JRE bundled) | ~120 ms | Plain Java + Jackson, packaged with `jpackage --type app-image` (which uses jlink internally to ship only required JDK modules) |
| `1-after-graalvm-native/` | GraalVM native image (single binary) | **~12 MB** | **No** | **~25 ms** | `native-image` ahead-of-time compilation via `native-maven-plugin` (plain Java + Jackson) |
| `1-after-spring-native/` | Spring Boot 3 + GraalVM native | ~60 MB | **No** | ~35 ms | Spring Boot 3 with native profile — keeps Spring DI/auto-config but compiles to single binary |
| `1-after-quarkus-native/` | Quarkus native (single binary) | ~50 MB | **No** | **~20 ms** | Quarkus native-first JVM framework — fastest cold-start of the five |
| `2-amalgamate/` | GraalVM native + every safe size knob | **~10 MB** | **No** | **~20 ms** | Plain Java + Jackson + GraalVM native + `-Os` + `--gc=serial` + `--initialize-at-build-time` + `Optimize=2` (stacked size flags). UPX skipped — known incompatibility with native-image relocations. |

## Why three variants?

The "no runtime" story for Java has **two distinct production techniques**, and they're both legitimately deployed:

- **jlink / jpackage** — strips an OpenJDK install down to only the modules your app uses, then bundles app classes alongside. Still a JVM at runtime — full reflection, class loading, JIT. Larger artifact, but easier migration from existing JVM apps.
- **GraalVM native image** — ahead-of-time compiles to a single platform binary. No JVM at runtime — instant cold-start, lower memory, but limited reflection (needs config) and longer build times.

For the exec table, GraalVM native is the headline number; jlink is the "we didn't have to rewrite anything for reflection" story.

## How to build

```powershell
# Spring Boot fat JAR (naive baseline)
cd 0-before-spring-boot-fat-jar
./build.ps1

# jlink runtime image (needs JDK 21)
cd after-jlink
./build.ps1

# GraalVM native — plain Java (needs GraalVM 21 + native-image installed)
cd 1-after-graalvm-native
./build.ps1

# Spring Boot 3 + GraalVM native (keeps Spring, AOT-compiled)
cd 1-after-spring-native
./build.ps1

# Quarkus native (native-first framework, fast cold-start)
cd 1-after-quarkus-native
./build.ps1

# 2-amalgamate: every safe knob stacked (GraalVM + size flags + scratch container)
cd 2-amalgamate
./build.ps1
```

## Prerequisites

- JDK 21 (Eclipse Temurin or Liberica)
- Maven 3.9+
- For `1-after-graalvm-native/`, `1-after-spring-native/`, `1-after-quarkus-native/`: GraalVM 21 with `native-image` (run `gu install native-image`)

## Trade-offs (for the exec)

> "Why not always GraalVM native?"

- **Build time**: Spring Boot JAR builds in ~10s. GraalVM native builds in 1–5 minutes per service.
- **Reflection**: Libraries that scan classes at runtime (Hibernate, Spring's older injection paths, JNI-using libs) need explicit GraalVM reachability metadata. Most modern Spring Boot 3 apps "just work"; legacy code may not.
- **Platform**: Native binaries are platform-specific (one for Linux, one for macOS, one for Windows). Fat JARs and jlink images are cross-platform if the bundled JRE is.

> "Why include jlink at all if GraalVM is smaller?"

- Existing apps that can't go native (reflection-heavy, dynamic class loading) can still drop the "needs JVM installed" requirement via jlink. ~32 MB self-contained still beats requiring every host to have a JDK.
