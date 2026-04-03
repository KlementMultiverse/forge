# Autoresearch V2 — @requirements-analyst Results

**Date**: 2026-04-02
**Repos tested**: axum (Rust), chi (Go), drf (Django REST Framework), pydantic (Python), taxonomy (Next.js)

## Edge Case 1: Reverse-engineer requirements from axum routes (Rust)
**Repo**: axum

### Gap Found: No Rust-specific reverse-engineering patterns
The Reverse-Engineering Mode in the prompt covers ORM models and API routes but not Rust-specific patterns:
- Axum routes use extractors (`Path`, `Query`, `Json`, `State`) — each extractor implies a requirement
- `#[derive]` macros encode validation requirements (e.g., `#[serde(deny_unknown_fields)]`)
- Tower middleware layers encode cross-cutting requirements (auth, rate limiting, tracing)
- Error types with `IntoResponse` impl encode error handling requirements

### Gap Found: No trait-based requirement extraction
Rust's trait implementations ARE requirements. `impl FromRequest` = "this type is extractable from requests." The agent needs a pattern for reading trait impls as implicit requirements.

## Edge Case 2: Reverse-engineer requirements from chi middleware (Go)
**Repo**: chi

### Gap Found: No Go middleware chain requirement extraction
Chi's middleware pattern `func(http.Handler) http.Handler` encodes requirements in the chain order:
- Middleware ordering IS a requirement (e.g., auth before route matching)
- `chi.URLParam()` usage implies path parameter requirements
- Context values (`context.WithValue`) encode implicit dependency requirements
- The agent has no pattern for extracting requirements from Go's `context.Context` propagation

### Gap Found: No Go interface-as-contract pattern
Go interfaces define contracts. `chi.Router` interface methods = functional requirements. The agent should extract requirements from interface definitions.

## Edge Case 3: Extract DRF API requirements from viewsets
**Repo**: drf

### Gap Found: No DRF-specific viewset requirement extraction
DRF viewsets encode many requirements implicitly:
- `permission_classes` = authorization requirements
- `throttle_classes` = rate limiting requirements (ABSENT = zero protection, mark as [REQ-DEP-xxx])
- `filter_backends` = filtering/search requirements
- `pagination_class` = pagination requirements
- `serializer_class` = data validation requirements
- The agent's Reverse-Engineering Mode step 2 ("Read API routes/endpoints") is too generic for DRF's class-based pattern

### Gap Found: No "absent requirement" severity classification
When a viewset has `throttle_classes = ()` (like DRF's `ObtainAuthToken`), that's not just absent — it's a security requirement gap. The agent should classify absent requirements by risk level.

## Edge Case 4: Extract validation requirements from pydantic models
**Repo**: pydantic

### Gap Found: No Pydantic model-as-requirement pattern
Pydantic models ARE requirements specifications:
- Field types = data type requirements
- `Field(min_length=1, max_length=255)` = validation requirements with specific thresholds
- `@field_validator` = custom validation requirements
- `model_config = ConfigDict(strict=True)` = strictness requirements
- `Annotated[int, Gt(0)]` = constraint requirements
- The agent should extract these as [REQ-VAL-xxx] requirements

### Gap Found: No v1 vs v2 requirement migration tracking
When pydantic models use v1 patterns (e.g., `@validator` instead of `@field_validator`), these should be tagged as [REQ-MIG-xxx] migration requirements.

## Edge Case 5: Extract Next.js page requirements from app/ directory (taxonomy)
**Repo**: taxonomy

### Gap Found: No Next.js file-convention requirement extraction
Next.js App Router uses file conventions that ARE requirements:
- `page.tsx` = route requirement
- `layout.tsx` = persistent layout requirement
- `loading.tsx` = loading state requirement (ABSENT in taxonomy = missing UX requirement)
- `error.tsx` = error boundary requirement (ABSENT in taxonomy = missing resilience requirement)
- `not-found.tsx` = 404 handling requirement
- `middleware.ts` = request interception requirement
- The agent has no pattern for extracting requirements from file system conventions

### Gap Found: No "dual-router" conflict detection
Taxonomy has BOTH `pages/` and `app/` directories with overlapping routes. The agent should detect route conflicts between old and new patterns and flag them as [REQ-MIG-xxx].

## Summary of Gaps

| # | Gap | Severity | Fix Applied |
|---|-----|----------|-------------|
| 1 | No Rust trait-based requirement extraction | HIGH | YES |
| 2 | No Rust extractor-as-requirement pattern | MEDIUM | YES |
| 3 | No Go middleware chain requirement extraction | HIGH | YES |
| 4 | No Go interface-as-contract requirement pattern | MEDIUM | YES |
| 5 | No DRF viewset-specific requirement extraction | HIGH | YES |
| 6 | No absent requirement severity classification | HIGH | YES |
| 7 | No Pydantic model-as-requirement pattern | HIGH | YES |
| 8 | No v1→v2 migration requirement tracking for Pydantic | MEDIUM | YES |
| 9 | No Next.js file-convention requirement extraction | HIGH | YES |
| 10 | No dual-router conflict detection | MEDIUM | YES |

## Claude Code Pattern: Defense in Depth
From Claude Code's `bashSecurity.ts`, every validation has multiple layers: allowlist check, then denylist check, then semantic validation. Apply this to requirements: every extracted requirement should be validated at multiple levels (explicit in docs, implicit in code, absent but needed).
