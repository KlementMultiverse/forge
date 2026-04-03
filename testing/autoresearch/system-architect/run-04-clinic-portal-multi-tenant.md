# Run 04: clinic-portal — Multi-Tenant Architecture, Schema Isolation Design

## Source Files
- `/home/intruder/projects/clinic-portal/config/settings.py`
- `/home/intruder/projects/clinic-portal/SPEC.md`
- `/home/intruder/projects/clinic-portal/apps/tenants/` (models, middleware)
- `/home/intruder/projects/clinic-portal/apps/users/` (models, api)
- `/home/intruder/projects/clinic-portal/apps/documents/services.py`

## Findings

### Multi-Tenancy Strategy: PostgreSQL Schema-Per-Tenant

**Implementation:**
- `django-tenants` for schema isolation — each tenant gets its own PostgreSQL schema.
- `django-tenant-users` for global user model with per-tenant access control.
- `TenantMainMiddleware` at position 0 — resolves tenant from subdomain on every request.
- `TenantSyncRouter` — routes queries to the correct schema automatically.
- `SafeTenantAccessMiddleware` — blocks unauthorized cross-tenant access.

**SHARED vs TENANT Separation:**
- SHARED_APPS: `django_tenants`, `apps.tenants`, `apps.users`, `tenant_users.permissions`, `tenant_users.tenants`, Django built-ins.
- TENANT_APPS: `apps.dashboard`, `apps.workflows`, `apps.documents`, `apps.search`.
- `tenant_users.permissions` is in BOTH — allows per-tenant permission grants on shared user model.

**Tenant Model:**
```python
class Tenant(TenantBase):
    name = CharField(max_length=100)
    created_at = DateTimeField(auto_now_add=True)
    auto_create_schema = True
```
- `auto_create_schema = True` — new tenant creation triggers schema + migration automatically.
- Inherits from `TenantBase` (django-tenant-users) which integrates with UserProfile.

**User Model (Shared):**
```python
class User(UserProfile):
    name, role, must_reset_password
```
- Global user model — one user can belong to multiple tenants.
- Role (`admin`/`staff`) is per-user, NOT per-tenant — architectural limitation.

### Architectural Analysis

**Strengths:**
1. Strong data isolation — PostgreSQL schemas prevent accidental cross-tenant data access at the database level.
2. Middleware chain correctly ordered — tenant resolution before auth before access control.
3. S3 keys namespaced by tenant schema name — storage isolation.
4. Redis cache keys tenant-aware via `django_tenants.cache.make_key`.
5. Migrations handled separately (`migrate_schemas --shared` / `--tenant`).

**Weaknesses / Design Issues:**

1. **Role is global, not per-tenant:** `User.role` is on the shared model. A user who is `admin` in one clinic is `admin` in ALL their clinics. This contradicts multi-tenant permission isolation. Fix: role should be on the tenant-user relationship (join table), not the User model.

2. **No tenant context in service layer:** `documents/services.py` accesses `connection.schema_name` directly. This is a Django-tenants pattern but creates tight coupling to the connection state. If you ever call services outside a request (e.g., management commands, background tasks), the schema context might be wrong.

3. **No tenant-scoped querysets by default:** The ORM routes queries to the correct schema via the router, but there's no defense-in-depth. If middleware fails to set the tenant, queries go to the public schema.

4. **AuditLog has `performed_by` as ForeignKey to shared User:** This works with django-tenants (the FK resolves correctly within the tenant schema), but it means AuditLog entries reference user IDs that are only meaningful in the shared schema context.

5. **Session engine is Redis cache:** Sessions are cached with tenant-aware keys (via `make_key`), but if Redis is flushed, all sessions are lost. No fallback to database sessions.

6. **CSRF_TRUSTED_ORIGINS is hardcoded:** New tenants with new subdomains won't be in the trusted origins list. This should be dynamic or use wildcard patterns.

### Data Flow: Request → Response

```
Browser request to clinic1.localhost:8000/api/workflows/
  → TenantMainMiddleware: resolves "clinic1" → sets connection.schema_name = "clinic1"
  → SecurityMiddleware: standard Django security headers
  → WhiteNoiseMiddleware: serves static files
  → SessionMiddleware: loads session (Redis, tenant-aware key)
  → CsrfViewMiddleware: validates CSRF token
  → AuthenticationMiddleware: loads user from session
  → PasswordResetMiddleware: checks must_reset_password flag
  → SafeTenantAccessMiddleware: verifies user has access to clinic1 tenant
  → URL resolution: config/urls.py (tenant URLs)
  → Django Ninja router: /api/workflows/ → WorkflowRouter
  → django_auth session check
  → ORM query: Workflow.objects.all() → routed to clinic1 schema by TenantSyncRouter
  → Response: JSON with workflow data
```

## Gaps Identified for Agent Prompt
1. **Multi-tenancy pattern analysis**: Agent should evaluate tenant isolation strategy (schema-per-tenant, row-level, database-per-tenant) with trade-offs.
2. **Per-tenant vs global authorization**: Agent should check if roles/permissions are scoped per-tenant or global.
3. **Tenant context propagation**: Agent should verify tenant context is available in all execution paths (requests, background tasks, management commands).
4. **Defense-in-depth for isolation**: Agent should check for multiple layers of tenant isolation (middleware + router + queryset + storage).
5. **Dynamic tenant configuration**: Agent should check if CSRF, ALLOWED_HOSTS, CORS adapt to new tenants automatically.
6. **Cross-tenant data references**: Agent should analyze Foreign Keys that cross the shared/tenant boundary.
