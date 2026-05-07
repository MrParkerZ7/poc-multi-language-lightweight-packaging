# Rust musl static — FROM scratch, fully-static binary (~4 MB image, no AV-flag risk like UPX)
FROM rust:1-alpine AS build
WORKDIR /app
RUN apk add --no-cache musl-dev
COPY Cargo.toml ./
COPY src ./src
RUN cargo build --release --target x86_64-unknown-linux-musl \
 && cp target/x86_64-unknown-linux-musl/release/app /app-bin

FROM scratch
COPY --from=build /app-bin /app
ENTRYPOINT ["/app"]
