# FastAPI Agent Routing

| Domain | Files | Agent | context7 Libraries |
|---|---|---|---|
| Routes & schemas | `app/routers/*.py`, `app/schemas/*.py` | @backend-architect | fastapi, pydantic |
| Models & DB | `app/models/*.py`, `alembic/**` | @backend-architect | sqlalchemy, alembic |
| Auth & middleware | `app/auth/*.py`, `app/middleware/*.py` | @backend-architect | fastapi, python-jose |
| Services | `app/services/*.py` | @backend-architect | -- |
| Tests | `tests/**` | @quality-engineer | pytest, httpx |
| Docker & deploy | `Dockerfile`, `docker-compose.yml` | @devops-architect | -- |
| Frontend (if any) | `static/**`, `templates/**` | /sc:implement | jinja2 |
