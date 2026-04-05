# Django Stack Rules

## API
1. Django Ninja for ALL API routes — NEVER import `rest_framework`
2. Schema classes (Pydantic) for validation — NOT serializers
3. SessionAuth.csrf is True by default — do NOT pass csrf=True to NinjaAPI

## Database
4. Migrations: `migrate_schemas --shared` or `--tenant` (if multi-tenant) — NEVER bare `migrate`
5. Database engine: `django_tenants.postgresql_backend` (if multi-tenant)

## Frontend
6. Django templates + vanilla JS — NOT React/Vue/Angular
7. LLM output sanitized with `strip_tags()` before storage

## Testing
8. Run tests: `docker compose exec web uv run python manage.py test`
9. Shared app tests: `django.test.TestCase`
10. Tenant app tests: `django_tenants.test.cases.TenantTestCase` (if multi-tenant)

## Infrastructure
11. S3 keys namespaced by tenant: `{schema_name}/{uuid}/{filename}` (if multi-tenant)
12. Presigned URLs expire after 15 minutes — NEVER serve files directly
13. Redis cache keys via `django_tenants.cache.make_key` (if multi-tenant)
14. Lambda invocation via `boto3.client("lambda").invoke()` — NEVER call LLM directly from Django (if AI features)
