# Test: @django-tenants-agent — Run 1/10

## Input
Create Tenant, Domain, and User models with correct base classes and middleware config

## Score: 17/17 applicable (100%) — after fixes

### Core (items 1-15)
1. Single responsibility: PASS — "Specialist for django-tenants + django-tenant-users multi-tenancy"
2. Forge Cell referenced: PASS — DJANGO-TENANTS-specific (7-step with TenantTestCase, migrate_schemas, middleware verification)
3. context7 MCP: PASS — MANDATORY steps with exact function calls (resolve-library-id, query-docs)
4. Web search: PASS — step 2 "web search django-tenants schema isolation [current year]"
5. Self-executing: PASS — migration commands, middleware assertion via Python, test commands
6. Handoff protocol: PASS — 6-field
7. [REQ-xxx]: PASS — step 6
8. Per-agent judge: PASS
9. Specific rules: PASS — 5 CRITICAL rules in system-reminder, On Activation mandatory steps
10. Failure escalation: PASS — migration error → check SHARED vs TENANT, schema not found → check --shared ran first
11. /learn: PASS — "version-specific behavior → /learn", "cache key isolation → /learn"
12. Anti-patterns: PASS — 6 items all django-tenants-specific
13-15: N/A (but agent itself IS the tenant expert, so it naturally covers these)

### New (items 16-20)
16. Confidence routing: PASS — added
17. Self-correction loop: PASS — added
18. Negative instructions near end: PASS — anti-patterns at very end
19. Tool failure handling: PASS — added
20. Chaos resilience: PASS — failure escalation covers common error scenarios

## STRENGTH
The most operationally detailed Django agent. On Activation has MANDATORY context7 calls with
exact MCP function names. System-reminder with 5 CRITICAL rules. Failure escalation maps
errors to root causes. CLAUDE.md rule citation is REQUIRED.

## Verdict: EXCELLENT — PERFECT SCORE (100%)
