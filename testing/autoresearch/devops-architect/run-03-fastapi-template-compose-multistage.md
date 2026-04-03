# Run 03: fastapi-template — compose.yml, Multi-Stage Docker Build

## Source Files
- `/home/intruder/projects/fastapi-template/scripts/production_with_nginx/Dockerfile`
- `/home/intruder/projects/fastapi-template/scripts/production_with_nginx/docker-compose.yml`
- `/home/intruder/projects/fastapi-template/scripts/local_with_uvicorn/Dockerfile`

## Findings

### Dockerfile (Production with Nginx)

**Build stage (`python:3.11 as requirements-stage`)**
- ISSUE: Uses Poetry in build stage, but `pip install poetry` without pinning version.
- ISSUE: Python 3.11, not 3.12 — outdated.
- OK: Multi-stage build pattern (requirements export then pip install).
- ISSUE: Uses `pip install` not `uv` — but this is a different project's choice.

**Runtime stage (`python:3.11`)**
- ISSUE: Uses full `python:3.11` image, not `python:3.11-slim`. Much larger attack surface.
- ISSUE: No non-root user created. Container runs as root.
- ISSUE: No apt-get cleanup (no system packages installed, but base image is full).
- ISSUE: CMD uses `--reload` flag — this is a DEV flag in production Dockerfile.
- OK: Alternative gunicorn command is commented out (but the default is uvicorn with reload).

### docker-compose.yml (Production with Nginx)

**Good patterns:**
- Service separation: web, worker, db, redis, nginx.
- DB and Redis use `expose` instead of `ports` — internal only (good security).
- Nginx handles external traffic on port 80 only.
- Worker service (arq) is separate from web — proper async task handling.
- env_file used consistently.

**Issues:**
- ISSUE: `image: redis:alpine` — uses `latest` tag (no version pinned). Agent anti-pattern.
- ISSUE: `image: nginx:latest` — same problem, latest tag.
- ISSUE: `image: postgres:13` — Postgres 13 is EOL (November 2025). Should be 15+.
- ISSUE: No health checks on any service.
- ISSUE: No restart policies on any service.
- ISSUE: Volume mounts `./src/app:/code/app` in production compose — code should be baked into image.
- ISSUE: No resource limits defined.
- MISSING: No network isolation.

**Interesting patterns not in clinic-portal:**
- Separate worker service for background tasks.
- Commented-out `pytest` service for running tests in Docker.
- Commented-out `create_superuser` service for init tasks.
- Nginx reverse proxy pattern for production.

## Comparison: fastapi-template compose vs clinic-portal compose

| Pattern | fastapi-template | clinic-portal | Gap |
|---|---|---|---|
| Reverse proxy (nginx) | YES | NO | clinic-portal needs this for production |
| Worker service | YES (arq) | NO (uses Lambda) | Different architecture, OK |
| DB port exposure | `expose` only | `ports` (exposed) | clinic-portal exposes DB |
| Redis port exposure | `expose` only | `ports` (exposed) | clinic-portal exposes Redis |
| Health checks | NO | NO | Both need this |
| Version pinning | PARTIAL | PARTIAL | Both have gaps |
| Init service pattern | YES (commented) | NO | clinic-portal runs migrations inline |

## Gaps Identified for Agent Prompt
1. **Reverse proxy pattern**: Agent should recommend nginx/traefik for production deployments.
2. **Dev vs prod CMD flags**: Agent should flag `--reload` in production Dockerfiles.
3. **Base image selection**: Agent should recommend `-slim` variants and flag full images.
4. **EOL version detection**: Agent should check if database/runtime versions are still supported.
5. **Init service pattern**: Agent should recommend separate init/migration services instead of inline commands.
6. **Volume mount in production**: Agent should flag source code volume mounts in production compose files.
