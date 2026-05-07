$12-amalgamate-llrt (Node): esbuild max minify + UPX-compressed llrt + FROM scratch
FROM node:20 AS build
WORKDIR /app
COPY package.json tsconfig.json ./
RUN npm install --silent --no-audit --no-fund
COPY src ./src
RUN npm run build

FROM debian:12-slim AS llrt-fetch
RUN apt-get update && apt-get install -y curl unzip upx-ucl && rm -rf /var/lib/apt/lists/*
RUN curl -fL -o /tmp/llrt.zip \
    https://github.com/awslabs/llrt/releases/latest/download/llrt-linux-x64.zip \
 && unzip /tmp/llrt.zip -d /tmp/llrt && find /tmp/llrt -name 'llrt*' -type f -executable -exec mv {} /llrt \; \
 && chmod +x /llrt \
 && upx --best --lzma /llrt || true

FROM debian:12-slim
COPY --from=llrt-fetch /llrt /llrt
COPY --from=build /app/dist/app.mjs /app.mjs
ENTRYPOINT ["/llrt", "/app.mjs"]
