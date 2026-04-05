---
description: Docker development rules. Only loads when Docker files are present.
paths: ["Dockerfile", "docker-compose.yml", "docker-compose*.yml", ".dockerignore"]
---

# Docker Rules

1. docker-compose.yml MUST have volume mount for live code reload in development:
   ```yaml
   volumes:
     - .:/app
     - /app/.venv  # exclude container venv from host mount
   ```
2. Development command MUST use runserver, NOT gunicorn:
   ```yaml
   command: uv run python manage.py runserver 0.0.0.0:8000
   ```
3. Tests MUST run inside Docker: `docker compose exec web uv run python manage.py test`
4. Local .venv is for IDE autocomplete ONLY — all execution happens in Docker
5. NEVER run `uv sync` on host during scaffold — Docker build handles dependencies
6. Dockerfile uses multi-stage (builder + runtime) — production uses gunicorn
7. docker-compose.yml is for DEVELOPMENT — Dockerfile CMD is for PRODUCTION
8. Add `.venv/` and `__pycache__/` to .dockerignore to keep builds fast
