# Go default build — FROM scratch (~10 MB image)
FROM golang:1.21-alpine AS build
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY main.go .
RUN CGO_ENABLED=0 go build -o app .

FROM scratch
COPY --from=build /app/app /app
ENTRYPOINT ["/app"]
