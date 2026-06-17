# ---- build stage ----
FROM python:3.12-slim AS builder
WORKDIR /install
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install/deps -r requirements.txt

# ---- runtime stage ----
FROM python:3.12-slim AS runtime
ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1
# Run as a non-root user for security.
RUN useradd --create-home --uid 10001 appuser
WORKDIR /app
COPY --from=builder /install/deps /usr/local
COPY app ./app
USER appuser
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')"
CMD ["uvicorn", "app.api.main:app", "--host", "0.0.0.0", "--port", "8080"]
