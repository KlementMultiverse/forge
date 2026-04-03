# @code-archaeologist — Autoresearch V2 Edge Cases

## Research Sources
- "Cognitive Debt Is Not Technical Debt" (Dev.to 2025)
- "AI-Generated Code Creates New Wave of Technical Debt" (InfoQ Nov 2025)
- "Detection of Self-Admitted Aging Debt" (Empirical Software Engineering 2025)
- CodeScene behavioral analysis methodology

## Edge Case Tests

### Test 1: axum — Rust codebase evolution (macro usage, feature flag accumulation)

**Input**: Scan axum for tech debt indicators specific to Rust.

**Findings**:
- **GAP FOUND**: Agent prompt's dead code detection uses Python patterns (`grep for defined functions/classes, then check if they are imported`). No Rust equivalents:
  - Dead feature flags in `Cargo.toml` that no code behind `#[cfg(feature = "...")]` uses
  - Macro-generated code that obscures dependency graphs — `#[derive(...)]` and custom proc macros
  - Conditional compilation: `#[cfg(test)]` modules mixed with production code in same file
  - Version-gated code: `#[cfg(feature = "tower-log")]` patterns that accumulate
- **GAP FOUND**: Agent prompt's git history analysis mentions "churn" but not Rust-specific: crate dependency churn (frequent Cargo.toml changes), breaking changes across minor versions.

**Recommendation**: Add Rust codebase archaeology patterns.

### Test 2: chi — Go code (dead interface methods, unused middleware, import cycles)

**Input**: Scan chi for Go-specific tech debt.

**Findings**:
- **GAP FOUND**: Agent prompt has no Go-specific debt detection:
  - **Dead interface methods**: Interface defined with 10 methods but implementations only use 5
  - **Unused middleware**: Middleware defined in `middleware/` but never `Use()`'d in routes
  - **Import cycles**: Go compiler catches these, but near-cycles (A→B→C→A via interface) are debt
  - **Build tags**: `//go:build` tags accumulating for platform-specific code
- **PASS**: chi itself is clean — 20 files, clear structure, well-documented middleware.
- **EDGE CASE**: chi's `_examples/` directory is excluded from build but contains patterns that may drift from current API. Agent should flag example code that uses deprecated APIs.

**Recommendation**: Add Go codebase archaeology patterns.

### Test 3: drf — DRF (deprecated API patterns, compatibility shims, migration debt)

**Input**: Scan DRF for deprecated patterns and migration debt.

**Findings**:
- **GAP FOUND**: DRF's `compat.py` contains compatibility shims. Agent prompt detects deprecated patterns but doesn't specifically scan for:
  - `rest_framework.compat` imports in application code (sign of using deprecated APIs)
  - DRF version-specific behavior changes (e.g., serializer field behavior changed between 3.14 and 3.15)
  - Orphaned viewsets: ViewSets registered in routers but not included in any URL conf
- **EDGE CASE**: DRF's test infrastructure uses `APITestCase` which has different transaction behavior than Django's `TestCase` — agent should flag test base class inconsistency as potential debt.

**Recommendation**: Add DRF-specific debt detection.

### Test 4: pydantic — Version migration debt (v1→v2 compat layer, deprecated validators)

**Input**: Scan pydantic for v1→v2 migration indicators.

**Findings**:
- **CRITICAL GAP FOUND**: pydantic has an entire `deprecated/` directory with 5 files:
  - `deprecated/config.py` — `BaseConfig` (v1 pattern, should use `ConfigDict`)
  - `deprecated/json.py` — `pydantic_encoder`, `custom_pydantic_encoder` (should use `model_dump`)
  - `deprecated/tools.py` — `parse_obj_as`, `schema_of` (should use `TypeAdapter`)
  - `deprecated/decorator.py` — v1 decorator pattern
- **GAP FOUND**: Agent prompt's dead code detection doesn't scan for deprecated import paths. Any application code importing from `pydantic.deprecated.*` or using v1 patterns (`class Config:`, `.dict()`, `.json()`, `parse_obj_as`) is migration debt.
- **GAP FOUND**: pydantic's `_migration.py` contains a mapping of 150+ v1→v2 import redirects. Agent should use this as a lookup table for detecting stale v1 usage.

**Recommendation**: Add pydantic v1→v2 migration debt scanner using `_migration.py` mappings.

### Test 5: taxonomy — Next.js (pages/ vs app/ migration, deprecated patterns, dead routes)

**Input**: Scan taxonomy for migration-era debt.

**Findings**:
- **CRITICAL GAP FOUND**: taxonomy has BOTH `pages/` and `app/` directories — classic Next.js migration in progress. Specifically:
  - `pages/api/auth/[...nextauth].ts` — Pages Router auth
  - `app/api/auth/[...nextauth]/_route.ts` — App Router auth (prefixed with `_` to disable!)
  - Agent prompt has no "dual router" detection pattern
- **GAP FOUND**: taxonomy has `contentlayer.config.js` — Contentlayer is abandoned/unmaintained as of 2024. Agent should flag abandoned dependencies.
- **GAP FOUND**: Agent prompt's "orphaned files" check uses import graph analysis but doesn't account for Next.js's file-system routing (files in `app/` are routes even without imports).

**Recommendation**: Add Next.js migration debt detection (pages/ vs app/ coexistence, abandoned dependencies, file-system routing awareness).

## Gaps Found in Agent Prompt

1. **No Rust archaeology patterns** (feature flag accumulation, macro code, conditional compilation)
2. **No Go archaeology patterns** (dead interfaces, unused middleware, build tag accumulation)
3. **No pydantic v1→v2 migration scanner** (deprecated import detection using _migration.py)
4. **No Next.js migration detection** (pages/ + app/ coexistence, disabled route files with `_` prefix)
5. **No abandoned dependency detection** (unmaintained libraries like Contentlayer)
6. **File-system routing not accounted for** in dead code analysis (Next.js, Remix, SvelteKit)
