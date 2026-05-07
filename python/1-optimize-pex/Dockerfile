# Python PEX — single .pex file, still needs Python runtime base
FROM python:3.11-slim AS build
WORKDIR /app
RUN pip install --no-cache-dir pex
COPY app.py .
RUN pex --output-file=app.pex --sources-directory=. --entry-point=app:main

FROM python:3.11-alpine
COPY --from=build /app/app.pex /app.pex
ENTRYPOINT ["python", "/app.pex"]
