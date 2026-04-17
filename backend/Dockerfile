FROM python:3.12-slim AS builder

WORKDIR /build
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libpq-dev gcc && rm -rf /var/lib/apt/lists/*

COPY backend/requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.12-slim AS runtime

RUN groupadd -r imc && useradd -r -g imc -d /app -s /sbin/nologin imc
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 curl && rm -rf /var/lib/apt/lists/*

COPY --from=builder /install /usr/local
COPY backend/app ./app
COPY backend/migrations ./migrations
COPY backend/alembic.ini .

RUN chown -R imc:imc /app && chmod -R 550 /app
USER imc

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

EXPOSE 8000

CMD ["uvicorn", "app.main:app", \
     "--host", "0.0.0.0", \
     "--port", "8000", \
     "--workers", "4", \
     "--log-config", "/dev/null"]
