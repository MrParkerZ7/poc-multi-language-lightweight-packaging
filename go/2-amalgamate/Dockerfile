# 2-amalgamate (Go): TinyGo + opt=z + UPX + FROM scratch
FROM tinygo/tinygo:0.31.2 AS build
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends upx-ucl && rm -rf /var/lib/apt/lists/*
COPY go.mod go.sum ./
COPY main.go .
RUN tinygo build -o app -opt=z -no-debug -target=linux .
RUN upx --best --lzma app

FROM scratch
COPY --from=build /app/app /app
ENTRYPOINT ["/app"]
