# Run 06: fastapi-template — Auth Architecture (JWT, Session, OAuth)

## Source Files
- `/home/intruder/projects/fastapi-template/src/app/core/security.py`
- `/home/intruder/projects/fastapi-template/src/app/api/dependencies.py`
- `/home/intruder/projects/fastapi-template/src/app/core/config.py`

## Findings

### Auth Strategy: JWT with Token Blacklisting

**Token Architecture:**
- Dual-token design: Access Token (short-lived) + Refresh Token (long-lived).
- Access token expires in `ACCESS_TOKEN_EXPIRE_MINUTES` (configurable).
- Refresh token expires in `REFRESH_TOKEN_EXPIRE_DAYS` (configurable).
- Both stored as JWT with `token_type` claim to differentiate.
- Algorithm configurable (from settings).

**Token Lifecycle:**
1. Login → verify password (bcrypt) → create access + refresh tokens.
2. API requests → `Authorization: Bearer {access_token}` → verify_token() → get_current_user().
3. Token refresh → verify refresh token → issue new access token.
4. Logout → blacklist both tokens in database.

**Token Blacklisting:**
- Blacklist stored in database (`TokenBlacklistCreate`).
- Every token verification checks blacklist first — O(1) DB lookup per request.
- Blacklisted tokens have `expires_at` — can be cleaned up after expiry.
- This solves the JWT statelessness problem (cannot revoke JWT without blacklist).

**Dependency Injection Chain:**
```
OAuth2PasswordBearer(tokenUrl="/api/v1/login")
  → get_current_user(token, db)
    → verify_token(token, ACCESS, db)
      → check blacklist
      → decode JWT
      → extract username_or_email
    → crud_users.get(email or username)
  → get_current_superuser(current_user)
    → check is_superuser flag
```

### Security Analysis

**Strengths:**
1. bcrypt for password hashing — industry standard, properly imported.
2. JWT decode uses specific algorithm (not `algorithms=["HS256", "RS256"]` wildcard).
3. Token blacklisting addresses JWT revocation problem.
4. Separate token types prevent access token from being used as refresh and vice versa.
5. `SecretStr` for SECRET_KEY — prevents accidental logging.

**Weaknesses:**
1. `datetime.fromtimestamp(exp_timestamp)` in `blacklist_tokens()` — no timezone, may cause issues.
2. No token rotation on refresh — the old refresh token isn't blacklisted when creating new access token.
3. No rate limiting on login endpoint (could allow brute force).
4. Username lookup before password check — timing attack possible (different response time for existing vs non-existing users).
5. No account lockout after N failed attempts.

### Comparison: fastapi-template Auth vs clinic-portal Auth

| Pattern | fastapi-template | clinic-portal |
|---|---|---|
| Auth mechanism | JWT (Bearer) | Session (cookie) |
| Token storage | Client-side (JWT) | Server-side (Redis session) |
| Revocation | Token blacklist DB | Delete session |
| Password hashing | bcrypt | Django's PBKDF2 (default) |
| Statelessness | YES (JWT) | NO (session) |
| CSRF needed | NO (Bearer token) | YES (session cookies) |
| Multi-device logout | Requires blacklisting all tokens | Delete all sessions for user |
| Refresh strategy | Explicit refresh token | Session auto-extends |

### Architectural Trade-offs

| Decision | Trade-off |
|---|---|
| JWT over sessions | Stateless scaling BUT token revocation is complex (need blacklist) |
| Blacklist in DB | Revocation works BUT every request hits DB (defeats JWT statelessness) |
| Dual-token | Better security BUT more complex client logic |
| bcrypt | Slow (by design) BUT consumes more CPU per login |

## Gaps Identified for Agent Prompt
1. **Auth mechanism evaluation**: Agent should evaluate the chosen auth mechanism (JWT vs session vs OAuth) with trade-offs for the project's requirements.
2. **Security vulnerability identification**: Agent should check for timing attacks, brute force protection, token rotation, timezone handling.
3. **Trade-off analysis for auth decisions**: Agent should explicitly document what you gain and lose with each auth choice.
4. **Consistency check**: Agent should verify auth architecture is consistent across all endpoints (no endpoints accidentally public).
5. **Multi-device/multi-session considerations**: Agent should evaluate how the auth system handles multiple simultaneous sessions.
