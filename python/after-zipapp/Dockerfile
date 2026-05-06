# Python zipapp — tiny artifact but still needs Python runtime base
FROM python:3.11-slim AS build
WORKDIR /app
COPY app.py __main__.py ./
RUN mkdir build && cp app.py __main__.py build/ \
 && python -m zipapp build/ -o app.pyz -p "/usr/bin/env python3"

FROM python:3.11-alpine
COPY --from=build /app/app.pyz /app.pyz
ENTRYPOINT ["python", "/app.pyz"]
