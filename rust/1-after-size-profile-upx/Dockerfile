# Rust opt-z + LTO + strip + UPX — FROM scratch (~0.5 MB image)
FROM rust:1-slim AS build
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends upx-ucl \
    && rm -rf /var/lib/apt/lists/*
COPY Cargo.toml ./
COPY src ./src
RUN cargo build --release \
 && upx --best --lzma target/release/app \
 && cp target/release/app /app-bin

FROM scratch
COPY --from=build /app-bin /app
ENTRYPOINT ["/app"]
