# Run 06: saleor — Django middleware ordering, CSRF config, session security

## Target
- Repo: `/home/intruder/projects/forge-test-repos/saleor`
- Scope: `saleor/settings.py` middleware, session, CSRF settings

## Files Examined
- `saleor/settings.py:86,198,212,258,269,281-285,506,511`

## Security Findings

### 1. DEBUG defaults to True (CRITICAL)
- **File**: `saleor/settings.py:86` — `DEBUG = get_bool_from_env("DEBUG", True)`
- **Issue**: If DEBUG env var is not set, it defaults to True. In production, forgetting to set this env var would expose stack traces, detailed error pages, and SQL queries to users.
- Saleor does have compensating controls (raises on missing ALLOWED_CLIENT_HOSTS when DEBUG=False), but the default itself is dangerous.

### 2. SECRET_KEY auto-generated in DEBUG mode (MEDIUM)
- **File**: `saleor/settings.py:258-273`
- `SECRET_KEY = os.environ.get("SECRET_KEY")` — if None and DEBUG, generates random key.
- Multi-instance deployments in DEBUG mode would have different keys.

### 3. Middleware has only 3 entries (MEDIUM)
- **File**: `saleor/settings.py:281-285`
- ```python
  MIDDLEWARE = [
      "django.middleware.security.SecurityMiddleware",
      "django.middleware.common.CommonMiddleware",
      "saleor.core.middleware.jwt_refresh_token_middleware",
  ]
  ```
- **Missing**: No SessionMiddleware, no CsrfViewMiddleware, no AuthenticationMiddleware, no XFrameOptionsMiddleware.
- This is intentional (API-only, no sessions), but it means there's zero CSRF protection at the framework level, relying entirely on token-based auth.

### 4. No SECURE_HSTS settings (MEDIUM)
- No `SECURE_HSTS_SECONDS`, `SECURE_HSTS_INCLUDE_SUBDOMAINS`, `SECURE_HSTS_PRELOAD` found.
- Only `SECURE_SSL_REDIRECT = not DEBUG` when ENABLE_SSL is True.

### 5. SECURE_PROXY_SSL_HEADER set (GOOD)
- **File**: `saleor/settings.py:511` — `SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")`

### 6. ALLOWED_HOSTS from env with defaults (GOOD)
- **File**: `saleor/settings.py:506` — Defaults to localhost only.

### 7. Test settings use hardcoded SECRET_KEY (LOW)
- **File**: `saleor/tests/settings.py:27` — `SECRET_KEY = "NOTREALLY"` — acceptable for tests only.

## Agent Prompt Evaluation

| Finding | Would prompt guide to this? | Notes |
|---|---|---|
| DEBUG=True default | PARTIAL | Prompt says check for secrets but not DEBUG defaults |
| Missing middleware | YES | Prompt says "check auth on endpoints, verify CSRF" |
| No HSTS | NO | No security headers checklist |
| SSL settings | NO | Not specifically called out |
| Test SECRET_KEY | PARTIAL | grep would find it |

## GAPs Identified
1. **GAP: No Django security headers checklist** — needs: SECURE_HSTS_SECONDS, SECURE_CONTENT_TYPE_NOSNIFF, X_FRAME_OPTIONS, SECURE_BROWSER_XSS_FILTER, SESSION_COOKIE_SECURE, CSRF_COOKIE_SECURE
2. **GAP: No DEBUG mode audit** — prompt should specifically check that DEBUG defaults to False, and that DEBUG=True is never possible in production
3. **GAP: No middleware ordering audit** — prompt should verify expected middleware is present and in correct order
