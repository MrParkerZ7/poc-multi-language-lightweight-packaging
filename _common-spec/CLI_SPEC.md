# Common CLI Specification

Every language in this POC implements **the same trivial CLI**, so size and cold-start differences come purely from packaging, not from feature scope.

## Behavior

When invoked with no arguments, print one line of JSON to stdout and exit with code 0:

```json
{"hello":"world","language":"<lang-name>","uuid":"<random-uuid-v4>","timestamp":"<iso8601-utc>"}
```

Example:

```bash
$ ./app
{"hello":"world","language":"java","uuid":"7f3c2e91-4a8b-4c6d-9e1a-2b5f7c8d3e9a","timestamp":"2026-05-05T12:34:56Z"}
```

## Required dependencies (forces real "weight" into the naive-baseline side)

| Concern | Use this (per language) |
|---------|------------------------|
| JSON serialization | Standard JSON lib for the language (Jackson / System.Text.Json / json / JSON.stringify / encoding/json / serde_json) |
| UUID v4 generation | Standard UUID lib (java.util.UUID / System.Guid / uuid / crypto.randomUUID / google/uuid / uuid crate) |
| ISO-8601 timestamp | Standard time lib |

For Java's `0-standard-spring-boot-fat-jar/` specifically, use **Spring Boot** to add realistic enterprise weight (~25 MB fat JAR for trivial CLI is the typical naive deployment most teams encounter).

For every other naive-baseline folder (`0-standard-*/`), just deploy the way most teams naively do: include the whole project tree + full dep install + the language's default packaging.

## Field rules

| Field | Type | Notes |
|-------|------|-------|
| `hello` | string | Always literal `"world"` |
| `language` | string | One of: `java`, `kotlin`, `csharp`, `python`, `node`, `typescript`, `go`, `rust` |
| `uuid` | string | RFC 4122 v4 UUID, lowercase hex |
| `timestamp` | string | ISO-8601 in UTC with `Z` suffix, second precision |

## Output rules

- Single line of JSON to stdout.
- No trailing newline-only print of stats (build script measures externally).
- Exit code `0` on success, `1` on failure.

## Verification

After building any variant, run the artifact and pipe through `jq` (or any JSON validator) to confirm output:

```bash
./app | jq .
# Expected: a single JSON object with the four fields above
```

The `build.ps1` in each sub-project does this verification automatically before reporting size and cold-start.
