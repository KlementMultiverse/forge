# @quality-engineer — Autoresearch V2 Edge Cases

## Research Sources
- "Testing-library: avoid these mistakes in async tests" (Dev.to)
- "Async Testing with Pytest: Mastering pytest-asyncio" (Medium)
- Edge case testing methodology (SoftwareTestingMaterial, Virtuoso QA)
- pytest-asyncio event loop gotchas

## Edge Case Tests

### Test 1: axum — Rust testing (async test fixtures, mock tower services, test isolation)

**Input**: Analyze axum's test patterns for edge cases.

**Findings**:
- **GAP FOUND**: Agent prompt's test quality checklist is Python-focused (mock patching, fixtures, conftest). No Rust testing patterns:
  - **Async test setup**: `#[tokio::test]` vs `#[tokio::test(flavor = "multi_thread")]` — wrong flavor = different behavior
  - **Tower service mocking**: Creating mock `Service` implementations for middleware testing — complex trait bounds
  - **Test isolation**: Rust tests run in parallel by default — shared state (DB, files) requires `#[serial]` or per-test setup
  - **Compile-time testing**: `compile_fail` tests verify that invalid code doesn't compile — unique to Rust
- **EDGE CASE**: axum's SSE tests use `unwrap()` extensively in test code — acceptable in tests but agent should distinguish test `unwrap()` from production `unwrap()`.

**Recommendation**: Add Rust testing patterns.

### Test 2: chi — Go testing (httptest patterns, table-driven tests, race condition testing)

**Input**: Analyze chi's test patterns.

**Findings**:
- **GAP FOUND**: Agent prompt has no Go testing patterns:
  - **httptest.NewRecorder**: Standard pattern for testing HTTP handlers — agent should verify this is used correctly
  - **Table-driven tests**: `[]struct{ name, input, expected }` pattern — Go idiom, agent should flag non-table tests for similar cases
  - **Race detection**: `go test -race` flag — critical for concurrent code, agent should verify CI runs with `-race`
  - **TestMain**: `func TestMain(m *testing.M)` for test setup/teardown — agent should check for proper cleanup
- **EDGE CASE**: chi's `throttle_test.go` spawns goroutines in tests (lines 42, 80, 113, 128, 166, 186, 233, 287) — these need proper synchronization or test can pass with goroutine leaks.

**Recommendation**: Add Go testing quality patterns.

### Test 3: drf — DRF (APITestCase vs TestCase, factory patterns, auth in tests)

**Input**: Analyze DRF testing edge cases.

**Findings**:
- **GAP FOUND**: Agent prompt mentions "schema/tenant isolation" for multi-tenant but doesn't cover DRF-specific test issues:
  - **APITestCase transaction behavior**: DRF's `APITestCase` wraps tests in transactions differently than Django's `TestCase` — can cause false positives when testing DB constraints
  - **force_authenticate vs login**: `self.client.force_authenticate(user)` bypasses all auth middleware — tests may pass but production fails
  - **APIClient vs Client**: DRF's `APIClient` handles JSON encoding; Django's `Client` doesn't — mixing them causes subtle test failures
- **EDGE CASE**: DRF's `throttle_test` would need to be time-aware — throttle tests that depend on timing can flake in CI.

**Recommendation**: Add DRF-specific test quality patterns.

### Test 4: pydantic — Property-based testing with Hypothesis, model fuzzing

**Input**: Analyze pydantic testing edge cases.

**Findings**:
- **GAP FOUND**: Agent prompt has no property-based testing guidance:
  - **Hypothesis + pydantic**: `hypothesis.strategies.from_type(MyModel)` generates random valid instances — catches edge cases human testers miss
  - **Roundtrip testing**: `model.model_dump() → Model.model_validate()` should be identity for all valid inputs
  - **Coercion boundary testing**: Test with inputs at coercion boundaries (`"1"` vs `1` vs `1.0` for IntField)
  - **Union discrimination**: Test with inputs that match multiple union members — verify correct member selected
- **EDGE CASE**: pydantic v2's Rust core makes property-based testing more valuable — Python-level fuzzing can find edge cases where the Rust validation differs from Python expectations.

**Recommendation**: Add property-based testing patterns for pydantic models.

### Test 5: taxonomy — Next.js (testing server components, MSW patterns, E2E with Playwright)

**Input**: Analyze taxonomy testing patterns.

**Findings**:
- **CRITICAL GAP FOUND**: taxonomy has NO test files at all. Zero tests. Agent prompt should flag "no tests" as highest severity finding.
- **GAP FOUND**: Agent prompt has no Next.js-specific test patterns:
  - **Server Component testing**: Cannot use `render()` from testing-library — need `renderServerComponent` or E2E
  - **MSW for API mocking**: Mock Service Worker for intercepting fetch in Server Components
  - **Playwright for E2E**: App Router's streaming SSR needs `waitForLoadState('networkidle')` — standard `waitForSelector` may be insufficient
  - **Server Action testing**: Actions need to be tested via form submission, not direct function calls
- **GAP FOUND**: Agent prompt's "cross-tenant verification" test pattern is Django-specific. No equivalent for Next.js auth boundary testing.

**Recommendation**: Add Next.js testing patterns and "zero test" detection as critical finding.

## Gaps Found in Agent Prompt

1. **No Rust testing patterns** (tokio test flavors, compile_fail tests, Service mocking)
2. **No Go testing patterns** (httptest, table-driven, race detection, TestMain)
3. **No DRF-specific test patterns** (APITestCase vs TestCase, force_authenticate gotcha)
4. **No property-based testing guidance** (Hypothesis + pydantic, roundtrip testing)
5. **No Next.js testing patterns** (Server Component testing, MSW, streaming SSR E2E)
6. **"Zero tests" detection** not explicitly called out as critical finding
