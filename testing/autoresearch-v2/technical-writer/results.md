# Autoresearch V2 — @technical-writer Results

**Date**: 2026-04-02
**Repos tested**: axum (Rust), chi (Go), drf (Django REST Framework), pydantic (Python), taxonomy (Next.js)

## Edge Case 1: Write API docs for a Rust axum project
**Repo**: axum

### Gap Found: No Rust-specific API documentation template
Axum APIs differ from Python/JS APIs:
- Extractors define the request schema (not OpenAPI annotations)
- Error types with `IntoResponse` define error responses
- State management via `Extension` or `State<Arc<T>>` needs documentation
- Tower middleware layers need their own documentation section
- No `utoipa` / `aide` integration guidance for auto-generating OpenAPI from Rust code

### Gap Found: No "type-safe API" documentation approach
Rust's type system makes many runtime errors impossible. The docs should explain which errors the compiler prevents (e.g., missing extractors) vs which are runtime (e.g., deserialization failures).

## Edge Case 2: Write middleware documentation for Go chi
**Repo**: chi

### Gap Found: No Go middleware documentation template
Chi middleware has specific documentation needs:
- Middleware ordering matters and must be documented with "why this order"
- `func(http.Handler) http.Handler` signature needs explanation for non-Go developers
- Context value propagation needs a data flow diagram
- No template for documenting middleware that wraps `http.ResponseWriter`

## Edge Case 3: Write DRF migration guide (DRF to Django Ninja)
**Repo**: drf

### Gap Found: No migration guide template
The Document-Type Templates section has no Migration Guide template. Migration guides need:
1. **Motivation** — why migrate, what improves
2. **Compatibility Matrix** — which DRF features have Django Ninja equivalents
3. **Step-by-Step Migration** — one pattern at a time, with before/after examples
4. **Breaking Changes** — what behavior changes during migration
5. **Coexistence Strategy** — how to run both frameworks during migration
6. **Rollback Plan** — how to revert if migration fails
7. **Verification** — how to confirm migration didn't break anything

### Gap Found: No framework-comparison documentation pattern
When documenting a migration, every feature needs a side-by-side comparison (DRF serializer vs Ninja Schema, DRF viewset vs Ninja router).

## Edge Case 4: Write pydantic v1 to v2 migration guide from the codebase
**Repo**: pydantic

### Gap Found: No codebase-driven migration guide approach
The agent writes docs from specs, not from codebases. For a v1-to-v2 migration guide derived from actual code:
- Scan for deprecated v1 patterns (`@validator`, `Config` inner class, `schema_extra`)
- Map each to its v2 equivalent (`@field_validator`, `model_config`, `json_schema_extra`)
- Extract examples from the ACTUAL codebase (not generic examples)
- Flag behavioral changes (e.g., `Optional[str]` no longer defaults to `None` in v2)

## Edge Case 5: Write Next.js deployment guide for taxonomy
**Repo**: taxonomy

### Gap Found: No Next.js-specific deployment documentation
The Deployment Guide Template is framework-agnostic but Next.js needs:
- Build output modes: standalone vs static vs edge
- `next.config.mjs` `output: 'standalone'` documentation
- Environment variable handling (`env.mjs` validation, `NEXT_PUBLIC_` prefix convention)
- Edge runtime vs Node.js runtime selection per route
- ISR/SSG cache invalidation in production
- Prisma database migration as part of deployment
- `middleware.ts` behavior differences between dev and production

## Summary of Gaps

| # | Gap | Severity | Fix Applied |
|---|-----|----------|-------------|
| 1 | No Rust API documentation template (extractors, tower middleware, type safety) | HIGH | YES |
| 2 | No Go middleware documentation template | MEDIUM | YES |
| 3 | No Migration Guide document-type template | HIGH | YES |
| 4 | No framework-comparison documentation pattern | MEDIUM | YES |
| 5 | No codebase-driven migration guide approach | HIGH | YES |
| 6 | No Next.js deployment documentation patterns | HIGH | YES |
| 7 | No edge/server runtime documentation for Next.js routes | MEDIUM | YES |

## Claude Code Pattern: Desanitization / Normalization
From Claude Code's `FileEditTool/utils.ts`, the `normalizeQuotes()` and `desanitizeMatchString()` patterns show graceful handling of mismatched representations. Apply to documentation: when documenting APIs across frameworks, normalize terminology (e.g., "serializer" = "schema" = "model") with an explicit glossary.
