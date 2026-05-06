# C# ReadyToRun precompiled (faster cold-start, slightly larger artifact)
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app
COPY app.csproj .
COPY Program.cs .
RUN dotnet publish -c Release -r linux-x64 --self-contained -o /publish \
    -p:PublishReadyToRun=true \
    -p:PublishReadyToRunComposite=true \
    -p:PublishSingleFile=true

FROM mcr.microsoft.com/dotnet/runtime-deps:8.0-alpine
COPY --from=build /publish/app /app
ENTRYPOINT ["/app"]
