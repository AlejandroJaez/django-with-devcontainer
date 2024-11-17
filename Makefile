.PHONY: setup-dev dev-sync format lint test

setup-dev:
	uv venv /venv
	uv pip install --editable ".[dev]"
	pre-commit install

dev-sync:
	uv sync

format:
	ruff format .

lint:
	ruff check . --fix

test:
	pytest

clean:
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	find . -type f -name "*.pyo" -delete
	find . -type f -name "*.pyd" -delete
	find . -type f -name ".coverage" -delete
	find . -type d -name "*.egg-info" -exec rm -rf {} +
	find . -type d -name "*.egg" -exec rm -rf {} +
	find . -type d -name ".pytest_cache" -exec rm -rf {} +
	find . -type d -name ".ruff_cache" -exec rm -rf {} +