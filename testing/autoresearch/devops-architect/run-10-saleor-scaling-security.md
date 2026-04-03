# Run 10: saleor — Scaling Strategy, Resource Limits, Container Security

## Source Files
- `/home/intruder/projects/saleor/Dockerfile`
- `/home/intruder/projects/saleor/saleor/settings.py`
- `/home/intruder/projects/saleor/.devcontainer/docker-compose.yml`
- `/home/intruder/projects/saleor/.github/workflows/publish-containers.yml`

## Findings

### Scaling Strategy

**Horizontal Scaling via Container Orchestration:**
- CMD runs uvicorn with `--workers=2` — low worker count suggests horizontal scaling (more containers, not more workers per container).
- `--limit-max-requests=10000` — containers restart after 10K requests, mitigating memory leaks.
- No sticky sessions required — stateless application design.
- Celery for background jobs — separates web and worker scaling independently.
- Sentry integration for production observability.

**Database Scaling:**
- PostgreSQL with connection configuration via `dj-database-url`.
- No explicit connection pooling configuration found (pgbouncer would be external).
- Resource limits handled by orchestrator (Kubernetes/ECS), not compose.

**Caching:**
- Valkey (Redis fork) 8.1 in devcontainer.
- Cache URL configurable via environment.
- Separate broker URL for Celery — allows independent Redis instances for cache and queue.

### Resource Limits

**Docker Compose (devcontainer):**
- No resource limits in compose — acceptable for development.
- Production resources managed by orchestrator (not compose).

**Application-Level Limits:**
- `--limit-max-requests=10000` in uvicorn — process recycling.
- `validate_and_set_rlimit` in settings.py — sets `RLIMIT_DATA` for heap memory limits.
- This is a Python-level OOM prevention — unusual and sophisticated.

### Container Security

**Dockerfile Security:**
- Non-root user created (`saleor:saleor`) — but USER instruction not set (container still runs as root by default).
- Minimal base image (`python:3.12-slim`).
- No `--privileged` anywhere.
- No Docker socket mounting.
- Build arguments don't contain secrets.
- `--no-server-header` hides uvicorn identity.

**CI/CD Security:**
- Least-privilege permissions on all workflows.
- Action versions pinned to SHA digests.
- GitHub Environments for secrets isolation.
- OIDC for cloud authentication (no long-lived credentials).
- Dependabot for dependency updates.
- Semgrep for security scanning.

**Application Security (from settings.py):**
- Sentry with `EventScrubber` and `DEFAULT_PII_DENYLIST` — PII scrubbing in error reports.
- Sentry deny-list extended with custom sensitive keys.
- CSRF and CORS properly configured.
- Secret key validation.

### Comparison: saleor Production Patterns vs clinic-portal

| Security Pattern | saleor | clinic-portal |
|---|---|---|
| Non-root container user | PARTIAL (created, not enforced) | NO |
| Process memory limits | YES (rlimit) | NO |
| Request recycling | YES (max-requests) | NO |
| Error tracking with PII scrubbing | YES (Sentry) | NO |
| Dependency scanning | YES (Dependabot) | NO |
| SAST scanning | YES (Semgrep) | NO |
| OIDC authentication for CI | YES | NO |
| Secret isolation via Environments | YES | NO |
| Server header suppression | YES | NO |

## Comprehensive Gap Summary for Agent Prompt

After 10 runs across 4 projects, these are ALL the gaps found in the devops-architect agent prompt:

### Missing from Forge Cell Compliance (Step-by-Step)
1. Health check verification (endpoints + Docker HEALTHCHECK + compose healthcheck)
2. Graceful shutdown verification (STOPSIGNAL, stop_grace_period, server timeouts)
3. Production server verification (not dev server)
4. File existence validation for Dockerfile references
5. Multi-stage build recommendation
6. Non-root USER instruction verification
7. Base image selection guidance (slim vs full)

### Missing from Anti-Patterns
8. Dev flags in production configs (--reload, runserver)
9. Volume mounts of source code in production compose
10. Inline migrations in container CMD
11. Missing health checks (should be an explicit anti-pattern)

### Missing from Chaos Resilience
12. Handle Railway/Heroku/Cloud Run deployment patterns (DATABASE_URL parsing)
13. Handle monorepo build strategies

### Missing from Focus Areas / Key Actions
14. Secret rotation documentation and procedures
15. IAM least privilege verification
16. Secret manager integration recommendation
17. Env var name consistency checking
18. gitignore completeness for secret patterns
19. Credential scanning tools (gitleaks, trufflehog)
20. CI pipeline patterns: path filtering, concurrency, caching, artifact passing
21. Pre-commit hooks recommendation
22. Service container health checks in CI
23. Test sharding/parallelization
24. API contract testing in CI
25. Migration testing in CI
26. SAST security scanning recommendation
27. Database connection pooling
28. Structured logging configuration
29. Error monitoring (Sentry) recommendation
30. SSL/TLS and HSTS settings verification
31. Rate limiting recommendation
32. CORS configuration check
33. Version pinning with SHA digests
34. EOL version detection for databases and runtimes
