# Smart Inbox AI — Backend

FastAPI backend service for Smart Inbox AI.

## Quickstart

```bash
# Setup virtualenv and dependencies
uv venv --python 3.11 .venv
source .venv/bin/activate
uv pip install -e ".[dev]"

# Run dev server
uvicorn app.main:app --reload --port 8000

# Run linter
ruff check .

# Run tests
pytest -v
```

## Endpoints

- `GET /health` — Health check
- `GET /v1/health` — V1 Health check
- `GET /api/v1/health` — API V1 Health check
- `GET /docs` — Swagger UI API documentation
