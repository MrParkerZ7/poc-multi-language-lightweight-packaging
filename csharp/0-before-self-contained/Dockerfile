# C# self-contained — runtime-deps base (~80 MB image)
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app
COPY app.csproj .
COPY Program.cs .
RUN dotnet publish -c Release -r linux-x64 --self-contained -o /publish \
    -p:PublishSingleFile=true \
    -p:IncludeNativeLibrariesForSelfExtract=true

FROM mcr.microsoft.com/dotnet/runtime-deps:8.0-alpine
COPY --from=build /publish/app /app
ENTRYPOINT ["/app"]
