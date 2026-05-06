# C# Native AOT — single binary, alpine-base (~12-15 MB image)
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app
RUN apt-get update && apt-get install -y clang zlib1g-dev && rm -rf /var/lib/apt/lists/*
COPY app.csproj .
COPY Program.cs .
RUN dotnet publish -c Release -r linux-x64 -o /publish

FROM mcr.microsoft.com/dotnet/runtime-deps:8.0-alpine
COPY --from=build /publish/app /app
ENTRYPOINT ["/app"]
