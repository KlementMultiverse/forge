# Run 08: clinic-portal — Rate limiting, password policy, brute force protection

## Target
- Repo: `/home/intruder/projects/clinic-portal`
- Scope: `config/settings.py`, `apps/users/`

## Files Examined
- `config/settings.py` — full Django settings
- `apps/users/models.py` — User model
- `apps/users/middleware.py` — (exists but not yet read for this specific check)
- Grep results for rate_limit, throttle, PASSWORD_MIN, password_validator

## Security Findings

### 1. No AUTH_PASSWORD_VALIDATORS configured (HIGH)
- **File**: `config/settings.py`
- `AUTH_PASSWORD_VALIDATORS` is completely absent from settings.
- **Issue**: Django's built-in password validators (MinimumLengthValidator, CommonPasswordValidator, NumericPasswordValidator, UserAttributeSimilarityValidator) are NOT enabled. Users can set passwords like "1" or "password".

### 2. No rate limiting on any endpoint (HIGH)
- No rate limiting middleware, no django-ratelimit, no throttle configuration found anywhere in the codebase.
- The login endpoint accepts unlimited authentication attempts, enabling brute force attacks.

### 3. No account lockout mechanism (HIGH)
- No failed login counter, no account lockout after N failures, no CAPTCHA on login.
- Combined with no rate limiting, this makes credential stuffing trivial.

### 4. Session security is configured (GOOD)
- **File**: `config/settings.py:135-138`
  - `SESSION_COOKIE_HTTPONLY = True`
  - `SESSION_COOKIE_SAMESITE = "Lax"`
  - `SESSION_COOKIE_SECURE = not DEBUG`

### 5. CSRF configuration is adequate (GOOD)
- CSRF middleware is present
- `CSRF_TRUSTED_ORIGINS` is configured with specific domains

### 6. must_reset_password field exists (GOOD)
- **File**: `apps/users/models.py:12` — `must_reset_password = models.BooleanField(default=False)`
- Suggests password reset enforcement is planned/implemented.

### 7. No SECURE_HSTS_SECONDS (MEDIUM)
- Missing from settings. Only `SECURE_CONTENT_TYPE_NOSNIFF = True` and `X_FRAME_OPTIONS = "DENY"` are set.

## Agent Prompt Evaluation

| Finding | Would prompt guide to this? | Notes |
|---|---|---|
| No password validators | NO | Prompt says "check auth" but not Django password validators specifically |
| No rate limiting | NO | Prompt has "Empty input validation" in chaos resilience but nothing about rate limiting |
| No account lockout | NO | Not mentioned |
| Session security | YES | Prompt says "check auth on endpoints" |
| Missing HSTS | NO | No security headers checklist |

## GAPs Identified
1. **GAP: No rate limiting / brute force checklist** — needs: check for rate limiting middleware, account lockout, CAPTCHA, progressive delays
2. **GAP: No password policy audit** — needs: check AUTH_PASSWORD_VALIDATORS (Django), check password length minimums, check common password lists
3. **GAP: No security headers checklist** — needs: HSTS, Content-Security-Policy, Referrer-Policy, Permissions-Policy
