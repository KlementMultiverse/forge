# @backend-architect — Autoresearch V2 Edge Cases

## Research Sources
- "Serverless and Edge Are Eating the Backend in 2025" (Dev.to)
- "Clean Architecture Design Guide for Backend API" (Naskay)
- "After 50 Production Incidents" failure pattern guide

## Edge Case Tests

### Test 1: axum — Rust backend (error handling with thiserror/anyhow, state management)

**Input**: Scan axum for error handling patterns and state management.

**Findings**:
- **GAP FOUND**: Agent prompt's API Design checklist focuses on HTTP status codes and pagination but has no Rust-specific guidance:
  - Error type strategy: `thiserror` (library) vs `anyhow` (application) — mixing them is an anti-pattern
  - State management: `axum::extract::State` for shared app state — agent should verify state is `Send + Sync + Clone`
  - Extractor ordering: extractors consuming the request body must come last — agent has no extraction ordering check
- **EDGE CASE**: axum's `customize-extractor-error` example shows 4 different error customization patterns — this complexity indicates the error handling design space is non-trivial. Agent should check for consistent error handling across all handlers.

**Recommendation**: Add Rust backend architecture patterns.

### Test 2: chi — Go backend (middleware chaining, dependency injection patterns)

**Input**: Scan chi for middleware and DI patterns.

**Findings**:
- **GAP FOUND**: chi uses function closures for dependency injection (handlers close over dependencies). Agent prompt evaluates DI for Python (FastAPI Depends, Django Ninja auth) but has no Go DI evaluation.
- **GAP FOUND**: chi's middleware chaining is implicit — `r.Use(A); r.Use(B)` means A wraps B. Agent prompt checks Django middleware ordering but has no generic middleware chain analysis.
- **EDGE CASE**: chi's `r.Group()` creates isolated middleware stacks — middleware added to a group doesn't apply to parent routes. This is a common source of "my middleware isn't running" bugs.

**Recommendation**: Add Go backend patterns (closure-based DI, group-scoped middleware).

### Test 3: drf — DRF (ViewSet vs APIView, nested serializers, permission composition)

**Input**: Scan DRF for architecture decision patterns.

**Findings**:
- **GAP FOUND**: Agent prompt's "service layer" check is generic. DRF-specific:
  - ViewSet vs APIView: ViewSets encourage monolithic views; APIViews encourage single-responsibility
  - Nested serializer depth: serializers referencing serializers > 3 levels deep = maintenance nightmare
  - Permission composition: `AND` vs `OR` permission logic (DRF uses AND by default via list; OR requires `|` operator or custom class)
- **EDGE CASE**: DRF's `serializers.py` imports show tight coupling between fields, relations, and validators — all in one module. This is framework-level coupling but influences application architecture.

**Recommendation**: Add DRF-specific architecture guidance.

### Test 4: pydantic — Schema design (optional vs default, computed fields, validators)

**Input**: Analyze pydantic schema design patterns.

**Findings**:
- **GAP FOUND**: Agent prompt has Schema Design checklist for DB models but no pydantic/API schema design checklist:
  - `Optional[str]` vs `str | None = None` vs `str = ""` — different semantics, often confused
  - `computed_field` for derived values vs manual property — agent should prefer computed_field
  - Request vs Response schemas: same model for both = over-exposure risk
- **EDGE CASE**: pydantic's `model_config` with `from_attributes = True` enables ORM mode — this changes validation behavior (attribute access vs dict access). Agent doesn't check for mode mismatches.

**Recommendation**: Add pydantic schema design checklist.

### Test 5: taxonomy — Next.js API (Route Handlers vs Server Actions)

**Input**: Scan taxonomy for API design patterns.

**Findings**:
- **GAP FOUND**: taxonomy uses both `pages/api/` (Pages Router API) and `app/api/` (App Router API) — this is a migration artifact. Agent prompt has no "mixed router" detection.
- **GAP FOUND**: Agent prompt's API Design checklist focuses on REST patterns but has no Next.js-specific guidance:
  - Route Handlers (`app/api/`) for external/webhook consumption
  - Server Actions for form mutations from Server Components
  - When to use which: agent should flag Server Actions used where Route Handlers are more appropriate (e.g., public API endpoints)
- **EDGE CASE**: taxonomy's `app/api/posts/route.ts` returns `new Response(JSON.stringify(posts))` without Content-Type header — defaults to `text/plain`. Should use `NextResponse.json()`.

**Recommendation**: Add Next.js API architecture patterns.

## Gaps Found in Agent Prompt

1. **No Rust backend patterns** (error type strategy, state management, extractor ordering)
2. **No Go backend patterns** (closure DI, group-scoped middleware, middleware chain analysis)
3. **No DRF architecture guidance** (ViewSet vs APIView, nested serializer depth, permission composition)
4. **No pydantic schema design checklist** (Optional semantics, request/response separation, computed fields)
5. **No Next.js API architecture patterns** (Route Handler vs Server Action, mixed router detection)
6. **Response Content-Type not checked** (raw Response vs framework-specific response helpers)
