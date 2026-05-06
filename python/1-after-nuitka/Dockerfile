# Python Nuitka — compiled to C, smaller and faster than PyInstaller
FROM python:3.11-slim AS build
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends gcc patchelf \
    && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir nuitka
COPY app.py .
RUN python -m nuitka --onefile --output-dir=dist --remove-output \
    --assume-yes-for-downloads app.py

FROM debian:12-slim
COPY --from=build /app/dist/app.bin /app
ENTRYPOINT ["/app"]
