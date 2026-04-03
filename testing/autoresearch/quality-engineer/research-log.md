# Quality Engineer Agent — Autoresearch Log (Karpathy-Style)

Date: 2026-04-02
Agent: `/home/intruder/projects/forge/agents/universal/quality-engineer.md`
Method: 10-run evaluation across 4 diverse test repos

## Web Research Summary

Sources consulted:
- [Codepipes: Software Testing Anti-patterns](https://blog.codepipes.com/testing/software-testing-antipatterns.html)
- [testRigor: Anti-patterns in Software Testing](https://testrigor.com/blog/anti-patterns-in-software-testing/)
- [DZone: Unit Testing Anti-Patterns — Full List](https://dzone.com/articles/unit-testing-anti-patterns-full-list)
- [Real Python: Understanding the Python Mock Object Library](https://realpython.com/python-mock-library/)
- [GoDaddy: Making Mocking Mistakes in Python](https://www.godaddy.com/resources/news/python-mocking)

Key patterns the agent should detect:
1. **Wrong mock target** — patching where defined, not where used
2. **Excessive mocking** — so many mocks that the SUT isn't tested
3. **Test isolation failures** — shared state between tests, ordering dependencies
4. **Fixture bloat** — god fixtures that create entire database states
5. **Happy path only** — no error/edge/boundary testing
6. **Flaky selectors** — E2E tests using brittle CSS selectors
7. **Session-scoped DB fixtures** — data leaks between test modules
8. **Missing assertion on mock calls** — mock injected but never asserted
9. **Hardcoded timeouts** — `wait_for_timeout(1000)` instead of explicit waits
10. **Monorepo test orchestration gaps** — cross-package test dependencies, duplicated setup

---

## Run 1: clinic-portal — Mock Target Accuracy

**Files examined:**
- `/home/intruder/projects/clinic-portal/apps/documents/tests.py`
- `/home/intruder/projects/clinic-portal/apps/documents/api.py`
- `/home/intruder/projects/clinic-portal/apps/documents/services.py`

**Findings:**
1. **CORRECT mocks:** `@patch("apps.documents.services.get_s3_client")` on line 98 — patches where `get_s3_client` is used in `services.py`, which is correct because the test calls the endpoint which calls `generate_upload_url()` in services.
2. **POTENTIALLY WRONG mock:** `@patch("apps.documents.api.generate_download_url")` (line 237) and `@patch("apps.documents.api.delete_s3_object")` (line 264) — these patch the import in `api.py`, which IS correct because `api.py` does `from apps.documents.services import delete_s3_object, generate_download_url`. Patching at the import site (`api.`) is the right approach.
3. **CORRECT mocks:** `@patch("apps.documents.api.invoke_summarize_lambda")` — BUT `api.py` no longer uses `invoke_summarize_lambda`. It uses `_summarize_with_claude` defined inline. The mock target `apps.documents.api.invoke_summarize_lambda` would not actually intercept the real code path. **This is a STALE MOCK — the test passes but doesn't test the actual summarize flow.**
4. `@patch("apps.documents.services._invoke_llm")` in `GenerateTasksReflexionTest` and `SummarizeViaLlmTest` — correct, patches where defined and used in same module.

**Gap in prompt:** The agent has NO guidance on detecting stale mocks — mocks that target functions no longer called by the code under test. Tests pass (because mock prevents the real call) but don't actually validate anything meaningful.

---

## Run 2: saleor — Test Isolation, Database Fixtures, Conftest Patterns

**Files examined:**
- `/home/intruder/projects/forge-test-repos/saleor/conftest.py`
- `/home/intruder/projects/forge-test-repos/saleor/saleor/tests/fixtures.py`

**Findings:**
1. **Massive fixture system:** 1698 lines in `fixtures.py` alone, plus 50+ fixture plugin modules registered via `pytest_plugins`. This is a textbook "god fixture" anti-pattern — any test can pull in any fixture, making it unclear what a test actually depends on.
2. **Database multi-connection trick:** Line 20-22 forces `TransactionTestCase.databases` to include replica — clever but hides the fact that tests may accidentally depend on replica lag behavior.
3. **Slow test marking:** Has `@pytest.mark.slow` with `--run-slow` flag — good pattern, but the agent prompt doesn't mention test performance categorization.
4. **Custom CaptureQueriesContext** with IGNORED_QUERIES — tests explicitly filter out certain SQL queries from performance assertions. This is a sophisticated pattern the agent should recognize.
5. **No conftest-per-app pattern** — all fixtures centralized, which creates implicit coupling.

**Gap in prompt:** No guidance on evaluating fixture architecture (centralized vs distributed), fixture dependency depth, or detecting "god fixtures" that create too much state.

---

## Run 3: fastapi-template — Async Test Patterns, httpx Client Usage

**Files examined:**
- `/home/intruder/projects/forge-test-repos/fastapi-template/backend/tests/conftest.py`
- `/home/intruder/projects/forge-test-repos/fastapi-template/backend/tests/api/routes/test_items.py`
- `/home/intruder/projects/forge-test-repos/fastapi-template/backend/tests/api/routes/test_users.py`

**Findings:**
1. **Uses `TestClient` (sync) not `AsyncClient`** — FastAPI's TestClient wraps ASGI with sync calls. This means async middleware/dependencies are tested, but any bugs specific to async concurrency (race conditions, asyncio context vars) will NOT be caught. The agent should flag this.
2. **Session-scoped DB fixture** (conftest.py line 15-24) — `scope="session"` means ONE database session shared across ALL tests. Cleanup only runs at session end. If a test fails mid-way, data leaks to subsequent tests.
3. **Module-scoped client** — `scope="module"` means tests within a module share a client instance, but tests in `test_users.py` create users that persist and affect `test_items.py` count assertions (line 79 uses `>= 2` instead of exact count — a smell).
4. **No async test examples at all** — for a FastAPI template, this is a coverage gap. No `pytest-asyncio` usage, no `httpx.AsyncClient` tests.
5. **test_update_password_me** (line 224-264) — test modifies the superuser password then reverts it. This is fragile — if the revert fails, all subsequent tests using `superuser_token_headers` will break.

**Gap in prompt:** No guidance on sync vs async test client selection for async frameworks, no mention of fixture scope pitfalls, no guidance on detecting "modify-then-revert" anti-patterns.

---

## Run 4: medusa — Jest/Vitest Patterns, TypeScript Test Coverage Gaps

**Files examined:**
- `/home/intruder/projects/forge-test-repos/medusa/packages/modules/caching/src/utils/__tests__/parser.test.ts`
- `/home/intruder/projects/forge-test-repos/medusa/integration-tests/modules/__tests__/cart/store/carts.spec.ts`
- `/home/intruder/projects/forge-test-repos/medusa/integration-tests/modules/__tests__/order/order.spec.ts`

**Findings:**
1. **`jest.setTimeout(100000)` / `jest.setTimeout(50000)`** — 50-100 second timeouts per test suite. This is a red flag for slow integration tests but common in DB-heavy suites. Agent should flag and recommend categorization.
2. **Good unit test structure** in `parser.test.ts` — proper `beforeEach` setup, edge cases (null, undefined, primitives), nested entity testing, deduplication. This is a POSITIVE example the agent should recognize.
3. **Integration tests resolve modules from container** — proper DI pattern. But `beforeAll` does module resolution while `beforeEach` does admin user creation — mixing setup granularity.
4. **No type-level test assertions** — TypeScript tests don't use `expectTypeOf` or similar to verify type narrowing. For a typed monorepo, this is a gap.
5. **Cross-package test dependencies** — `carts.spec.ts` imports from `../../../../helpers/` — deep relative imports suggest test helpers aren't properly packaged.

**Gap in prompt:** No guidance for TypeScript/JS testing at all — the prompt is entirely Python/Django-centric. No mention of Jest patterns, type-level testing, or monorepo test organization.

---

## Run 5: clinic-portal — TenantTestCase Compliance, Schema Switching

**Files examined:**
- `/home/intruder/projects/clinic-portal/apps/workflows/tests.py`
- `/home/intruder/projects/clinic-portal/apps/dashboard/tests.py`
- `/home/intruder/projects/clinic-portal/apps/tenants/tests.py`
- `/home/intruder/projects/clinic-portal/apps/users/tests.py`

**Findings:**
1. **CORRECT TestCase selection:** Shared apps (tenants, users) use `django.test.TestCase`. Tenant apps (workflows, documents, dashboard) use `TenantTestCase`. All compliant.
2. **Duplicated `_ensure_public_tenant()` helper** — defined separately in every test file (documents, workflows, dashboard, users, search) with slightly different owner emails. Should be a shared fixture.
3. **Schema switching in setUp** — `connection.set_schema_to_public()` then `connection.set_tenant()` pattern is correct but relies on tearDown of TenantTestCase to restore. If a test crashes mid-setUp, schema could leak.
4. **`get_test_schema_name()` and `get_test_tenant_domain()`** overrides in TaskEndpointTest and GenerateTasksEndpointTest — needed to avoid schema collision. Agent should flag when these are MISSING (potential parallel test failures).
5. **No negative test for cross-tenant data leakage** — tests verify single-tenant behavior but never create two tenants and verify isolation at the ORM level.

**Gap in prompt:** No guidance on multi-tenant testing patterns — schema isolation verification, helper deduplication, parallel-safe tenant naming.

---

## Run 6: saleor — GraphQL Test Patterns

**Files examined:**
- `/home/intruder/projects/forge-test-repos/saleor/saleor/graphql/payment/tests/mutations/test_checkout_payment_create.py`
- `/home/intruder/projects/forge-test-repos/saleor/saleor/tests/e2e/promotions/test_promotions_query_with_different_parameters.py`

**Findings:**
1. **GraphQL mutation strings defined as module constants** — `CREATE_PAYMENT_MUTATION` on line 23. Good pattern for reuse, but no schema validation that the mutation string matches the actual schema.
2. **Given/When/Then comments** in `test_checkout_add_payment_without_shipping_method_and_not_shipping_required` — excellent test structure documentation pattern.
3. **E2E tests use `@pytest.mark.e2e` marker** — allows separate CI pipeline for slow E2E. Good categorization.
4. **Fixture-heavy test signatures** — `user_api_client, checkout_without_shipping_required, address` — tests depend on complex fixture chains that are hard to trace.
5. **No snapshot testing** — GraphQL responses are manually asserted field-by-field. For large mutation responses, snapshot testing would catch regression better.

**Gap in prompt:** No guidance on GraphQL-specific test patterns (mutation string validation, snapshot testing, given/when/then structure, test markers for categorization).

---

## Run 7: fastapi-template — Dependency Injection in Tests, Override Patterns

**Files examined:**
- `/home/intruder/projects/forge-test-repos/fastapi-template/backend/tests/api/routes/test_login.py`
- `/home/intruder/projects/forge-test-repos/fastapi-template/backend/tests/scripts/test_test_pre_start.py`

**Findings:**
1. **No `app.dependency_overrides` usage anywhere** — FastAPI's primary DI override mechanism for testing is completely unused. All tests use real database, real CRUD. This means tests cannot isolate service layers.
2. **`patch()` used for SMTP settings** (test_users.py line 40-44) — patches individual settings instead of using FastAPI dependency injection. Fragile.
3. **Pre-start script test** (test_test_pre_start.py) — mocks Session, select, and logger. Good isolation but the mock structure is complex for a simple connectivity check.
4. **Password hash upgrade tests** (test_login.py lines 129-191) — excellent edge case testing for bcrypt-to-argon2 migration. Tests both upgrade path AND idempotency. Agent should recognize this as a model pattern.
5. **No TestClient context manager cleanup** — `yield c` in conftest but no explicit cleanup of test-created data per test.

**Gap in prompt:** No guidance on FastAPI `dependency_overrides`, no mention of DI testing patterns for any framework, no guidance on evaluating framework-specific test utilities.

---

## Run 8: medusa — Monorepo Test Orchestration

**Files examined:**
- `/home/intruder/projects/forge-test-repos/medusa/integration-tests/modules/jest.config.js`
- `/home/intruder/projects/forge-test-repos/medusa/jest.config.js` (root)

**Findings:**
1. **Separate jest configs per integration test type** — `modules/`, `http/`, `api/` each have their own config. Good separation.
2. **`testPathIgnorePatterns`** excludes fixtures directories — proper separation of test data from test code.
3. **`setupFiles: ["../setup-env.js"]`** — environment setup shared across test suites. Good pattern.
4. **Deep `../../../../helpers/` imports** in spec files — no package-level test utility exports. This creates fragile path dependencies.
5. **No test sharding configuration** — for a large monorepo, no jest `--shard` or `projects` config for parallel execution.

**Gap in prompt:** No guidance on monorepo-specific test orchestration, test sharding, or shared helper packaging.

---

## Run 9: clinic-portal — E2E Test Quality (Playwright)

**Files examined:**
- `/home/intruder/projects/clinic-portal/tests/e2e/conftest.py`
- `/home/intruder/projects/clinic-portal/tests/e2e/test_frontend_flows.py`
- `/home/intruder/projects/clinic-portal/tests/e2e/test_all_flows.py`

**Findings:**
1. **FLAKY SELECTORS in test_frontend_flows.py** — line 33: `'input[name="email"], input[type="email"], #email'` uses OR-chained CSS selectors as fallback. This is a smell — it means the author wasn't sure which selector would work.
2. **Hardcoded timeouts** — `page.wait_for_timeout(1000)` on line 36 of test_frontend_flows.py. Should use `page.wait_for_url()` or `expect()` with auto-wait.
3. **BETTER in test_all_flows.py** — uses `page.wait_for_url(lambda url: "/login" not in url, timeout=5000)` (line 53) and Playwright's `expect()` API. But still has `page.fill("#email", email)` which relies on exact ID.
4. **Two duplicate E2E test files** — `test_frontend_flows.py` and `test_all_flows.py` test overlapping flows. The former uses loose selectors, the latter uses tighter ones. One should be deleted.
5. **No page object model** — selectors are scattered throughout test methods instead of being encapsulated in page objects.
6. **Minimal conftest** — only sets `ignore_https_errors`. No base URL configuration, no authentication fixture, no screenshot-on-failure.

**Gap in prompt:** No E2E-specific guidance at all — no mention of page object model, selector quality, explicit waits vs timeouts, screenshot on failure, duplicate test detection.

---

## Run 10: saleor — Test Performance

**Files examined:**
- `/home/intruder/projects/forge-test-repos/saleor/conftest.py` (slow test marking)
- `/home/intruder/projects/forge-test-repos/saleor/saleor/tests/fixtures.py` (CaptureQueriesContext)

**Findings:**
1. **`@pytest.mark.slow` with `--run-slow` flag** — explicit slow test categorization. Tests marked slow are SKIPPED by default. Excellent pattern.
2. **Custom `CaptureQueriesContext`** — extends Django's query capture to filter out noise queries. Used to assert N+1 query prevention. This is a performance-aware testing pattern the agent should recommend.
3. **1698-line fixtures file** — fixture creation overhead itself is a performance concern. Tests that pull in heavy fixtures (full product catalog, payment gateways) are inherently slow.
4. **No test parallelization config** — `conftest.py` doesn't configure `pytest-xdist` or any parallel runner.
5. **`_fixture_teardown` override** (line 98-100) — custom teardown to handle foreign key constraints during TRUNCATE. Indicates DB cleanup is expensive.

**Gap in prompt:** No guidance on test performance assessment — N+1 detection, slow test categorization, query count assertions, parallel execution, fixture optimization.

---

## Summary of ALL Gaps Found

| # | Gap Category | Found In Runs | Severity |
|---|---|---|---|
| G1 | Stale mock detection (mock targets unreachable code) | Run 1 | HIGH |
| G2 | Fixture architecture evaluation (god fixtures, duplication) | Run 2, 5 | HIGH |
| G3 | Async vs sync test client guidance | Run 3 | MEDIUM |
| G4 | Fixture scope pitfalls (session/module leak) | Run 3 | HIGH |
| G5 | Modify-then-revert anti-pattern | Run 3 | MEDIUM |
| G6 | TypeScript/JS testing guidance (Jest, type-level) | Run 4, 8 | HIGH |
| G7 | Multi-tenant testing patterns | Run 5 | HIGH |
| G8 | Cross-tenant isolation verification | Run 5 | HIGH |
| G9 | GraphQL-specific test patterns | Run 6 | MEDIUM |
| G10 | Test categorization (markers, slow/fast split) | Run 6, 10 | MEDIUM |
| G11 | Framework DI override patterns (FastAPI, Django Ninja) | Run 7 | MEDIUM |
| G12 | Monorepo test orchestration | Run 8 | LOW |
| G13 | E2E test quality (POM, selectors, waits, screenshots) | Run 9 | HIGH |
| G14 | Duplicate/overlapping test detection | Run 9 | MEDIUM |
| G15 | Test performance assessment (N+1, query count, parallelism) | Run 10 | HIGH |
| G16 | Given/When/Then structure recommendation | Run 6 | LOW |
