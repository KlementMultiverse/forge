# Run 08: Explain Why Middleware Ordering Matters in Django (clinic-portal)

## Source Repo: clinic-portal
## Key Files: config/settings.py (lines 88-100)

## Teaching Output

### The Pipeline Mental Model

Django middleware is a pipeline. Each request passes through middleware TOP to BOTTOM. Each response passes BOTTOM to TOP. Think of it as a series of security checkpoints at an airport — you must pass through them in order, and each one depends on the previous one having done its job.

### clinic-portal's Middleware Stack (Annotated)

```python
MIDDLEWARE = [
    # 1. TenantMainMiddleware — MUST BE FIRST
    #    Reads hostname (clinic1.localhost), sets connection.schema_name
    #    After this: all DB queries go to the right tenant schema
    "django_tenants.middleware.main.TenantMainMiddleware",

    # 2. SecurityMiddleware — HTTP security headers (HSTS, etc.)
    "django.middleware.security.SecurityMiddleware",

    # 3. WhiteNoise — serves static files
    "whitenoise.middleware.WhiteNoiseMiddleware",

    # 4. SessionMiddleware — loads session from Redis
    #    Depends on: TenantMainMiddleware (tenant-aware cache keys)
    "django.contrib.sessions.middleware.SessionMiddleware",

    # 5. CommonMiddleware — URL normalization (trailing slashes)
    "django.middleware.common.CommonMiddleware",

    # 6. CsrfViewMiddleware — CSRF token validation
    #    Depends on: SessionMiddleware (session must exist)
    "django.middleware.csrf.CsrfViewMiddleware",

    # 7. AuthenticationMiddleware — sets request.user
    #    Depends on: SessionMiddleware (reads user ID from session)
    "django.contrib.auth.middleware.AuthenticationMiddleware",

    # 8. PasswordResetMiddleware — redirects if must_reset_password=True
    #    Depends on: AuthenticationMiddleware (needs request.user)
    "apps.users.middleware.PasswordResetMiddleware",

    # 9. SafeTenantAccessMiddleware — blocks users not in this tenant
    #    Depends on: AuthenticationMiddleware (needs request.user)
    #    Depends on: TenantMainMiddleware (needs request.tenant)
    "apps.tenants.middleware.SafeTenantAccessMiddleware",

    # 10. MessageMiddleware — flash messages
    "django.contrib.messages.middleware.MessageMiddleware",

    # 11. XFrameOptionsMiddleware — clickjacking protection
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]
```

### What Breaks If You Reorder

**Scenario 1: TenantMainMiddleware is NOT position 0**

If `SessionMiddleware` runs before `TenantMainMiddleware`, sessions are loaded WITHOUT tenant context. Redis cache keys use `django_tenants.cache.make_key` which includes the schema name. Without the schema set, you get the wrong cache key — potentially loading Clinic A's session data for Clinic B's user.

**Scenario 2: AuthenticationMiddleware before SessionMiddleware**

`AuthenticationMiddleware` reads `request.session['_auth_user_id']`. If the session hasn't been loaded yet (because `SessionMiddleware` hasn't run), `request.user` is always `AnonymousUser`. Every user appears logged out.

**Scenario 3: PasswordResetMiddleware before AuthenticationMiddleware**

`PasswordResetMiddleware` checks `request.user.must_reset_password`. If `request.user` hasn't been set yet, you get an `AttributeError` or the check is skipped entirely — staff with temporary passwords can access everything without resetting.

### The Dependency Chain

```
TenantMainMiddleware → sets connection.schema_name
    ↓
SessionMiddleware → uses tenant-aware cache keys to load session
    ↓
AuthenticationMiddleware → reads user ID from session
    ↓
PasswordResetMiddleware → checks request.user.must_reset_password
    ↓
SafeTenantAccessMiddleware → checks if request.user belongs to request.tenant
```

Each middleware builds on what the previous one established. Break the chain and downstream middleware operates on incomplete or wrong data.

### Rule of Thumb for Ordering

1. **Infrastructure first**: tenant resolution, security headers, static files
2. **Session and state next**: session loading, CSRF
3. **Identity after session**: authentication (needs session to know who you are)
4. **Authorization after identity**: tenant access checks, password reset enforcement (need to know WHO before checking WHAT they can do)
5. **Presentation last**: messages, clickjacking headers

## Evaluation

### Did the prompt guide good pedagogy?
- **Anchor to existing knowledge**: YES - Airport security checkpoint analogy
- **Progressive disclosure**: YES - Pipeline concept → annotated code → failure scenarios → dependency chain → rule of thumb
- **Practical examples**: YES - Real clinic-portal middleware stack with failure scenarios
- **Multiple explanation approaches**: YES - Analogy, annotated code, dependency chain, failure scenarios
- **Verify understanding**: PARTIAL - The failure scenarios serve as implicit checks ("what would happen if...") but no explicit exercises

### Prompt Gaps Identified
1. **No instruction to show failure modes as a teaching tool** — I used "what breaks if you reorder" naturally, but the prompt doesn't mandate this technique. It should include: "when teaching ordering/configuration, demonstrate what breaks when the order is wrong"
2. **No instruction to provide a generalizable rule** — the "rule of thumb" section abstracts from the specific example to a general principle. The prompt should instruct: "always end with a transferable principle the learner can apply to other projects"
3. **Recurring: no mandatory exercises**
