# Run 02: fastapi-template — Layered Architecture, Dependency Direction

## Source Files
- `/home/intruder/projects/fastapi-template/src/app/` (directory structure)
- `/home/intruder/projects/fastapi-template/src/app/core/security.py`
- `/home/intruder/projects/fastapi-template/src/app/api/dependencies.py`
- `/home/intruder/projects/fastapi-template/src/app/core/config.py`

## Findings

### Architecture: Clean Layered Architecture

**Layer Structure (top to bottom):**
```
API Layer (app/api/)
  └── v1/ — versioned endpoints
  └── dependencies.py — FastAPI Depends() injection

Middleware Layer (app/middleware/)
  └── client_cache_middleware.py
  └── logger_middleware.py

Schema Layer (app/schemas/)
  └── Pydantic models for request/response

Core Layer (app/core/)
  └── config.py — settings
  └── security.py — JWT, password hashing
  └── db/ — database connection, CRUD base
  └── health.py — health check
  └── logger.py — structured logging
  └── schemas.py — shared schemas

CRUD Layer (app/crud/)
  └── Per-model CRUD operations

Model Layer (app/models/)
  └── SQLAlchemy ORM models

Admin Layer (app/admin/)
  └── Admin interface
```

### Dependency Direction Analysis

**Correct dependency direction (outer → inner):**
- `api/dependencies.py` imports from `core/security.py` and `crud/crud_users.py` — API depends on Core.
- `core/security.py` imports from `crud/crud_users.py` — Core depends on CRUD (arguably a violation).
- `crud/` imports from `core/db/` — CRUD depends on Core DB.

**Dependency inversion issues:**
- `core/security.py` directly calls `crud_users.get()` — the Core layer should not depend on CRUD. This should go through an interface or be in a Service layer.
- No explicit Service layer exists — business logic is split between CRUD and API layers.

### Key Patterns

1. **Dependency Injection via FastAPI Depends():**
   - `get_current_user()` — extracts and validates JWT, returns user dict.
   - `get_current_superuser()` — extends `get_current_user` with role check.
   - `rate_limiter_dependency()` — per-request rate limiting.
   - Clean chain: `Depends(get_current_user)` → `Depends(oauth2_scheme)` → `Depends(async_get_db)`.

2. **Rate Limiting (Tiered):**
   - Users have tiers, tiers have per-path rate limits.
   - Defaults for anonymous users.
   - Uses Redis for rate limit tracking.

3. **Token Blacklisting:**
   - JWT tokens can be blacklisted (for logout).
   - Checked on every request in `verify_token()`.

4. **API Versioning:**
   - `/api/v1/` prefix — explicit version in URL path.

### Comparison with clinic-portal Architecture

| Pattern | fastapi-template | clinic-portal |
|---|---|---|
| Layered architecture | YES (clear layers) | PARTIAL (flat apps) |
| Service layer | NO (CRUD = service) | PARTIAL (services.py in some apps) |
| Dependency injection | YES (FastAPI Depends) | NO (Django has no DI) |
| API versioning | YES (/api/v1/) | NO (/api/) |
| Rate limiting | YES (tiered, per-path) | NO |
| Token blacklisting | YES | N/A (session auth) |
| Health endpoint | YES (core/health.py) | NO |

## Gaps Identified for Agent Prompt
1. **Layer dependency direction**: Agent should analyze and flag when inner layers depend on outer layers (dependency inversion violations).
2. **Missing Service layer**: Agent should identify when business logic is split across CRUD/API without a proper service layer.
3. **Dependency injection patterns**: Agent should evaluate DI approach and recommend improvements.
4. **API versioning strategy**: Agent should check if API versioning exists and recommend one if missing.
5. **Rate limiting architecture**: Agent should evaluate rate limiting approach and recommend one.
