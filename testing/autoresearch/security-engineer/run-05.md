# Run 05: fastapi-template — JWT handling, token expiry, algorithm validation

## Target
- Repo: `/home/intruder/projects/forge-test-repos/fastapi-template`
- Scope: `backend/app/core/security.py`, `backend/app/api/deps.py`, `backend/app/utils.py`

## Files Examined
- `backend/app/core/security.py` — JWT creation, password hashing
- `backend/app/api/deps.py` — JWT verification in dependency
- `backend/app/utils.py` — Password reset token generation/verification

## Security Findings

### 1. Algorithm is hardcoded correctly (GOOD)
- **File**: `backend/app/core/security.py:19` — `ALGORITHM = "HS256"`
- **File**: `backend/app/api/deps.py:33` — `algorithms=[security.ALGORITHM]`
- Both encode and decode use explicit algorithm. No "none" algorithm vulnerability.

### 2. JWT decode uses algorithms list (GOOD)
- `jwt.decode(token, settings.SECRET_KEY, algorithms=[security.ALGORITHM])` — correctly passes algorithms as a list, preventing algorithm confusion attacks.

### 3. Password reset token has 48-hour expiry (MEDIUM)
- **File**: `backend/app/core/config.py:86` — `EMAIL_RESET_TOKEN_EXPIRE_HOURS: int = 48`
- 48 hours is generous for a password reset token. Industry standard is 1-4 hours.

### 4. Password reset token is a JWT (not a random token) (LOW)
- **File**: `backend/app/utils.py:103-113`
- Uses the same SECRET_KEY as access tokens. If SECRET_KEY is compromised, an attacker can forge password reset tokens.
- Better practice: use a separate signing key for reset tokens, or use opaque random tokens stored in DB.

### 5. Password hashing uses Argon2 + Bcrypt (GOOD)
- **File**: `backend/app/core/security.py:11-16`
- `PasswordHash((Argon2Hasher(), BcryptHasher()))` — Argon2 is the primary hasher with Bcrypt fallback. This is excellent.

### 6. No JWT token revocation mechanism (MEDIUM)
- No token blacklist, no database check for token validity. Once issued, a token is valid for 8 days with no way to revoke it (e.g., on password change or user deactivation).

### 7. User is_active check on every request (GOOD)
- **File**: `backend/app/api/deps.py:44` — checks `user.is_active` on token verification.

## Agent Prompt Evaluation

| Finding | Would prompt guide to this? | Notes |
|---|---|---|
| Algorithm validation | PARTIAL | Prompt says "check auth" but not specifically JWT algorithm confusion |
| algorithms list | NO | Specific to JWT library |
| Reset token expiry | NO | No token lifetime guidance |
| Same key for reset tokens | NO | No key separation guidance |
| Argon2 hashing | PARTIAL | Would find via grep but not evaluate quality |
| No token revocation | NO | Not mentioned in prompt |

## GAPs Identified
1. **GAP: No JWT-specific security checklist** — needs: algorithm validation (no "none"), key separation, token revocation, refresh token rotation, audience/issuer claims, token expiry best practices
2. **GAP: No password reset security guidance** — needs: token expiry limits, one-time-use enforcement, separate signing keys
