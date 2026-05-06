# Rust default release — FROM scratch (~7 MB image)
FROM rust:1-slim AS build
WORKDIR /app
COPY Cargo.toml ./
COPY src ./src
RUN cargo build --release \
 && cp target/release/app /app-bin

FROM scratch
COPY --from=build /app-bin /app
ENTRYPOINT ["/app"]
