# build stage: install deps into an isolated prefix
FROM python:3.12-slim AS builder

WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# runtime stage: copy only what we need
FROM python:3.12-slim

# run as non-root
RUN useradd --create-home --uid 1001 appuser
USER appuser

WORKDIR /app
COPY --from=builder /install /usr/local
COPY main.py .

# Cloud Run injects PORT (default 8080)
ENV PORT=8080
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT}"]
