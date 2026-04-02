# Forge Playbook — Strategies & Insights

## STRATEGIES & INSIGHTS

[str-001] helpful=5 harmful=0 :: Verify API parameters exist in library version before using them in code
[str-002] helpful=4 harmful=0 :: When improving a pattern in a service module, apply the improvement to ALL functions in that module
[str-003] helpful=5 harmful=0 :: LLM output must be sanitized with strip_tags() before storage — treat as untrusted input
[str-004] helpful=4 harmful=0 :: Every service function calling external APIs must have try/except for ClientError, timeout, and credentials errors
[str-005] helpful=3 harmful=0 :: Security middleware should be included from day 1, not added as a late patch
[str-006] helpful=3 harmful=0 :: Scope guards for AI endpoints should be designed upfront, not patched in after
[str-007] helpful=3 harmful=0 :: Demo/seed data should be comprehensive from the first implementation, not improved iteratively
[str-008] helpful=2 harmful=0 :: Admin UI customizations should be planned in the spec, not added as afterthoughts
[str-009] helpful=2 harmful=0 :: Keep deployment config separate from core build — different concerns, different phases

## COMMON MISTAKES TO AVOID

[mis-001] helpful=5 harmful=0 :: Never retry the same approach without understanding WHY it failed — investigate first
[mis-002] helpful=4 harmful=0 :: Never mix deployment artifacts (Railway, ngrok URLs) into core settings during initial build
[mis-003] helpful=3 harmful=0 :: Session cookies set to shared domain can leak across subdomains — use per-subdomain cookies
[mis-004] helpful=3 harmful=0 :: After 2 failed corrections on the same issue, start fresh with better prompt — don't keep iterating

## DOMAIN-SPECIFIC

[dom-001] helpful=4 harmful=0 :: django-ninja CSRF is per-auth-class (SessionAuth.csrf=True by default), NOT via NinjaAPI(csrf=True)
[dom-002] helpful=3 harmful=0 :: TenantMainMiddleware MUST be position 0 in MIDDLEWARE — no exceptions
[dom-003] helpful=3 harmful=0 :: S3 keys must be namespaced by tenant: {schema_name}/{uuid}/{filename}
[dom-004] helpful=3 harmful=0 :: Redis cache keys via django_tenants.cache.make_key — never raw keys
