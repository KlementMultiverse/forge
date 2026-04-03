# Run 09: clinic-portal — Production Readiness (Health Checks, Graceful Shutdown)

## Source Files
- `/home/intruder/projects/clinic-portal/Dockerfile`
- `/home/intruder/projects/clinic-portal/docker-compose.yml`
- `/home/intruder/projects/clinic-portal/config/settings.py`
- `/home/intruder/projects/clinic-portal/pyproject.toml`

## Findings

### Health Checks — NONE EXIST

**No Docker health checks:**
- Dockerfile has no `HEALTHCHECK` instruction.
- docker-compose.yml has no `healthcheck` on any service.
- No `/health/` or `/api/health/` endpoint in the Django app (checked urls.py and api.py files).

**Impact:**
- Container orchestrators (ECS, Kubernetes, Railway) cannot determine if the app is healthy.
- `depends_on` in compose doesn't wait for app readiness — only container start.
- No way to detect deadlocked workers, database connection loss, or Redis failures.

**Recommended health check endpoint should verify:**
1. Database connectivity (simple query)
2. Redis connectivity (ping)
3. Application ready (migrations complete)

### Graceful Shutdown — NOT CONFIGURED

**Dockerfile CMD:**
```dockerfile
RUN chmod +x railway_start.sh
CMD ["./railway_start.sh"]
```
- `railway_start.sh` does not exist in the repo — build will fail.
- No graceful shutdown configuration.
- No `STOPSIGNAL` instruction.

**docker-compose.yml:**
- Uses `sh -c "... runserver 0.0.0.0:8000"` — Django dev server.
- Django dev server does not handle SIGTERM gracefully.
- No `stop_grace_period` configured (defaults to 10s).

**Production server (gunicorn):**
- `gunicorn>=25.3.0` is in pyproject.toml — installed but not used in any config.
- No gunicorn configuration file.
- No `--timeout`, `--graceful-timeout`, `--workers` configuration.

### Production Configuration Gaps

| Concern | Status | Notes |
|---|---|---|
| Health check endpoint | MISSING | No /health/ route |
| HEALTHCHECK in Dockerfile | MISSING | No instruction |
| Health checks in compose | MISSING | No healthcheck config |
| Graceful shutdown signal | MISSING | No STOPSIGNAL, no stop_grace_period |
| Production server (gunicorn) | INSTALLED, NOT USED | gunicorn in deps but not in CMD |
| Gunicorn config | MISSING | No gunicorn.conf.py |
| Static file serving | PARTIAL | whitenoise in middleware but STATIC_ROOT needs collectstatic |
| Logging configuration | MISSING | No LOGGING dict in settings.py |
| Error monitoring (Sentry) | MISSING | No Sentry/error tracking integration |
| Rate limiting | MISSING | No rate limiting middleware |
| CORS configuration | MISSING | No CORS middleware |
| Database connection pooling | MISSING | No pgbouncer or Django CONN_MAX_AGE |
| SSL/TLS termination | MISSING | No nginx/traefik, no SECURE_SSL_REDIRECT |

### Broken References
- `railway_start.sh` is referenced in Dockerfile but does not exist.
- This means `docker build` will fail at `RUN chmod +x railway_start.sh` if the file isn't present.

### Security Settings Review
- `SECRET_KEY` env var name mismatch (settings reads `SECRET_KEY`, .env sets `DJANGO_SECRET_KEY`).
- `DEBUG` defaults to False — good.
- `SECURE_CONTENT_TYPE_NOSNIFF = True` — good.
- `X_FRAME_OPTIONS = "DENY"` — good.
- `SESSION_COOKIE_HTTPONLY = True` — good.
- `SESSION_COOKIE_SECURE = not DEBUG` — good (True in production).
- MISSING: `SECURE_SSL_REDIRECT`, `SECURE_HSTS_SECONDS`, `SECURE_HSTS_INCLUDE_SUBDOMAINS`.

## Gaps Identified for Agent Prompt
1. **Health check endpoints**: Agent should verify a health check endpoint exists and checks all critical dependencies (DB, Redis, external services).
2. **Graceful shutdown**: Agent should verify STOPSIGNAL, stop_grace_period, and that the application server handles SIGTERM.
3. **Production server verification**: Agent should check that the production CMD uses gunicorn/uvicorn, not Django runserver.
4. **Broken file references**: Agent should verify all files referenced in Dockerfile actually exist.
5. **Logging configuration**: Agent should check for structured logging configuration in settings.
6. **Database connection pooling**: Agent should recommend CONN_MAX_AGE or pgbouncer for production.
7. **SSL/TLS settings**: Agent should verify Django security middleware settings for production (HSTS, SSL redirect).
8. **Error monitoring**: Agent should recommend Sentry or similar for production error tracking.
9. **CORS**: Agent should check if CORS is needed and configured.
10. **Rate limiting**: Agent should recommend rate limiting for public-facing APIs.
