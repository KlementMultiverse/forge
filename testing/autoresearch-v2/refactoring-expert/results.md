# @refactoring-expert — Autoresearch V2 Edge Cases

## Research Sources
- refactoring.guru code smell catalog
- "Code Smells and Anti-Patterns" (Codacy 2025)
- AI-generated code tech debt patterns (InfoQ, Nov 2025)

## Edge Case Tests

### Test 1: axum — Rust (trait bloat, tower layer complexity, error type proliferation)

**Input**: Scan axum for Rust-specific code smells.

**Findings**:
- **GAP FOUND**: Agent prompt's smell detection catalog is Python/JS focused. Missing Rust smells:
  - **Trait bloat**: Traits with 10+ methods (violates ISP)
  - **Error type proliferation**: Every module defining its own error enum without a unified error strategy
  - **Tower layer complexity**: Middleware chains where the type signature becomes unreadable (`ServiceBuilder<Stack<A, Stack<B, Stack<C, ...>>>>`)
  - **Clone overhead**: Excessive `.clone()` calls (20+ found in axum/src) — indicates ownership design issues
  - **Generic parameter explosion**: Functions with 5+ type parameters
- **EDGE CASE**: axum's error_handling module uses `HandleError` with nested generics and clone — this is framework code (acceptable), but agent should distinguish framework internals from application code.

**Recommendation**: Add Rust-specific smell catalog.

### Test 2: chi — Go (interface pollution, context value abuse, goroutine leak patterns)

**Input**: Scan chi for Go-specific anti-patterns.

**Findings**:
- **GAP FOUND**: Agent prompt has no Go-specific smell patterns. Missing:
  - **Interface pollution**: Defining interfaces where a concrete type would suffice
  - **Context value abuse**: Using `context.WithValue()` for dependency injection instead of function parameters
  - **Error string matching**: `if err.Error() == "something"` instead of sentinel errors or `errors.Is()`
  - **Init function abuse**: `func init()` with side effects
  - **Naked returns**: Named return values with naked returns in complex functions
- **PASS**: chi itself is well-structured — small files, focused interfaces, clean middleware pattern. Good reference for what clean Go looks like.

**Recommendation**: Add Go-specific smell patterns.

### Test 3: drf — DRF (fat serializers, viewset bloat, mixin hell)

**Input**: Scan DRF for serializer and viewset anti-patterns.

**Findings**:
- **GAP FOUND**: DRF's `serializers.py` is 1000+ lines — agent threshold is 300 lines. But this is framework code. Agent needs to distinguish "framework file is large" (acceptable) vs "application file is large" (smell).
- **EDGE CASE**: DRF mixin pattern (`ListModelMixin`, `CreateModelMixin`, etc.) combined with `GenericViewSet` creates "mixin hell" — a view inheriting 5+ mixins where method resolution order (MRO) becomes unpredictable.
- **GAP FOUND**: Agent prompt detects "Business Logic in Views" but doesn't specifically detect DRF's "fat serializer" pattern: `validate()` methods containing business logic, DB queries, and external API calls.

**Recommendation**: Add DRF-specific smell: "fat serializer validate()" and "mixin depth > 3".

### Test 4: pydantic — Model inheritance depth, validator chain complexity, config class bloat

**Input**: Scan pydantic for model design anti-patterns.

**Findings**:
- **GAP FOUND**: Agent prompt has no pydantic-specific smells. Missing:
  - **Deep model inheritance**: BaseModel → SharedBase → TenantBase → SpecificModel (4+ levels)
  - **Validator chain explosion**: `@field_validator` + `@model_validator(before)` + `@model_validator(after)` on same model
  - **Config class bloat**: `model_config = ConfigDict(...)` with 10+ options
  - **v1 compat layer**: Using `class Config` instead of `model_config = ConfigDict()`
- **GAP FOUND**: pydantic's `deprecated/` directory contains 5 files of v1 compat code. Agent should detect v1 compat usage as tech debt indicator.

**Recommendation**: Add pydantic model design smells.

### Test 5: taxonomy — Next.js (component prop drilling, context overuse, useEffect chains)

**Input**: Scan taxonomy for React/Next.js component anti-patterns.

**Findings**:
- **GAP FOUND**: 30+ `"use client"` components — agent should flag disproportionate client-to-server component ratio as potential smell (everything being client-side defeats RSC benefits).
- **GAP FOUND**: Agent prompt detects "God Class" but has no React equivalent: "God Component" — a component that manages state, fetches data, renders UI, AND handles side effects.
- **EDGE CASE**: taxonomy uses `components/ui/` directory with many Radix-based wrapper components that just re-export with styling. This is intentional (shadcn pattern) but agent might flag as "thin wrapper" smell incorrectly.
- **GAP FOUND**: Agent needs awareness of acceptable patterns per framework — not all wrappers are smells.

**Recommendation**: Add React/Next.js component smell patterns with framework-aware exceptions.

## Gaps Found in Agent Prompt

1. **No Rust smell patterns** (trait bloat, clone overhead, generic explosion, error type proliferation)
2. **No Go smell patterns** (interface pollution, context value abuse, init abuse, naked returns)
3. **No pydantic smell patterns** (deep inheritance, validator chains, v1 compat layer)
4. **No React/Next.js smell patterns** (God Component, client component ratio, prop drilling depth)
5. **Framework code vs application code** distinction missing (large files acceptable in frameworks)
6. **Framework-aware exceptions** needed (shadcn thin wrappers, DRF mixin patterns)
