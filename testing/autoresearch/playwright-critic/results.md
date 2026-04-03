# Playwright Critic Agent - Autoresearch Results (10 Runs)

**Date:** 2026-04-02
**Agent:** /home/intruder/projects/forge/agents/universal/playwright-critic.md

---

## Run 1: clinic-portal tests/e2e/test_frontend_flows.py — Flakiness Audit

**Input:** Audit existing E2E tests for flakiness patterns.

**Findings:**
- `wait_for_timeout(1000)` used 32 times across this file alone — hard-coded sleeps are the #1 flakiness source
- `login_as()` helper uses `wait_for_timeout(1000)` instead of waiting for navigation or DOM state
- Multiple assertions use `page.content()` string matching (e.g., `"dashboard" in content.lower()`) — fragile, breaks if text changes
- `test_create_workflow` uses conditional logic (`if create_btn.count() > 0`) — test silently passes even if the element doesn't exist
- No `expect()` from Playwright used anywhere — all bare `assert` statements
- No screenshot capture on failure
- No mobile viewport testing

**Gaps Found in Agent Prompt:**
1. Agent says "use `expect()` assertions" but doesn't explain the critical difference: `expect()` auto-retries with timeout, bare `assert` does not
2. No guidance on replacing `wait_for_timeout` with event-based waits (`wait_for_url`, `wait_for_selector`, `wait_for_load_state("networkidle")`)
3. No pattern for "conditional test that silently passes" anti-pattern detection
4. No guidance on network request interception to wait for API responses

---

## Run 2: clinic-portal tests/e2e/test_all_flows.py — wait_for_timeout Analysis

**Input:** Check for wait_for_timeout anti-patterns.

**Findings:**
- 42 occurrences of `wait_for_timeout` in test_all_flows.py
- 32 occurrences in test_frontend_flows.py
- 27 occurrences in test_clinical_search.py
- **Total: 101 wait_for_timeout calls across 3 test files**
- Better patterns exist in test_all_flows.py: uses `wait_for_url(lambda url: "/login" not in url, timeout=5000)` in `login()` helper — but other tests still use `wait_for_timeout(1500)` after navigation
- `login_api()` helper shows awareness of CSRF handling (good) but still uses `wait_for_timeout` in related tests

**Replacement Patterns (should be in prompt):**
```python
# BAD: page.wait_for_timeout(1500)
# GOOD: page.wait_for_load_state("networkidle")
# GOOD: page.wait_for_url(lambda u: "/dashboard" in u)
# GOOD: expect(page.locator("#data")).to_be_visible()
# GOOD: page.wait_for_response("**/api/workflows/")
```

**Gap:** Agent prompt mentions `wait_for_selector` and `wait_for_load_state` but does NOT mention `wait_for_response` or `wait_for_url` — critical for API-driven SPAs.

---

## Run 3: saleor — E2E Test Infrastructure Analysis

**Input:** Analyze saleor's E2E test infrastructure.

**Findings:**
- Saleor has extensive E2E tests under `saleor/tests/e2e/` organized by domain (account, checkout, channel, etc.)
- Tests are API-based (GraphQL mutations), NOT browser-based Playwright tests
- Uses `pytest.mark.e2e` marker for selective execution
- Tests use utility functions that wrap GraphQL operations (e.g., `checkout_create_from_order()`, `prepare_product()`, `assign_permissions()`)
- Pattern: setup with utility functions, assert on GraphQL response structure, no browser interaction
- NO `wait_for_timeout` anywhere — all tests are synchronous API calls
- Each test file tests ONE specific flow end-to-end (e.g., `test_checkout_create_from_order_core_0104`)

**Key Pattern for Agent:**
- Saleor's E2E tests are integration tests against the API, not browser tests
- Agent prompt assumes all E2E = Playwright browser tests — needs guidance for API-only E2E testing
- The utility-wrapper pattern (abstracting API calls into reusable functions) is a best practice the agent should recommend

**Gap:** Agent prompt is 100% browser-focused. No guidance for when E2E tests should use API calls instead of browser automation.

---

## Run 4: fastapi-template — Frontend Testing Approach

**Input:** Analyze frontend testing patterns.

**Findings:**
- Frontend tests in `frontend/tests/` use Playwright TypeScript (not Python)
- Uses `data-testid` attributes exclusively: `page.getByTestId("email-input")`, `page.getByTestId("user-menu")`
- Uses `page.getByRole()` for buttons and links — accessible selectors
- Uses `page.waitForURL()` instead of `wait_for_timeout` — event-based waiting
- Uses `storageState` for auth state management (avoids re-login)
- Clean separation: `auth.setup.ts` handles authentication once, tests reference stored state
- No `wait_for_timeout` anti-pattern at all

**Key Patterns Missing from Agent Prompt:**
1. `getByTestId()` / `data-testid` pattern — agent mentions it but doesn't show HOW to recommend adding them to templates
2. `getByRole()` for accessibility-first selectors
3. Auth state persistence via `storageState` — massive speedup for test suites
4. `fillForm()` helper pattern — reusable form filling utility

**Gap:** Agent says "use data-testid or role selectors" but doesn't provide a migration strategy for existing CSS selector-heavy tests.

---

## Run 5: medusa — Integration Test Patterns

**Input:** Analyze integration-tests/ directory.

**Findings:**
- Integration tests under `integration-tests/api/__tests__/` organized by domain (admin/, store/, taxes/, etc.)
- Uses Jest, not Playwright
- Factory pattern for test data: `simple-product-factory.ts`, `simple-order-factory.ts`, etc.
- Environment helpers: `bootstrap-app.js`, `setup-server.js`, `use-api.js` — complete test infrastructure
- Tests are `.js.txt` files (archived/disabled?) — suggests migration or deprecation in progress
- Snapshot testing used for complex response structures (`.snap` files)
- Each test module has its own `__tests__` directory within the package — tests live close to code

**Key Pattern:**
- Monorepo integration tests need cross-package test coordination
- Factory pattern creates realistic test data without hardcoding
- Environment helpers abstract away server setup/teardown

**Gap:** Agent prompt has no guidance for:
1. Monorepo testing strategies (testing across package boundaries)
2. Factory pattern for test data generation
3. Snapshot testing for API response validation
4. When to use archived tests vs active tests

---

## Run 6: clinic-portal — Login Flow E2E Test (Selector Audit)

**Input:** Write login flow E2E test, checking what selectors work.

**Analysis of Current Selectors:**
- `test_frontend_flows.py` uses broad CSS selectors: `input[name="email"], input[type="email"], #email` (3 fallbacks)
- `test_all_flows.py` uses specific IDs: `#email`, `#password` (cleaner)
- Both have login helpers but with different strategies (wait_for_timeout vs wait_for_url)
- No `data-testid` attributes found in templates
- Login form relies on `#email` and `#password` IDs plus `button[type="submit"]`

**Recommended Test Pattern:**
```python
def test_login_flow(page: Page):
    page.goto(f"{CLINIC}/login/")
    page.fill("#email", ADMIN_EMAIL)
    page.fill("#password", ADMIN_PASS)
    page.click('button[type="submit"]')
    page.wait_for_url(lambda u: "/login" not in u, timeout=5000)
    expect(page).not_to_have_url(re.compile(r"/login"))
    expect(page.locator("nav")).to_contain_text("Sunrise")
```

**Gap:** Agent prompt doesn't address the real-world scenario of auditing EXISTING selectors and recommending improvements. It assumes writing tests from scratch.

---

## Run 7: clinic-portal — Workflow CRUD E2E Scenario

**Input:** Write workflow CRUD E2E test scenario.

**Analysis:**
- Current workflow create test uses conditional logic that silently skips if elements don't exist
- No test for workflow UPDATE or DELETE operations
- Workflow detail test clicks "Patient Intake" but doesn't verify task count or task data structure
- No test verifies the AI task generation feature (Generate Tasks button)

**Missing Coverage:**
1. Workflow edit/update flow
2. Workflow delete flow (if supported)
3. AI task generation flow
4. Workflow search/filter
5. Empty state (no workflows)
6. Pagination if many workflows exist

**Gap:** Agent prompt says "test ALL interactive elements" but provides no checklist for CRUD coverage completeness.

---

## Run 8: clinic-portal conftest.py — Setup/Teardown Review

**Input:** Review test setup/teardown.

**Findings:**
- `conftest.py` is minimal — only sets `ignore_https_errors: True`
- No test user creation/cleanup
- No database seeding or state reset between tests
- No `base_url` configuration (hardcoded in test files)
- No screenshot-on-failure fixture
- No video recording configuration
- No parallel test isolation

**Critical Missing Fixtures:**
1. `base_url` fixture for environment-agnostic URLs
2. Screenshot capture on test failure
3. Test data cleanup after each test class
4. Browser viewport configuration for responsive testing
5. API request context for authenticated API calls

**Gap:** Agent prompt doesn't address conftest.py configuration patterns or mandatory fixtures for reliable E2E testing.

---

## Run 9: medusa — Cross-Package Integration Patterns

**Input:** Analyze cross-package integration test patterns.

**Findings:**
- Medusa's `integration-tests/environment-helpers/` provides shared infrastructure:
  - `bootstrap-app.js` — starts full application
  - `setup-server.js` — configures test server
  - `use-api.js` — provides API client
  - `use-container.js` — dependency injection container for tests
- Tests verify event emission across modules (e.g., `events.spec.ts` in product module)
- Uses `eventBus.emit()` pattern for cross-module communication testing
- Factory pattern centralizes test data creation

**Gap:** Agent prompt has no guidance for testing event-driven architectures or cross-module communication patterns.

---

## Run 10: clinic-portal — Document Upload E2E with File Handling

**Input:** Write document upload E2E test with file handling.

**Analysis:**
- Current `test_upload_button_exists` only checks button presence
- `test_presigned_upload_url_api` tests the API but not the actual upload flow through the UI
- No test actually uploads a file via the file input
- Document upload involves: file input -> presigned URL request -> S3 upload -> document creation -> page refresh

**Required Test Pattern:**
```python
def test_document_upload_flow(page: Page):
    login(page, ADMIN_EMAIL, ADMIN_PASS)
    page.goto(f"{CLINIC}/documents/")
    # Playwright file upload pattern:
    file_input = page.locator('input[type="file"]')
    file_input.set_input_files("tests/e2e/fixtures/test.pdf")
    # Wait for presigned URL request
    with page.expect_response("**/api/documents/upload-url") as resp:
        page.click('button:has-text("Upload")')
    # Verify upload completed
    expect(page.locator("text=test.pdf")).to_be_visible()
```

**Gap:** Agent prompt mentions file handling nowhere. `set_input_files()` is a critical Playwright API for file upload testing.

---

## Summary of ALL Gaps Found

| # | Gap | Severity | Fix |
|---|-----|----------|-----|
| 1 | No `wait_for_response` / `wait_for_url` patterns | HIGH | Add to Rules section |
| 2 | No guidance for API-only E2E testing | HIGH | Add new section |
| 3 | No `storageState` auth persistence pattern | MEDIUM | Add to Common Mistakes |
| 4 | No file upload (`set_input_files`) guidance | HIGH | Add to Rules |
| 5 | No conftest.py fixture patterns | HIGH | Add new section |
| 6 | No factory pattern for test data | MEDIUM | Add to best practices |
| 7 | No CRUD coverage checklist | MEDIUM | Add to MAP section |
| 8 | Conditional test silently passing anti-pattern | HIGH | Add to Anti-Patterns |
| 9 | No monorepo/cross-package testing guidance | LOW | Add note |
| 10 | No event-driven testing guidance | LOW | Add note |
| 11 | `expect()` vs bare `assert` not explained | HIGH | Expand Rules |
| 12 | No selector migration strategy | MEDIUM | Add to Common Mistakes |
