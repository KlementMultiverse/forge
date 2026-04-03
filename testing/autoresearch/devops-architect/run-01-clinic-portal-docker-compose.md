# Run 01: clinic-portal — docker-compose.yml Review

## Source Files
- `/home/intruder/projects/clinic-portal/docker-compose.yml`
- `/home/intruder/projects/clinic-portal/Dockerfile`

## Findings

### Services Analysis

**db (postgres:15)**
- ISSUE: No health check defined. The `web` service depends_on `db` but without a health check, Django may attempt migrations before PostgreSQL is ready.
- ISSUE: Hardcoded credentials in environment (`POSTGRES_PASSWORD: postgres`). Should use env_file or Docker secrets.
- ISSUE: Port 5433:5432 exposed to host in all profiles — production should not expose DB ports (agent anti-pattern rule).
- OK: Named volume `pgdata` for data persistence.
- MISSING: No resource limits (memory, CPU).

**redis (redis:7-alpine)**
- ISSUE: No health check defined.
- ISSUE: Port 6379:6379 exposed to host — should use `expose` instead of `ports` for production.
- ISSUE: No persistence configured (no volume, no appendonly).
- MISSING: No password configured — Redis is open to any connection on the network.
- MISSING: No resource limits.

**web (Django)**
- ISSUE: `command` runs migrations inline on every container start. Migrations should be a separate init container or entrypoint script with idempotency check, not blocking the main process.
- ISSUE: Volume mount `.:/app` is a development pattern only — acceptable for dev but the compose file has no profile separation for dev vs production.
- ISSUE: No health check defined for the web service.
- ISSUE: No restart policy (`restart: unless-stopped` or `on-failure`).
- ISSUE: Running `runserver` (Django dev server) — production must use gunicorn.
- OK: Uses `env_file: .env` instead of inline secrets.
- OK: `depends_on` is correctly set.

### Networking
- ISSUE: No custom network defined. All services share the default bridge network, which is fine for dev but should be explicit.
- ISSUE: No network isolation between services (DB shouldn't be accessible from outside the compose network).

### Volumes
- OK: `pgdata` named volume for PostgreSQL persistence.
- MISSING: No Redis volume for data persistence.
- MISSING: No volume for static files in production.

### What the Agent Prompt Covers vs Misses

| Concern | Covered by Prompt? | Notes |
|---|---|---|
| Validate compose with `docker compose config` | YES | Step 4 in Forge Cell Compliance |
| No secrets in config | YES | Anti-pattern rule |
| No `latest` tags | YES | Anti-pattern rule — but not checked against `ghcr.io/astral-sh/uv:latest` in Dockerfile |
| No exposed DB ports in production | YES | Anti-pattern rule |
| Health checks | NO | Not mentioned anywhere in the prompt |
| Restart policies | NO | Not mentioned |
| Dev vs production profile separation | NO | Not mentioned |
| Migration strategy (init container vs inline) | NO | Not mentioned |
| Redis security (password, persistence) | NO | Not mentioned |
| Resource limits | NO | Not mentioned |
| Graceful shutdown | NO | Not mentioned |
| Log driver configuration | NO | Not mentioned |
| Network isolation | NO | Not mentioned |

## Gaps Identified for Agent Prompt
1. **Health checks**: Agent should verify health checks exist for all services (postgres `pg_isready`, redis `redis-cli ping`, web HTTP endpoint).
2. **Restart policies**: Agent should verify restart policies are set.
3. **Dev/prod separation**: Agent should check for Docker Compose profiles or separate files.
4. **Migration strategy**: Agent should flag inline migrations in CMD/command.
5. **Service security**: Agent should check Redis auth, DB port exposure.
6. **Resource limits**: Agent should recommend `deploy.resources.limits` for production.
7. **Graceful shutdown**: Agent should verify `stop_grace_period` and SIGTERM handling.
