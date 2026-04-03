# Run 02: saleor — deployment/ Directory Analysis, Dockerfile Patterns

## Source Files
- `/home/intruder/projects/saleor/Dockerfile`
- `/home/intruder/projects/saleor/deployment/elasticbeanstalk/Dockerrun.aws.json`
- `/home/intruder/projects/saleor/.devcontainer/docker-compose.yml`

## Findings

### Dockerfile Analysis (Multi-Stage Build — Exemplary)

**Build stage (`python:3.12 AS build-python`)**
- Excellent: Multi-stage build separates build dependencies from runtime.
- Excellent: Uses `--mount=type=cache,target=/root/.cache/uv` for build cache.
- Excellent: Uses `--mount=type=bind` for lock files — never copies them into the build layer.
- Excellent: Pins uv version with full SHA digest: `ghcr.io/astral-sh/uv:0.10.8@sha256:...`.
- Excellent: `UV_COMPILE_BYTECODE=1` for faster startup.
- Excellent: `UV_SYSTEM_PYTHON=1` avoids venv overhead in container.

**Runtime stage (`python:3.12-slim`)**
- Excellent: Non-root user created (`groupadd -r saleor && useradd -r -g saleor saleor`).
- Excellent: Minimal runtime dependencies installed (only libs, not compilers).
- Excellent: `apt-get clean && rm -rf /var/lib/apt/lists/*` in every RUN.
- Excellent: OCI labels for image metadata.
- OK: `EXPOSE 8000` documented.

**CMD (Production-Ready)**
```
CMD ["uvicorn", "saleor.asgi:application", "--host=0.0.0.0", "--port=8000",
     "--workers=2", "--lifespan=on", "--ws=none", "--no-server-header",
     "--no-access-log", "--timeout-keep-alive=35",
     "--timeout-graceful-shutdown=30", "--limit-max-requests=10000"]
```
- Excellent: Graceful shutdown timeout (30s).
- Excellent: Keep-alive timeout (35s) — slightly above typical load balancer timeout.
- Excellent: Max request limit (10000) for memory leak mitigation.
- Excellent: `--no-server-header` hides server identity.
- Excellent: `--ws=none` disables WebSocket if unused.
- NOTE: Only 2 workers — may be intentional for container orchestration (scale horizontally).

**Missing from Saleor but not necessarily bad:**
- No HEALTHCHECK instruction in Dockerfile (relies on orchestrator).
- No USER instruction to switch to `saleor` user (the CMD runs as root unless overridden by orchestrator).

### Deployment (Elastic Beanstalk)
- ISSUE: `Dockerrun.aws.json` references `saleor/saleor:latest` — violates the "no latest tags" anti-pattern.
- Minimal config — likely legacy/deprecated.

### docker-compose.yml (.devcontainer)
- Good: Separate env files (`common.env`, `backend.env`).
- Good: `restart: unless-stopped` on db and cache.
- Good: Uses Valkey 8.1 (Redis fork) — modern choice.
- Good: Includes mailpit for email testing.
- ISSUE: No health checks on services.

## Comparison: Saleor Dockerfile vs clinic-portal Dockerfile

| Pattern | Saleor | clinic-portal | Gap |
|---|---|---|---|
| Multi-stage build | YES | NO | CRITICAL |
| Non-root user | YES | NO | CRITICAL |
| Pinned tool versions | YES (SHA) | NO (`uv:latest`) | HIGH |
| Build cache mounts | YES | NO | MEDIUM |
| Graceful shutdown | YES (30s) | NO | HIGH |
| Max request limit | YES (10000) | NO | MEDIUM |
| apt-get cleanup | YES | YES | OK |
| OCI labels | YES | NO | LOW |
| Production server | uvicorn (ASGI) | railway_start.sh (unknown) | NEEDS CHECK |

## Gaps Identified for Agent Prompt
1. **Multi-stage builds**: Agent should recommend multi-stage builds to reduce image size and attack surface.
2. **Non-root user**: Agent should verify containers don't run as root (mentioned in anti-patterns but not as an explicit check step).
3. **Version pinning with digests**: Agent should recommend SHA digest pinning for base images and tools.
4. **Build cache optimization**: Agent should recommend `--mount=type=cache` for package managers.
5. **Production CMD patterns**: Agent should check for graceful shutdown, max requests, keep-alive tuning.
6. **USER instruction**: Agent should verify a non-root USER is set in the Dockerfile.
