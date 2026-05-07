$13-best-pyoxidizer (Python): PyOxidizer + memory-only modules + stripped CPython + UPX-LZMA + scratch-adjacent
FROM rust:1-bullseye AS build
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3 python3-pip python3-dev \
        build-essential cmake patchelf upx-ucl \
    && rm -rf /var/lib/apt/lists/*
RUN cargo install pyoxidizer

COPY pyproject.toml app.py pyoxidizer.bzl ./
RUN pyoxidizer build --release exe

# Find produced binary, strip + UPX
RUN find /app/build -type f -name 'app' -executable -exec cp {} /app-bin \; \
 && upx --best --lzma /app-bin

FROM debian:12-slim
COPY --from=build /app-bin /app
ENTRYPOINT ["/app"]
