$13-best-build-std (Rust): nightly + build-std + immediate-abort + every 2-amalgamate knob + UPX-LZMA + scratch
FROM rustlang/rust:nightly-alpine AS build
WORKDIR /app
RUN apk add --no-cache musl-dev upx
RUN rustup component add rust-src --toolchain nightly \
 && rustup target add x86_64-unknown-linux-musl --toolchain nightly
COPY Cargo.toml rust-toolchain.toml ./
COPY .cargo ./.cargo
COPY src ./src
RUN cargo +nightly build --release --target x86_64-unknown-linux-musl \
 && upx --best --lzma target/x86_64-unknown-linux-musl/release/app \
 && cp target/x86_64-unknown-linux-musl/release/app /app-bin

FROM scratch
COPY --from=build /app-bin /app
ENTRYPOINT ["/app"]
