# Stage 1: Build stage
FROM python:3.12-slim-bookworm AS builder

# Consolidate ENV variables to reduce layers
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/root/.local/bin:/venv/bin:$PATH" \
    VIRTUAL_ENV=/venv \
    UV_PROJECT_ENVIRONMENT=/venv

WORKDIR /app

# Combine package installation and cleanup in single layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    git && \
    curl -LsSf https://astral.sh/uv/install.sh | sh && \
    uv tool install ruff && \
    uv venv /venv && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy only dependency files first to leverage cache
COPY --chown=root:root pyproject.toml uv.lock ./

# Install dependencies
RUN uv sync --no-group dev

# Copy application code
COPY --chown=root:root . .

# Run build steps
RUN uv run manage.py collectstatic --noinput

# Stage 2: Production stage
FROM python:3.12-slim-bookworm

# Consolidate ENV variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    VIRTUAL_ENV=/venv \
    PATH="/venv/bin:$PATH" \
    USER=app \
    UID=10001

WORKDIR /app

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    postgresql-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    # Create non-root user with specific UID
    adduser --disabled-password --gecos "" --uid ${UID} ${USER} && \
    chown -R ${USER}:${USER} /app

# Copy virtual environment and application from builder
COPY --from=builder --chown=${USER}:${USER} /venv /venv
COPY --from=builder --chown=${USER}:${USER} /app /app

USER ${USER}

# Health check with timeout adjustment
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/ || exit 1

# Set recommended environment variables for gunicorn
ENV GUNICORN_CMD_ARGS="--bind=0.0.0.0:8000 --workers=4 --worker-class=gthread --threads=4 --worker-tmp-dir=/dev/shm --access-logfile=- --error-logfile=- --capture-output --enable-stdio-inheritance"

# Command to run the production server
CMD ["gunicorn", "myapp.wsgi:application"]