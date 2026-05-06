# Node bun --compile — single binary, bun runtime bundled (~60 MB image)
FROM oven/bun:1 AS build
WORKDIR /app
COPY package.json tsconfig.json ./
RUN bun install --silent
COPY src ./src
RUN bun build --compile --minify --target=bun-linux-x64 --outfile=app src/main.ts

FROM debian:12-slim
COPY --from=build /app/app /app
ENTRYPOINT ["/app"]
