# Run 04: clinic-portal — Cross-schema FK cascade risks

## Target
- Repo: `/home/intruder/projects/clinic-portal`
- Scope: Multi-tenant models, FK cascade behavior across schemas

## Files Examined
- `apps/tenants/models.py` — Tenant model (shared schema)
- `apps/users/models.py` — User model (shared schema via UserProfile)
- `apps/workflows/models.py` — Workflow, Task, AuditLog (tenant schema)
- `apps/documents/models.py` — Document model (tenant schema)
- `config/settings.py` — SHARED_APPS vs TENANT_APPS

## Security Findings

### 1. CASCADE from tenant models to shared user model (HIGH)
- **File**: `apps/workflows/models.py:45`
  - `Workflow.created_by = ForeignKey(AUTH_USER_MODEL, on_delete=CASCADE)`
  - `Task.created_by = ForeignKey(AUTH_USER_MODEL, on_delete=CASCADE)`
  - `Document.uploaded_by = ForeignKey(AUTH_USER_MODEL, on_delete=CASCADE)`
- **Issue**: In a multi-tenant PostgreSQL schema setup (django-tenants), tenant-schema models have ForeignKeys pointing to shared-schema user models. When a user is deleted from the shared schema, Django tries to CASCADE delete across schemas. This can:
  - Fail silently depending on search_path
  - Delete data in tenant schemas unexpectedly
  - Create orphaned records if the cascade doesn't reach the tenant schema
- **Recommendation**: Use `on_delete=models.PROTECT` or `on_delete=models.SET_NULL` for cross-schema FKs.

### 2. No tenant isolation validation on FKs (HIGH)
- **File**: `apps/workflows/models.py:78-83`
- `Task.assigned_to` points to AUTH_USER_MODEL — but there's no validation that the assigned user belongs to the current tenant.
- An admin in Tenant A could theoretically reference a user ID from Tenant B if the FK is a shared-schema user.
- **Note**: django-tenant-users handles user-tenant association, but the FK itself doesn't enforce tenant boundary.

### 3. AuditLog immutability is application-level only (MEDIUM)
- **File**: `apps/workflows/models.py:30-36`
- `save()` and `delete()` raise ValueError, but this is only enforced at Django ORM level. Direct SQL or admin can bypass it.
- **Recommendation**: Consider database-level triggers or a read-only database user for audit tables.

### 4. No cross-schema FK cascade tests (MEDIUM)
- No tests found that specifically test what happens when a shared-schema user is deleted and tenant-schema records reference them.

## Agent Prompt Evaluation

| Finding | Would prompt guide to this? | Notes |
|---|---|---|
| CASCADE cross-schema | NO | Prompt has no multi-tenant security guidance |
| Tenant isolation on FKs | NO | Prompt says "check tenant isolation" but doesn't specify HOW for FKs |
| Application-level immutability | PARTIAL | Prompt would catch "audit logging" but not the bypass risk |
| Missing cascade tests | NO | Not in scope of prompt |

## GAPs Identified
1. **GAP: No multi-tenant security checklist** — needs: cross-schema FK cascade risks, tenant isolation validation on all data access, schema search_path verification, shared-vs-tenant model boundary enforcement
2. **GAP: No database-level vs application-level enforcement distinction** — prompt should note that application-level security (Python raise) is bypassable via direct DB access
