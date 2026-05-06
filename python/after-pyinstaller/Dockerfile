# Python PyInstaller — bundles stripped Python, no runtime base needed (~12 MB image)
FROM python:3.11-slim AS build
WORKDIR /app
RUN pip install --no-cache-dir pyinstaller
COPY app.py .
RUN pyinstaller --onefile --strip --noconfirm --name app app.py

FROM debian:12-slim
COPY --from=build /app/dist/app /app
ENTRYPOINT ["/app"]
