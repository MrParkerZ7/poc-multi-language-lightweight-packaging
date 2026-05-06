# Go strip + UPX — FROM scratch (~2 MB image)
FROM golang:1.21-alpine AS build
WORKDIR /app
RUN apk add --no-cache upx
COPY go.mod go.sum ./
RUN go mod download
COPY main.go .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -trimpath -o app . \
 && upx --best --lzma app

FROM scratch
COPY --from=build /app/app /app
ENTRYPOINT ["/app"]
