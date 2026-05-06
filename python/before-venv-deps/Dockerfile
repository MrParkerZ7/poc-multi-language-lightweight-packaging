# Python venv + deps — naive deploy, full Python base (~150 MB image)
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
ENTRYPOINT ["python", "app.py"]
