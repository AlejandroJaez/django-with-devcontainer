# Streamline Your Django Development with VS Code Dev Containers

Developing Django applications in a consistent and reproducible environment can be a challenge, especially when working across different machines or teams. VS Code Dev Containers provide a powerful solution by encapsulating your development environment inside a Docker container, ensuring that every developer works with the same dependencies, tools, and configurations.

In this blog post, we'll walk through setting up a VS Code Dev Container for Django development using a `devcontainer.json` configuration and a `Dockerfile.dev`.

## Why Use VS Code Dev Containers?

With Dev Containers, you can:
- Avoid dependency conflicts by isolating your development environment.
- Standardize your tooling across different machines.
- Easily onboard new team members without the hassle of environment setup.
- Leverage VS Code’s powerful remote development features.

## Setting Up Your Dev Container

### 1. Creating the `devcontainer.json`

The `devcontainer.json` file is the heart of the VS Code Dev Container configuration. Here's what our configuration looks like:

```json
{
  "name": "Django Development",
  "build": {
    "dockerfile": "../Dockerfile.dev"
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "ms-azuretools.vscode-docker",
        "charliermarsh.ruff"
      ],
      "settings": {
        "python.defaultInterpreterPath": "/venv/bin/python",
        "python.formatting.provider": "ruff",
        "editor.formatOnSave": true
      }
    }
  }
}
```

This configuration:
- Specifies the development container name.
- Uses a Dockerfile (`Dockerfile.dev`) to define the container environment.
- Installs necessary VS Code extensions for Python and Docker support.
- Configures the Python environment and formatting tool (`ruff`).

### 2. Creating the `Dockerfile.dev`

To define our Django development environment, we use the following `Dockerfile.dev`:

```dockerfile
FROM python:3.12-slim-bookworm

# Set environment variables
ENV PATH="/root/.local/bin/:$PATH" \
    VIRTUAL_ENV=/venv \
    UV_PROJECT_ENVIRONMENT=/venv \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install development dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    git \
    make \
    gcc \
    postgresql-client && \
    curl -LsSf https://astral.sh/uv/install.sh | sh && \
    /root/.local/bin/uv tool install ruff && \
    /root/.local/bin/uv venv /venv && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy dependency files
COPY pyproject.toml uv.lock ./

# Install dependencies including development packages
RUN uv pip install --editable ".[dev]"

# Mount the application code as a volume
VOLUME ["/app"]

# Command to run the development server
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
```

This Dockerfile:
- Uses Python 3.12 as the base image.
- Sets up a virtual environment (`/venv`).
- Installs necessary system dependencies such as `git`, `gcc`, and `postgresql-client`.
- Uses `uv` to manage dependencies and install `ruff` for code formatting.
- Copies `pyproject.toml` and `uv.lock` for dependency installation.
- Defines a command to run the Django development server.

## Running the Dev Container

To start using the development container:

1. Open your project in VS Code.
2. Ensure you have the **Dev Containers** extension installed.
3. Click on the **Remote Explorer** in the activity bar and select **Open Folder in Container**.
4. VS Code will build the container and start your development environment.

## Conclusion

Using VS Code Dev Containers simplifies Django development by creating a reproducible, standardized environment. Whether you are working solo or in a team, this approach ensures consistency and ease of setup. Try integrating Dev Containers into your workflow and experience seamless development!

Do you use Dev Containers in your projects? Let us know your thoughts in the comments!

