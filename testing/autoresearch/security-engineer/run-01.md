# Run 01: fastapi-template — DEBUG mode, CORS config, secret key handling

## Target
- Repo: `/home/intruder/projects/forge-test-repos/fastapi-template`
- Scope: `backend/app/core/config.py`, `backend/app/main.py`

## Files Examined
- `backend/app/core/config.py` — Settings class with pydantic-settings
- `backend/app/main.py` — FastAPI app with CORS middleware

## Security Findings

### 1. SECRET_KEY regenerated on every restart (MEDIUM)
- **File**: `backend/app/core/config.py:34`
- **Issue**: `SECRET_KEY: str = secrets.token_urlsafe(32)` — default generates a new key on every process restart. This means all existing JWTs are invalidated on deploy, but the real risk is: if no .env is set, the key is random and unpredictable per-instance, which could break multi-instance deployments (tokens from instance A won't validate on instance B).
- **Mitigation**: There IS a `_check_default_secret` validator, but it only checks for "changethis" — it does NOT check for the auto-generated default.

### 2. CORS allows wildcard methods and headers (LOW)
- **File**: `backend/app/main.py:28-30`
- **Issue**: `allow_methods=["*"]` and `allow_headers=["*"]` are set. While origins are restricted, wildcard methods/headers increase attack surface.
- **Good**: Origins are restricted to configured values, not `["*"]`.

### 3. Token expiry is 8 days (MEDIUM)
- **File**: `backend/app/core/config.py:36`
- **Issue**: `ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 8` — 8 days is long for access tokens. Industry best practice is 15-60 minutes with refresh tokens.

### 4. No DEBUG flag exposure (GOOD)
- No `DEBUG=True` found in code. ENVIRONMENT is used with local/staging/production enum.

### 5. Default credential check exists but is weak (LOW)
- Only checks for literal "changethis" string. Does not check for common weak passwords or minimum entropy.

## Agent Prompt Evaluation

| Finding | Would prompt guide to this? | Notes |
|---|---|---|
| Secret key handling | PARTIAL | Prompt says "grep for secrets (sk-, ghp_, AKIA, password=)" but does NOT mention checking for auto-generated/ephemeral secret keys or multi-instance key consistency |
| CORS wildcard methods | NO | Prompt has no CORS-specific guidance at all |
| Long token expiry | NO | Prompt mentions auth but not token lifetime best practices |
| Default credential check | PARTIAL | Prompt would find password patterns but not evaluate the quality of the check |

## GAPs Identified
1. **GAP: No CORS audit checklist** — prompt should guide checking `allow_origins`, `allow_methods`, `allow_headers`, `allow_credentials` combinations
2. **GAP: No token lifetime audit** — prompt should mention checking JWT/session expiry values against best practices (15-60 min access, 7-30 day refresh)
3. **GAP: No secret key lifecycle audit** — prompt should check for ephemeral keys, multi-instance consistency, key rotation support
