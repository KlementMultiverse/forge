# REAL TEST: @quality-engineer on clinic-portal

## Input
"Analyze test coverage and quality"

## Real Findings

### Test Inventory: 280 total methods
- 141 unit/integration tests across 6 apps
- 139 E2E tests (Playwright) across 3 files

### TenantTestCase Compliance: 100% PASS
All 4 tenant apps (dashboard, documents, workflows, search) use TenantTestCase.
Both shared apps (tenants, users) use standard TestCase.

### CRITICAL Finding: Wrong mock target
- `apps/documents/tests.py` lines 301, 329 patch `invoke_summarize_lambda`
- But endpoint actually calls `_summarize_with_claude` (defined locally in api.py)
- Tests pass VACUOUSLY — mock creates new attribute, real function still runs
- Fix: patch `apps.documents.api._summarize_with_claude` instead

### Other Findings
- Duplicated test helpers in 4 files (_ensure_public_tenant, _create_owner_user)
- Dashboard tests thin (only 3 methods)
- No shared conftest.py for Django unit tests

## Agent Quality Assessment
- Counted REAL test methods: ✓
- Found REAL bug (wrong mock target): ✓ (same bug code-archaeologist found earlier)
- TenantTestCase compliance verified correctly: ✓
- Specific file:line references: ✓

## Score: EXCELLENT — found a real bug with evidence
