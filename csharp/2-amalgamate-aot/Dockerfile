$12-amalgamate-aot (C#): every AOT/trim knob stacked + scratch-adjacent container
# - Native AOT + full trim + size optimization + reflection disabled
# - Drops EventSource, Metrics, HTTP activity propagation, debugger support
# - Final stage on alpine runtime-deps (smallest base for AOT-linked native libs)
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends clang zlib1g-dev && rm -rf /var/lib/apt/lists/*
COPY app.csproj .
COPY Program.cs .
RUN dotnet publish -c Release -r linux-x64 -o /publish

FROM mcr.microsoft.com/dotnet/runtime-deps:8.0-alpine
COPY --from=build /publish/app /app
ENTRYPOINT ["/app"]
