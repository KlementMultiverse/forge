# REAL TEST: @root-cause-analyst on clinic-portal

## Input
"Tests expect 401 for unauthenticated API access but get 302 redirect instead"

## Root Cause Found
SafeTenantAccessMiddleware (position 8 in MIDDLEWARE) intercepts unauthenticated requests
and returns redirect("/login/") BEFORE Django Ninja's auth=django_auth can return 401.

## Evidence Chain
1. Middleware order: settings.py lines 88-100 — SafeTenantAccessMiddleware at position 8
2. Redirect code: middleware.py lines 41-43 — `return redirect("/login/")` for anonymous users
3. EXEMPT_PATHS: middleware.py line 24 — only `/api/auth/` exempt, all other `/api/*` caught
4. Django Ninja auth: workflow/api.py line 115 — `Router(auth=django_auth)` would return 401 but never runs

## Affected Tests: 10+ tests across 4 apps
- dashboard/tests.py:161
- search/tests.py:405,409,897,903
- tenants/tests.py:99
- users/tests.py:130,145,161,176
- workflows/tests.py:158 (already has workaround: assertIn [302, 401])

## Fix Proposed
Option A (recommended): Add "/api/" to EXEMPT_PATHS — let Django Ninja handle API auth
Option B: Return JsonResponse 401 for API paths instead of redirect

## Agent Quality Assessment
- Traced REAL request flow through middleware chain: ✓
- Found EXACT root cause with file:line: ✓
- Identified ALL affected tests: ✓
- Proposed TWO fix options with trade-offs: ✓
- Evidence-based (read actual code, not guessed): ✓

## Score: EXCELLENT — textbook root cause analysis
