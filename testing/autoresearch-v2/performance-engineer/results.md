# @performance-engineer — Autoresearch V2 Edge Cases

## Research Sources
- "Async Isn't Always Faster" (FastAPI gotchas)
- "Async Rust is about concurrency, not performance" (Kobzol, Jan 2025)
- SQLAlchemy async performance discussions
- DataLoader performance overhead analysis

## Edge Case Tests

### Test 1: axum — Rust async performance (tokio runtime config, connection pool sizing)

**Input**: Scan axum for runtime configuration and connection pool patterns.

**Findings**:
- **GAP FOUND**: Agent prompt has no Rust/tokio-specific detection patterns. Missing: `#[tokio::main]` runtime configuration (multi_thread vs current_thread), `tokio::spawn` without backpressure controls, `.await` inside blocking code.
- **EDGE CASE**: axum examples (`tokio-postgres/`, `sqlx-postgres/`) use connection pools but don't document pool sizing relative to tokio worker threads. Over-provisioning pool = connection exhaustion; under-provisioning = unnecessary await contention.
- **GAP FOUND**: Agent scans for `boto3.client(` re-creation but has no equivalent for Rust (`Pool::new()` inside handlers, `Client::new()` per request).

**Recommendation**: Add Rust async performance patterns.

### Test 2: chi — Go performance (goroutine pool, context propagation overhead)

**Input**: Scan chi for goroutine management and context overhead patterns.

**Findings**:
- **GAP FOUND**: chi's `ThrottleWithOpts` uses channel-based concurrency limiting (buffered channel as semaphore). This is good pattern, but agent prompt has no Go-specific detection for unbounded `go func()` calls (goroutine leak = memory leak).
- **GAP FOUND**: chi middleware stacks add per-request overhead. `chi.Use()` wraps handlers recursively. Agent prompt checks middleware ordering for Django but has no generic middleware chain depth analysis.
- **EDGE CASE**: `context.WithTimeout` in chi's timeout middleware creates a new context per request — if timeout is large and requests are slow, this can accumulate goroutines waiting on context cancellation.

**Recommendation**: Add Go performance patterns (goroutine counting, channel sizing, middleware depth).

### Test 3: drf — DRF (serializer N+1, queryset evaluation timing, pagination overhead)

**Input**: Scan DRF core for N+1 query patterns and serializer performance.

**Findings**:
- **PASS**: DRF's `authentication.py:201` uses `select_related('user')` on token lookup — good pattern.
- **GAP FOUND**: `serializers.py` field validation runs `validate_<fieldname>` per field sequentially — no batch validation. For serializers with many validated fields + DB lookups per validator, this creates N+1 at the validation layer (not just the view layer).
- **GAP FOUND**: DRF's `mixins.py:71` notes "If 'prefetch_related' has been applied to a queryset, we need to forcibly evaluate it" — this means paginated querysets with prefetch are fully evaluated before slicing. Agent prompt detects N+1 in views but not in serializer-level validation queries.
- **EDGE CASE**: `ListSerializer` runs all validators in a loop per item — no batch optimization. 100-item bulk create = 100x validator calls.

**Recommendation**: Add serializer-level N+1 detection pattern.

### Test 4: pydantic — Model validation overhead (v1 vs v2, discriminated unions)

**Input**: Analyze pydantic v2 performance patterns.

**Findings**:
- **GAP FOUND**: Agent prompt has no pydantic-specific performance patterns. Missing: model re-creation overhead (`model_validate` vs `model_construct`), TypeAdapter caching, discriminated union with `Literal` vs without (10x difference).
- **EDGE CASE**: `model_validator(mode='before')` runs Python code before Rust-optimized field validation — a slow before-validator negates v2's performance gains.
- **GAP FOUND**: `arbitrary_types_allowed` disables pydantic-core's Rust validation path, falling back to Python isinstance — significant performance regression for hot paths.

**Recommendation**: Add pydantic performance patterns.

### Test 5: taxonomy — Next.js (bundle splitting, server component hydration, image optimization)

**Input**: Scan taxonomy for bundle size, hydration, and image patterns.

**Findings**:
- **GAP FOUND**: 30+ components marked `"use client"` — each creates a client bundle boundary. Agent prompt checks for bundle size but doesn't count client component boundaries.
- **GAP FOUND**: No `loading.tsx` files found in taxonomy — all async server components will show no loading state, causing perceived performance issues.
- **GAP FOUND**: Agent prompt has Web Vitals checklist but no Next.js-specific pattern for: RSC payload size, dynamic imports for heavy client components, Image component optimization (`next/image` vs raw `<img>`).
- **EDGE CASE**: taxonomy's `lib/auth.ts` JWT callback queries the database on EVERY token refresh (`db.user.findFirst`) — this runs on every authenticated request. No caching.

**Recommendation**: Add Next.js-specific performance patterns (RSC payload, client boundary count, auth callback DB queries).

## Gaps Found in Agent Prompt

1. **No Rust/tokio performance patterns** (runtime config, pool sizing, async bottlenecks)
2. **No Go performance patterns** (goroutine counting, channel sizing, context overhead)
3. **No pydantic performance patterns** (model_construct vs model_validate, TypeAdapter cache, discriminated unions)
4. **No Next.js performance patterns** (RSC payload, client boundary count, loading states)
5. **Serializer-level N+1 not detected** (DRF validator DB queries, ListSerializer loops)
6. **Auth callback DB queries not flagged** (per-request DB lookups in auth callbacks)
