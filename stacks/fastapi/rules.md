# FastAPI Stack Rules

## API
1. Pydantic v2 models for ALL request/response schemas
2. Use `APIRouter` for route organization — group by domain
3. Dependency injection for auth, DB sessions, and config
4. Use `HTTPException` with proper status codes — NEVER return raw dicts for errors

## Database
5. SQLAlchemy 2.0+ with async sessions (if async)
6. Alembic for ALL migrations — NEVER modify DB directly
7. Use `sessionmaker` with `expire_on_commit=False` for async

## Testing
8. Run tests: `docker compose exec web pytest -v`
9. Use `httpx.AsyncClient` for async test client — NEVER `TestClient` in async tests
10. Use `pytest-asyncio` for async test functions

## Infrastructure
11. Use `uvicorn` with `--reload` for development
12. Use `gunicorn` with `uvicorn.workers.UvicornWorker` for production
