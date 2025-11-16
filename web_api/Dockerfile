# Multi-stage Dockerfile for OptiVolt Web API
# Supports 3 variants: standard, microvm, minimal

FROM python:3.12-slim AS base

WORKDIR /app

# Install uv for fast dependency management
RUN pip install --no-cache-dir uv

# Copy dependency files
COPY pyproject.toml uv.lock ./

# Install dependencies
RUN uv pip install --system --no-cache .

# Copy application code
COPY app/ ./app/

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000').read()" || exit 1

# Default command
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]


# ============================================
# VARIANT 1: Standard (Full features)
# ============================================
FROM base AS standard

# Add logging and monitoring tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

ENV VARIANT=standard
ENV LOG_LEVEL=info
ENV WORKERS=4

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]


# ============================================
# VARIANT 2: MicroVM (Optimized for Firecracker)
# ============================================
FROM base AS microvm

# Minimal tools for microVM
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

ENV VARIANT=microvm
ENV LOG_LEVEL=warning
ENV WORKERS=2

# Single worker for microVM
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2", "--access-log"]


# ============================================
# VARIANT 3: Minimal (Ultra-light)
# ============================================
FROM python:3.12-alpine AS minimal

WORKDIR /app

# Install uv
RUN pip install --no-cache-dir uv

# Copy files
COPY pyproject.toml uv.lock ./
RUN uv pip install --system --no-cache .

COPY app/ ./app/

ENV VARIANT=minimal
ENV LOG_LEVEL=error
ENV WORKERS=1

EXPOSE 8000

# Minimal healthcheck
HEALTHCHECK --interval=60s --timeout=5s --start-period=10s --retries=2 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8000/ || exit 1

# Single worker, no access log
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "1", "--no-access-log"]
