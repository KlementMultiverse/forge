# Django Scaffold Instructions

Generate these files for a new Django project:

## Required Files
- `pyproject.toml` — all deps, uv managed
- `manage.py` — standard Django manage
- `config/settings.py` — full settings with DATABASE from env
- `config/urls.py` — root URL conf
- `config/wsgi.py` — WSGI application
- `apps/__init__.py` — apps package
- `Dockerfile` — multi-stage (builder with uv + runtime with gunicorn)
- `docker-compose.yml` — DEVELOPMENT config with:
  - PostgreSQL 16 with healthcheck
  - Redis (if caching/sessions needed)
  - Web service with volume mount (`.:/app`, `/app/.venv` excluded)
  - `command: uv run python manage.py runserver 0.0.0.0:8000`
- `.dockerignore` — .venv, __pycache__, .git, *.pyc, node_modules
- `.env.example` — all env vars with placeholder values
- `.gitignore` — .venv, __pycache__, .env, db.sqlite3, *.pyc, staticfiles/

## Do NOT
- Run `uv sync` on host
- Use gunicorn in docker-compose (that's for production Dockerfile CMD)
- Create a local .venv
- Include React/Vue/Angular
