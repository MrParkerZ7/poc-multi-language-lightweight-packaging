$13-best-quickjs (Node): esbuild max minify + QuickJS-NG (~1 MB JS engine) + UPX-LZMA + FROM scratch
FROM node:20 AS build
WORKDIR /app
COPY package.json tsconfig.json ./
RUN npm install --silent --no-audit --no-fund
COPY src ./src
RUN npm run build

FROM debian:12-slim AS qjs-fetch
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl unzip xz-utils build-essential cmake git upx-ucl \
    && rm -rf /var/lib/apt/lists/*
# Build QuickJS-NG from source — small enough to compile in <1 min on Linux
RUN git clone --depth 1 https://github.com/quickjs-ng/quickjs.git /tmp/qjs \
 && cd /tmp/qjs \
 && cmake -B build -DCMAKE_BUILD_TYPE=MinSizeRel -DBUILD_QJS_LIBC=ON \
 && cmake --build build -j --target qjs \
 && strip /tmp/qjs/build/qjs \
 && upx --best --lzma /tmp/qjs/build/qjs \
 && cp /tmp/qjs/build/qjs /qjs

FROM scratch
COPY --from=qjs-fetch /qjs /qjs
COPY --from=build /app/dist/app.mjs /app.mjs
ENTRYPOINT ["/qjs", "/app.mjs"]
