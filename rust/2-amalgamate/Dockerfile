# 2-amalgamate (Rust): musl static + every Cargo size knob + UPX + FROM scratch
FROM rust:1-alpine AS build
WORKDIR /app
RUN apk add --no-cache musl-dev upx
COPY Cargo.toml ./
COPY src ./src
RUN cargo build --release --target x86_64-unknown-linux-musl \
 && upx --best --lzma target/x86_64-unknown-linux-musl/release/app \
 && cp target/x86_64-unknown-linux-musl/release/app /app-bin

FROM scratch
COPY --from=build /app-bin /app
ENTRYPOINT ["/app"]
