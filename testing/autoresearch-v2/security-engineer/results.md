# @security-engineer — Autoresearch V2 Edge Cases

## Research Sources
- OWASP Top 10 2025 (new categories: A10 Mishandling of Exceptional Conditions)
- CVE-2025-29927: Next.js middleware authorization bypass (CVSS 9.1)
- DRF ObtainAuthToken: no throttle_classes by default
- Axum: `#![forbid(unsafe_code)]` — safe Rust, but panics in SSE module

## Edge Case Tests

### Test 1: axum — Rust-specific security (unsafe blocks, memory safety, tower middleware auth)

**Input**: Scan axum for `unsafe`, panic paths, and tower middleware auth bypass vectors.

**Findings**:
- **PASS**: axum uses `#![forbid(unsafe_code)]` — no unsafe blocks in core crate
- **GAP FOUND**: SSE module (`axum/src/response/sse.rs`) contains 4 `panic!()` calls (lines 316, 336, 383, 451) for duplicate method calls on Event builder. These are programmer-error panics (not user-input triggered), but if a handler builds SSE events from user input without validation, it could panic the handler.
- **GAP FOUND**: Agent prompt scans for `eval(`, `exec(`, Python/JS patterns but has NO Rust-specific scan patterns. Missing: `unsafe`, `unwrap()`, `expect()`, `panic!`, `transmute`, `from_raw_parts`
- **EDGE CASE**: Tower middleware backpressure — axum docs warn that `poll_ready` errors are returned from `call`, not `poll_ready`. Services that care about backpressure can misbehave silently.

**Recommendation**: Add Rust security scan patterns to agent.

### Test 2: chi — Go security (goroutine leaks, context cancellation, net/http defaults)

**Input**: Scan chi for goroutine leak vectors, missing context cancellation, and default security settings.

**Findings**:
- **GAP FOUND**: chi's Timeout middleware (`middleware/timeout.go`) has a critical edge case documented inline: "It's required that you select the ctx.Done() channel to check for the signal." If a handler ignores context cancellation, the timeout is silently ignored and the goroutine keeps running. This is a goroutine leak vector.
- **GAP FOUND**: chi's Recoverer middleware (`middleware/recoverer.go`) does NOT recover `http.ErrAbortHandler` — this is intentional but could surprise auditors.
- **GAP FOUND**: Agent prompt has no Go-specific scan patterns. Missing: `go func(`, unchecked `err`, `defer` ordering, context propagation checks.

**Recommendation**: Add Go security patterns to agent.

### Test 3: drf — DRF-specific (throttling bypass, serializer validation holes, permission classes)

**Input**: Scan DRF for default security configurations and validation gaps.

**Findings**:
- **CRITICAL GAP FOUND**: `ObtainAuthToken` view (rest_framework/authtoken/views.py:9-10) ships with `throttle_classes = ()` and `permission_classes = ()` — zero throttling on the login endpoint by default. This is a documented OWASP issue: brute force on auth endpoints.
- **GAP FOUND**: Serializer `validate_<fieldname>` methods (serializers.py:510-515) are only called if the field passed initial validation. If a field has `required=False` and is not submitted, field-level validators are silently skipped. This is expected behavior but easy to miss.
- **GAP FOUND**: Agent prompt mentions DRF throttling bypass as a risk category but doesn't specifically grep for `throttle_classes = ()` on auth views.

**Recommendation**: Add specific DRF auth endpoint scan pattern.

### Test 4: pydantic — Validation bypass (coercion edge cases, arbitrary_types, model_validator)

**Input**: Test pydantic v2 coercion changes and arbitrary_types validation.

**Findings**:
- **GAP FOUND**: When `arbitrary_types_allowed = True`, validation is reduced to `isinstance()` check only — no deep validation. Agent prompt doesn't flag this pattern.
- **GAP FOUND**: `model_validator(mode='before')` receives raw input dict — validators can mutate input before field validation. If a before-validator raises, mutated values may leak to union variant validators.
- **GAP FOUND**: Pydantic v2 changed int→str coercion (disabled by default). Agent prompt has no awareness of version-specific coercion differences.

**Recommendation**: Add Pydantic-specific validation audit patterns.

### Test 5: taxonomy — Next.js (server actions CSRF, middleware auth bypass, API route exposure)

**Input**: Scan taxonomy for CVE-2025-29927 patterns and auth boundary issues.

**Findings**:
- **CRITICAL GAP FOUND**: taxonomy's `middleware.ts` uses `withAuth` from next-auth with `authorized() { return true }` — always returns true, relying entirely on the middleware function for auth logic. If middleware is bypassed (CVE-2025-29927: `x-middleware-subrequest` header), ALL protected routes become accessible.
- **GAP FOUND**: API routes (e.g., `app/api/posts/route.ts`) correctly check `getServerSession()` independently — this is defense-in-depth. But the GET endpoint returns 403 with text "Unauthorized" (wrong status code — should be 401).
- **GAP FOUND**: No `global-error.tsx` exists — root layout errors will crash without a fallback UI.
- **GAP FOUND**: Agent prompt has no Next.js-specific security patterns. Missing: `x-middleware-subrequest` header check, Server Action CSRF validation, API route auth independence from middleware.

**Recommendation**: Add Next.js security checklist to agent, including CVE-2025-29927 mitigation check.

## Gaps Found in Agent Prompt

1. **No Rust security patterns** (unsafe, unwrap, panic, transmute)
2. **No Go security patterns** (goroutine leaks, context cancellation, defer ordering)
3. **No Next.js-specific security patterns** (middleware bypass CVE, server action CSRF)
4. **No Pydantic validation audit patterns** (arbitrary_types, coercion mode, before validators)
5. **DRF auth endpoint throttle check not specific enough** (should grep `throttle_classes = ()`)
6. **OWASP 2025 A10 not referenced** (Mishandling of Exceptional Conditions)
