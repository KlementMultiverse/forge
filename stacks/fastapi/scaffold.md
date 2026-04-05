# FastAPI Scaffold Instructions

Generate these files for a new FastAPI project:

## Required Files
- `pyproject.toml` — fastapi, uvicorn, sqlalchemy, alembic, pytest, httpx
- `app/main.py` — FastAPI app with CORS, routers, health endpoint
- `app/config.py` — settings from env via pydantic-settings
- `app/database.py` — SQLAlchemy engine + session
- `alembic.ini` + `alembic/` — migration setup
- `Dockerfile` — multi-stage (builder with uv + runtime with gunicorn+uvicorn)
- `docker-compose.yml` — DEVELOPMENT config with:
  - PostgreSQL 16 with healthcheck
  - Redis (if needed)
  - Web service with volume mount (`.:/app`, `/app/.venv` excluded)
  - `command: uv run uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload`
- `.dockerignore` — .venv, __pycache__, .git
- `.env.example`
- `.gitignore`
- `tests/conftest.py` — fixtures for async client, test DB
