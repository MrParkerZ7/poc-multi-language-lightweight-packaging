# Go TinyGo — alternative compiler, very small (~0.6 MB image)
FROM tinygo/tinygo:0.31.2 AS build
WORKDIR /app
COPY go.mod go.sum ./
COPY main.go .
RUN tinygo build -o app -opt=z -target=linux .

FROM scratch
COPY --from=build /app/app /app
ENTRYPOINT ["/app"]
