# REAL TEST: @learning-guide on clinic-portal

## Input
"Explain multi-tenancy to a developer who has never used django-tenants"

## Output Quality Assessment

### Teaching Structure: EXCELLENT
1. Started with analogy (office building with private floors) ✓
2. Progressive complexity: concept → models → settings → middleware → testing ✓
3. Used REAL code from clinic-portal (not generic examples) ✓
4. Explained WHY at each step (not just WHAT) ✓

### Real Code References Used:
- apps/tenants/models.py — Tenant(TenantBase), Domain(DomainMixin), auto_create_schema
- config/settings.py — SHARED_APPS vs TENANT_APPS, DATABASE_ROUTERS, ROOT_URLCONF
- apps/tenants/middleware.py — TenantMainMiddleware, FlexibleTenantMiddleware, SafeTenantAccessMiddleware
- apps/workflows/tests.py — TenantTestCase, TenantClient, setup_tenant, schema switching

### Technical Accuracy: 100%
- Correctly explained SET search_path TO mechanism ✓
- Correctly explained why contentypes appears in both lists ✓
- Correctly explained FlexibleTenantMiddleware session fallback ✓
- Correctly showed request lifecycle (5 steps with SQL) ✓
- Correctly explained why TenantTestCase is slower ✓

### Key Insight Delivered
"Your view code is completely unaware of multi-tenancy. You never write
Workflow.objects.filter(tenant=current_tenant). The schema isolation happens
transparently at the database connection level."

## Score: EXCELLENT — best teaching output in the test suite, uses real code throughout
