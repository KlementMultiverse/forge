# Django Rules

1. Django Ninja for ALL API routes — NEVER import `rest_framework`
2. Schema classes (Pydantic) for validation — NOT serializers
3. `TenantMainMiddleware` MUST be position 0 in MIDDLEWARE (if multi-tenant)
4. Database engine: `django_tenants.postgresql_backend` (if multi-tenant)
5. Migrations: `migrate_schemas --shared` or `--tenant` — NEVER bare `migrate`
6. S3 keys namespaced by tenant: `{schema_name}/{uuid}/{filename}`
7. Presigned URLs expire after 15 minutes — NEVER serve files directly
8. Redis cache keys via `django_tenants.cache.make_key` — NEVER raw keys
9. AuditLog tracks EVERY state mutation — no silent changes
10. SessionAuth.csrf is True by default — do NOT pass csrf=True to NinjaAPI
11. Shared app tests: `django.test.TestCase`
12. Tenant app tests: `django_tenants.test.cases.TenantTestCase`
13. Frontend: Django templates + vanilla JS — NOT React/Vue/Angular
14. LLM output sanitized with `strip_tags()` before storage
15. Lambda invocation via `boto3.client("lambda").invoke()` — NEVER call LLM directly from Django
