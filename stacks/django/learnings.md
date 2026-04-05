# Django Stack Learnings

<!-- Updated by /retro after each build. Each entry prevents a real past mistake. -->

## From clinical_assistant (2026-04-03)
- Parallel test agents corrupt shared test DB — serialize test execution, never run manage.py test in parallel
- `logger.info(..., extra={"filename": ...})` conflicts with Python LogRecord.filename — use `export_filename` instead
- Rate limiter TOCTOU: `cache.get()` then `cache.incr()` race condition — check `current is None` separately, use `cache.set()` for new keys
- AuditLog.save() must raise error if pk exists — immutable records
- TenantMainMiddleware MUST be position 0 — other middleware depends on tenant being set

## From forge-ops (2026-04-04)
- docker-compose.yml scaffold missing volume mount for live reload — always include `.:/app` with `/app/.venv` excluded
- Builder ran `uv sync` on host creating 4600+ .venv files — Docker build handles deps, not host
- Never dump all tests into one tests.py file — split by domain (tests_models.py, tests_api.py, etc.) to stay under 300 lines per file
- N+1 on queryset iteration: use `.update()` for bulk field changes instead of looping `.save()` on individual instances
- Django Ninja router imports don't depend on NinjaAPI instance — import at top of urls.py, create api after imports
- Use `grep -F` in traceability scripts — REQ IDs with brackets break regex grep
