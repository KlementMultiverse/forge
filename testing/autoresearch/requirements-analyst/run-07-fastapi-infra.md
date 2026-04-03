# Run 07: Extract Infrastructure Requirements from fastapi-template

## Source: compose.yml, backend/app/core/config.py, backend/Dockerfile (path), pyproject.toml

## Extracted Requirements

### Container Infrastructure

- [REQ-INFRA001] PostgreSQL 18 as database service
  - Given the application, When deployed, Then PostgreSQL 18 is available with health checks (pg_isready)
  - Evidence: `image: postgres:18` with healthcheck in compose.yml
- [REQ-INFRA002] Database health check before app start
  - Given the database service, When starting, Then health is verified via `pg_isready` with 10s intervals, 5 retries
  - Evidence: `healthcheck.test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]`
- [REQ-INFRA003] Pre-start migration/seeding phase
  - Given the application, When deploying, Then a prestart service runs migrations before the main backend starts
  - Evidence: `prestart` service with `condition: service_completed_successfully` in backend's depends_on
- [REQ-INFRA004] Backend health check endpoint
  - Given the backend, When running, Then `/api/v1/utils/health-check/` returns 200
  - Evidence: `healthcheck.test: ["CMD", "curl", "-f", "http://localhost:8000/api/v1/utils/health-check/"]`
- [REQ-INFRA005] Persistent database storage via named volume
  - Given database data, When container restarts, Then data persists via `app-db-data` volume
- [REQ-INFRA006] Adminer database admin interface
  - Given a developer, When managing database, Then Adminer is available on a subdomain
  - Evidence: `adminer` service in compose.yml

### Reverse Proxy / Networking

- [REQ-INFRA007] Traefik reverse proxy with automatic HTTPS
  - Given the deployment, When services are exposed, Then Traefik handles SSL termination via Let's Encrypt
  - Evidence: `traefik.http.routers.*.tls.certresolver=le` labels
- [REQ-INFRA008] HTTP to HTTPS redirect
  - Given an HTTP request, When received, Then it's redirected to HTTPS via `https-redirect` middleware
  - Evidence: `traefik.http.routers.*-http.middlewares=https-redirect`
- [REQ-INFRA009] Subdomain-based routing
  - Given the deployment, When services are accessed, Then: `api.DOMAIN` → backend, `dashboard.DOMAIN` → frontend, `adminer.DOMAIN` → adminer
- [REQ-INFRA010] External traefik-public network
  - Given the deployment stack, When multiple stacks share Traefik, Then all join the `traefik-public` external network

### Configuration Management

- [REQ-INFRA011] Environment variables with validation
  - Given required env vars, When not set, Then Docker Compose fails with `?Variable not set` error
  - Evidence: `${SECRET_KEY?Variable not set}` syntax throughout compose.yml
- [REQ-INFRA012] Environment-specific behavior (local/staging/production)
  - Given an ENVIRONMENT setting, When set to "local", Then default secrets are allowed with warnings; production rejects them
  - Evidence: `_check_default_secret()` in config.py
- [REQ-INFRA013] Pydantic Settings for configuration
  - Given environment variables, When loaded, Then pydantic-settings validates types and provides defaults
  - Evidence: `class Settings(BaseSettings)` with `SettingsConfigDict`
- [REQ-INFRA014] CORS origins from environment
  - Given BACKEND_CORS_ORIGINS env var, When parsed, Then comma-separated URLs are split into list
  - Evidence: `parse_cors()` function in config.py

### Database

- [REQ-INFRA015] Computed database URI from individual components
  - Given individual PG settings (server, port, user, password, db), When assembled, Then a PostgresDsn is built
  - Evidence: `SQLALCHEMY_DATABASE_URI` computed field
- [REQ-INFRA016] Sentry integration (optional)
  - Given SENTRY_DSN, When set, Then error tracking is enabled; when empty, Then no Sentry
  - Evidence: `SENTRY_DSN: HttpUrl | None = None`

### Email

- [REQ-INFRA017] SMTP email sending (optional)
  - Given SMTP settings, When fully configured, Then email is enabled; when partial, Then email is disabled
  - Evidence: `emails_enabled` computed field checks `SMTP_HOST and EMAILS_FROM_EMAIL`
- [REQ-INFRA018] Email token expiry
  - Given a password reset email, When token is generated, Then it expires after 48 hours
  - Evidence: `EMAIL_RESET_TOKEN_EXPIRE_HOURS: int = 48`

### Frontend

- [REQ-INFRA019] Separate frontend container
  - Given the frontend, When deployed, Then it runs in its own container with VITE_API_URL set at build time
  - Evidence: `frontend` service with `VITE_API_URL` build arg

## Evaluation

### Did the prompt guide good requirements extraction?
- **Discovery**: Good — extracted from Docker Compose, settings, Traefik labels
- **REQ-xxx tagging**: YES
- **Acceptance criteria**: YES
- **Completeness**: Good for infrastructure scope
- **Duplicate check**: YES

### Prompt Gaps Identified
1. **No instruction to extract from DEPLOYMENT CONFIGURATION** — Docker Compose, Kubernetes manifests, and Terraform files contain requirements that don't appear in application code. The prompt should list: "infrastructure configs (docker-compose, k8s, Terraform) are requirements sources — extract from them"
2. **No instruction to distinguish REQUIRED vs OPTIONAL infrastructure** — Sentry and SMTP are optional (graceful when absent). The prompt should instruct: "mark infrastructure requirements as REQUIRED or OPTIONAL based on graceful degradation patterns"
