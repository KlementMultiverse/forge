# Run 04: Clinic Portal - Middleware Per-Request Cost

## Target
- Repo: clinic-portal (Python/Django multi-tenant with django-tenants)
- Focus: Middleware per-request cost, tenant membership query on every request

## Files Read
- `config/settings.py` (MIDDLEWARE list)
- `apps/tenants/middleware.py` - SafeTenantAccessMiddleware + FlexibleTenantMiddleware
- `apps/users/middleware.py` - PasswordResetMiddleware

## Findings

### 1. N+1 Tenant Membership Check on EVERY Authenticated Request (Critical)
`SafeTenantAccessMiddleware` runs this on every non-exempt request:
```python
if not request.user.tenants.filter(pk=request.tenant.pk).exists():
```
This is a database query on **every single request** for authenticated users on tenant subdomains. For a portal with 50+ requests/page-load, this adds 50+ queries per page.

**Fix**: Cache the tenant membership in session after first check, or use a middleware-level cache with short TTL.

### 2. Middleware Stack Depth (9 Middlewares)
```python
MIDDLEWARE = [
    "django_tenants.middleware.main.TenantMainMiddleware",  # DB query to resolve tenant
    "django.middleware.security.SecurityMiddleware",
    "whitenoise.middleware.WhiteNoiseMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",  # DB query to load user
    "apps.users.middleware.PasswordResetMiddleware",
    "apps.tenants.middleware.SafeTenantAccessMiddleware",  # DB query for membership
]
```
At minimum, 3 DB queries per authenticated request before the view even runs:
1. TenantMainMiddleware: resolve tenant from subdomain/session
2. AuthenticationMiddleware: load user from session
3. SafeTenantAccessMiddleware: check tenant membership

### 3. FlexibleTenantMiddleware Does Extra DB Lookup
When on public schema with session-based routing, it does:
```python
tenant = TenantModel.objects.get(pk=tenant_id)
```
Another DB query per request for session-routed tenants.

### 4. PasswordResetMiddleware Has Attribute Check Overhead
```python
if hasattr(request.user, "must_reset_password") and request.user.must_reset_password:
```
Minor, but `hasattr` on a model may trigger a deferred field load if `must_reset_password` is a deferred field.

### 5. No Short-Circuit for Static Files
`SafeTenantAccessMiddleware` exempts `/static/` but WhiteNoise serves statics before this middleware runs (position 2 vs position 8). So static file serving is already efficient. But API requests still go through the full stack.

## Does the Current Prompt Guide Finding This?
**NO** for the critical finding:
- **NO** middleware cost analysis patterns
- **NO** per-request query counting as a technique
- **NO** session caching as a mitigation for repeated queries
- **NO** Django middleware ordering optimization guidance
- **NO** multi-tenant specific performance patterns

## Gaps to Fix
1. Add middleware/interceptor per-request cost analysis
2. Add "count queries per request" as a profiling technique
3. Add session/request-level caching for repeated lookups
4. Add multi-tenant performance patterns (schema switching, membership caching)
5. Add middleware ordering optimization
