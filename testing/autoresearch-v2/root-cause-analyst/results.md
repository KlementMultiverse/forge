# @root-cause-analyst — Autoresearch V2 Edge Cases

## Research Sources
- "9 Biggest Software Bugs of 2025" (TestDevLab)
- "After 50 Production Incidents" failure pattern guide (Medium)
- "AI code has 1.7x more issues" (CodeRabbit 2025 study)
- Cloudflare global outage 2025 (config change trigger)

## Edge Case Tests

### Test 1: axum — "Request handler panics in production but not in tests" (Rust panic handling)

**Input**: Simulate debugging scenario where axum handler panics under load but passes all tests.

**Findings**:
- **GAP FOUND**: Agent prompt's Fishbone categories (Code/Config/Data/Environment/Dependencies/Timing) don't cover Rust-specific categories:
  - **Memory**: Stack overflow from deep recursion, OOM from unbounded allocations
  - **Concurrency**: Tokio runtime starvation (blocking code in async context), deadlock from nested .await
  - **Panic propagation**: `unwrap()` on None/Err that only occurs under specific input combinations
- **EDGE CASE**: axum SSE's `panic!()` calls (Event::event called twice) would only trigger if handler code double-sets event fields — tests typically don't test this path because test helpers create events correctly.
- **GAP FOUND**: Agent's "All-Paths Analysis" is Django-specific (model.delete, QuerySet, Admin, etc). No Rust equivalent: handler path, middleware path, extractor path, tower service path.

**Recommendation**: Add Rust-specific investigation patterns and expand Fishbone categories.

### Test 2: chi — "API returns 404 for existing route" (Go route matching edge cases)

**Input**: Simulate debugging scenario where chi route returns 404 despite being registered.

**Findings**:
- **GAP FOUND**: Agent prompt has no Go/chi-specific route debugging patterns. Common root causes:
  - **Trailing slash**: chi treats `/users` and `/users/` as different routes (configurable)
  - **Route group scoping**: Route registered in a group with prefix, but request doesn't include prefix
  - **Method mismatch**: Route registered with `r.Get()` but request uses POST
  - **Middleware short-circuit**: Middleware returns response before handler runs (e.g., auth middleware returns 401, but appears as 404 if middleware ordering is wrong)
  - **URL encoding**: `%2F` in path vs literal `/`
- **EDGE CASE**: chi's tree-based router has priority rules — a wildcard route `/{id}` can shadow a literal route `/new` if registered first. This is a Timing/Config fishbone issue.

**Recommendation**: Add route matching debugging patterns for Go/chi.

### Test 3: drf — "Serializer silently drops fields" (DRF serializer inheritance gotcha)

**Input**: Simulate debugging scenario where DRF serializer omits expected fields.

**Findings**:
- **GAP FOUND**: Agent prompt's Fishbone analysis doesn't cover DRF serializer-specific root causes:
  - **Meta.fields override**: Child serializer's `Meta.fields` completely replaces parent's — no inheritance merge
  - **read_only_fields interaction**: Adding a field to `read_only_fields` doesn't add it to `fields` — it must be in both
  - **source collision**: Two fields with same `source` — later one silently overrides
  - **SerializerMethodField**: If the `get_<field>` method doesn't exist, field is silently None (no error)
- **CRITICAL EDGE CASE**: DRF's `LIST_SERIALIZER_KWARGS` (line 75-80 of serializers.py) defines which kwargs pass from parent to child in list context. If a custom kwarg is not in this list, it's silently dropped.
- **GAP FOUND**: Agent's 5-Whys example is specific to middleware redirect. No DRF-specific 5-Whys example for serializer issues.

**Recommendation**: Add DRF serializer debugging patterns to investigation methods.

### Test 4: pydantic — "Model validates in v1 but rejects in v2" (coercion changes)

**Input**: Simulate debugging scenario where pydantic v2 rejects previously valid data.

**Findings**:
- **GAP FOUND**: Agent prompt has no version migration debugging patterns. Common v1→v2 root causes:
  - **int→str coercion disabled by default** in v2. `"123"` no longer auto-coerces to `int` in strict mode.
  - **Required field semantics changed**: v1 `Optional[str]` meant "nullable + has default None". v2 `Optional[str]` still requires the field unless `= None` is explicit.
  - **Validator signature changed**: v1 `@validator` receives value + values dict. v2 `@field_validator` receives value only (access other fields via `info.data`).
  - **Config class → ConfigDict**: v1 `class Config: orm_mode = True` → v2 `model_config = ConfigDict(from_attributes=True)`
- **EDGE CASE**: v2 Union matching changed from "try first, then second" to discriminated union logic. `Union[int, str]` with input `"42"` may match differently.

**Recommendation**: Add pydantic v1→v2 debugging patterns with common error→root cause mappings.

### Test 5: taxonomy — "Server Component data leaks to client bundle" (Next.js boundaries)

**Input**: Simulate debugging scenario where sensitive data appears in client-side JavaScript bundle.

**Findings**:
- **GAP FOUND**: Agent prompt has no Next.js-specific investigation patterns. Server/client boundary bugs:
  - **Prop serialization**: Server Component passes object to Client Component — entire object serialized to client bundle, including fields that shouldn't be exposed
  - **Environment variable exposure**: `NEXT_PUBLIC_*` vars are bundled client-side. Non-prefixed vars should NOT be accessible, but can leak via Server Component props
  - **Import chain**: Client Component imports a utility that imports a server-only module — the server module code gets bundled client-side
  - **Closure capture**: Server Action closes over sensitive variable — variable is serialized in the action's encrypted payload
- **CRITICAL EDGE CASE**: taxonomy's `lib/auth.ts` contains `env.GITHUB_CLIENT_SECRET` and `env.POSTMARK_API_TOKEN`. If any Client Component imports from `@/lib/auth`, these secrets could leak to the client bundle.

**Recommendation**: Add Next.js server/client boundary debugging patterns.

## Gaps Found in Agent Prompt

1. **Fishbone categories too narrow** — missing Memory, Concurrency for Rust; missing Route Matching for Go
2. **All-Paths Analysis is Django-only** — no Rust/Go/Next.js equivalent paths
3. **No DRF serializer debugging patterns** (Meta.fields inheritance, source collisions, LIST_SERIALIZER_KWARGS)
4. **No version migration debugging** (pydantic v1→v2 common failures)
5. **No Next.js boundary debugging** (server/client data leaks, env var exposure, import chain analysis)
6. **No "config change as root cause" pattern** — 80% of prod bugs trace to recent changes (2025 data)
