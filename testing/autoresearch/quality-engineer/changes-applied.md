# Changes Applied to quality-engineer.md

Date: 2026-04-02
Based on: 10-run autoresearch across 4 repos

## New Sections Added

### Test Quality Checklist (7 categories)
The core addition. A systematic checklist the agent must run on every audit:

1. **Mock Accuracy** — stale mock detection, patch-where-used rule, autospec, assertion requirements
2. **Fixture Architecture** — god fixture detection (>500 lines), helper duplication, scope evaluation, modify-then-revert detection
3. **Test Isolation** — data leak detection (`>=` assertions), tenant schema isolation, cross-tenant verification, cache clearing
4. **E2E Test Quality** — selector quality, explicit waits vs timeouts, page object model, screenshot on failure, duplicate detection
5. **Test Performance** — slow test categorization, N+1 query detection, fixture optimization, parallelization readiness
6. **Framework-Specific Patterns** — Django, FastAPI, TypeScript/Jest, GraphQL (each with concrete patterns found in real repos)
7. **Multi-Tenant Testing** — unique schema naming, cross-tenant isolation tests, shared helper consolidation, schema leak prevention

### Framework-Specific Subsections
- **Python/Django**: TestCase vs TenantTestCase, override_settings, migration compatibility
- **Python/FastAPI**: AsyncClient vs TestClient, dependency_overrides, pytest-asyncio
- **TypeScript/Jest**: timeout thresholds, type-level assertions, monorepo helper packaging
- **GraphQL**: schema validation, Given/When/Then, snapshot testing, E2E markers

## Modified Sections

### Triggers
Added: "Test quality audit (mock accuracy, fixture health, E2E reliability, performance)"

### Behavioral Mindset
Added: "Treat test code with the same rigor as production code — test quality IS code quality."

### Focus Areas
Added 4 new focus areas: Mock Accuracy, Fixture Health, E2E Reliability, Test Performance

### Key Actions
Added: "Audit Test Quality: Run the Test Quality Checklist against existing tests"

### Forge Cell Compliance
Added step 9: "RUN Test Quality Checklist against all written tests — fix issues before handoff"

### Handoff Protocol
Added: "Test Quality Audit" field to handoff template

### Self-Correction Loop
Added step 4: "Run Test Quality Checklist mentally against your own test code"

### Chaos Resilience
Added: stale mock detection, god fixture detection

### Anti-Patterns
Added 6 new anti-patterns:
- No `wait_for_timeout()` in E2E
- Patch where imported, not defined
- Mock without assertions
- No `scope="session"` for mutable DB fixtures
- No copy-paste helpers
- No `>= N` when exact count is knowable

## Gaps Addressed

All 16 gaps from the research log are covered:
- G1 (stale mocks) → Mock Accuracy checklist
- G2 (god fixtures) → Fixture Architecture checklist
- G3 (async client) → FastAPI framework section
- G4 (scope leaks) → Fixture Architecture checklist
- G5 (modify-revert) → Fixture Architecture checklist
- G6 (TS/JS) → TypeScript/Jest framework section
- G7-G8 (multi-tenant) → Multi-Tenant Testing section
- G9 (GraphQL) → GraphQL framework section
- G10 (categorization) → Test Performance checklist
- G11 (DI overrides) → FastAPI framework section
- G12 (monorepo) → TypeScript/Jest framework section
- G13 (E2E quality) → E2E Test Quality checklist
- G14 (duplicates) → E2E Test Quality checklist
- G15 (performance) → Test Performance checklist
- G16 (Given/When/Then) → GraphQL framework section
