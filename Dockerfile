# Stage 1: Build stage
FROM python:3.12-slim-bookworm as builder

ENV PATH="/root/.local/bin/:$PATH" \
    VIRTUAL_ENV=/venv \
    UV_PROJECT_ENVIRONMENT=/venv \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    git && \
    curl -LsSf https://astral.sh/uv/install.sh | sh && \
    /root/.local/bin/uv tool install ruff && \
    /root/.local/bin/uv venv /venv && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy dependency files
COPY pyproject.toml uv.lock ./

# Install production dependencies only
RUN uv pip install --production

# Copy the application code
COPY . .

# Run any build steps (example: collecting static files for Django)
RUN python manage.py collectstatic --noinput

# Stage 2: Production stage
FROM python:3.12-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    VIRTUAL_ENV=/venv \
    PATH="/venv/bin:$PATH"

WORKDIR /app

# Install runtime dependencies only
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    postgresql-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy virtual environment and application from builder
COPY --from=builder /venv /venv
COPY --from=builder /app /app

# Create and switch to non-root user
RUN useradd -m -s /bin/bash app && \
    chown -R app:app /app /venv

USER app

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health/ || exit 1

# Command to run the production server (example using gunicorn)
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "myapp.wsgi:application"]