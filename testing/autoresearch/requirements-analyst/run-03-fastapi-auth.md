# Run 03: Extract Auth Requirements from fastapi-template Code

## Source: backend/app/api/deps.py, backend/app/api/routes/login.py, backend/app/models.py, backend/app/core/security.py

## Extracted Requirements

### Authentication

- [REQ-AUTH001] OAuth2 password grant login
  - Given valid email + password, When POST /login/access-token, Then JWT access token is returned
  - Evidence: `login_access_token()` uses `OAuth2PasswordRequestForm`
- [REQ-AUTH002] JWT token with configurable expiry
  - Given a login, When token is created, Then it expires after `ACCESS_TOKEN_EXPIRE_MINUTES` (default 8 days)
  - Evidence: `create_access_token(subject, expires_delta)` in security.py
- [REQ-AUTH003] Token validation extracts user identity
  - Given a JWT token, When decoded, Then the `sub` claim identifies the user UUID
  - Evidence: `get_current_user()` decodes token, looks up `token_data.sub`
- [REQ-AUTH004] Inactive user rejection
  - Given a user with `is_active=False`, When they try to authenticate, Then 400 error is returned
  - Evidence: Both `login_access_token()` and `get_current_user()` check `is_active`

### Password Management

- [REQ-AUTH005] Password hashing with Argon2 + Bcrypt fallback
  - Given a password, When hashed, Then Argon2 is primary, Bcrypt is fallback (for legacy migration)
  - Evidence: `PasswordHash((Argon2Hasher(), BcryptHasher()))` in security.py
- [REQ-AUTH006] Password minimum length enforcement
  - Given a password, When submitted via API, Then it must be 8-128 characters
  - Evidence: `password: str = Field(min_length=8, max_length=128)` in all password models
- [REQ-AUTH007] Password recovery via email token
  - Given a registered email, When password recovery is requested, Then a reset token is sent via email
  - Evidence: `recover_password()` generates token and sends email
- [REQ-AUTH008] Email enumeration prevention
  - Given any email, When password recovery is requested, Then the same response is returned regardless of whether the account exists
  - Evidence: "If that email is registered, we sent a password recovery link" — always returns this
- [REQ-AUTH009] Password reset via token
  - Given a valid reset token, When new password is submitted, Then password is updated
  - Evidence: `reset_password()` verifies token, updates user

### Authorization

- [REQ-AUTH010] Role-based access: regular user vs superuser
  - Given a user, When accessing superuser-only endpoints, Then `is_superuser` is checked
  - Evidence: `get_current_active_superuser()` dependency
- [REQ-AUTH011] Dependency injection chain for auth
  - Given any protected endpoint, When request arrives, Then: extract token → validate JWT → load user → check active → check role
  - Evidence: `SessionDep → TokenDep → get_current_user → CurrentUser → get_current_active_superuser`

### Registration

- [REQ-AUTH012] User registration with email + password + optional name
  - Given registration data, When POST /register, Then user is created with hashed password
  - Evidence: `UserRegister(email, password, full_name)` schema
- [REQ-AUTH013] UUID-based user IDs
  - Given a new user, When created, Then a UUID4 is assigned as primary key
  - Evidence: `id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)`

### Security (Implicit)

- [REQ-SEC001] Secret key validation in non-local environments
  - Given a production environment, When SECRET_KEY is "changethis", Then ValueError is raised
  - Evidence: `_enforce_non_default_secrets()` model validator
- [REQ-SEC002] Token test endpoint for debugging
  - Given a valid token, When POST /login/test-token, Then current user info is returned
  - Evidence: `test_token()` endpoint — useful for frontend to verify token validity
- [REQ-SEC003] No user existence leakage on password reset
  - Given an invalid user, When reset password is attempted, Then same "Invalid token" error is returned
  - Evidence: `# Don't reveal that the user doesn't exist` comment in reset_password()

## Evaluation

### Did the prompt guide good requirements extraction?
- **Discovery**: Good — extracted from code patterns, error handling, and security comments
- **REQ-xxx tagging**: YES — domain-prefixed (AUTH, SEC)
- **Acceptance criteria**: YES — Given/When/Then for all
- **Completeness**: YES for auth domain — covered login, registration, password management, authorization
- **Duplicate check**: YES

### Prompt Gaps Identified
1. **No instruction to use domain-prefixed requirement IDs** — I used REQ-AUTH001 instead of plain REQ-001. This is better for large codebases but the prompt doesn't instruct it. Should add: "prefix requirement IDs with domain abbreviation for traceability"
2. **No instruction to extract SECURITY requirements as a first-class category** — the prompt mentions "no non-functional requirements mentioned → add defaults" in Chaos Resilience, but security requirements extracted from code deserve explicit attention. The prompt should instruct: "always extract security requirements separately — look for input validation, error message leakage, credential handling"
