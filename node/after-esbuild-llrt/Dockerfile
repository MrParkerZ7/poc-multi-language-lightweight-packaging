# Node esbuild + AWS llrt — no Node runtime, just llrt binary + bundle (~12 MB image)
FROM node:20 AS build
WORKDIR /app
COPY package.json tsconfig.json ./
RUN npm install --silent --no-audit --no-fund
COPY src ./src
RUN npm run build

FROM debian:12-slim AS llrt-fetch
RUN apt-get update && apt-get install -y curl unzip && rm -rf /var/lib/apt/lists/*
RUN curl -fL -o /tmp/llrt.zip \
    https://github.com/awslabs/llrt/releases/latest/download/llrt-linux-x64.zip \
 && unzip /tmp/llrt.zip -d /tmp/llrt && find /tmp/llrt -name 'llrt*' -type f -executable -exec mv {} /llrt \; \
 && chmod +x /llrt

FROM debian:12-slim
COPY --from=llrt-fetch /llrt /llrt
COPY --from=build /app/dist/app.mjs /app.mjs
ENTRYPOINT ["/llrt", "/app.mjs"]
