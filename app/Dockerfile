FROM python:3.12-slim AS builder
WORKDIR /build
RUN apt-get update && apt-get install -y --no install-recommends \
build-essential libpq-dev && rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
RUN pip install wheel --no-cache-dir --wheel-dir /build/wheels -r requirements.txt

FROM python:3.12-slim AS runner
WORKDIR /workspace
ARG SERVICE_NAME
RUN apt-get update && apt-get install --no-recommends -y \
libpq5 && rm -rf /var/lib/apt/lists/*
COPY --from=builder /build/wheels /wheels
RUN pip install --no-cache-dir /wheels/* && rm -rf /wheels
RUN groupadd -g 10001 approup && useradd -u 10001 -g appgroup -m appuser
USER 10001
EXPOSE 8000
COPY --chown=appgroup:appuser shared ./shared
COPY --chown=appgroup:appuser services/${SERVICE_NAME} ./app
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTE=1 \
    PYTHONPATH=/workspace \
    OTEL_SERVICE_NAME=${SERVICE_NAME}
    ENTRYPOINT ["opentelemetry-instrument", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
