# Autoresearch V2 — @context-loader-agent Results

**Date**: 2026-04-02
**Repos tested**: axum (Rust), chi (Go), drf (Django REST Framework), pydantic (Python), taxonomy (Next.js)

## Edge Case 1: Load axum + tower + tokio docs via context7
**Repo**: axum

### Gap Found: No Rust ecosystem library map
The Library Map only covers Python and Node.js libraries. Rust ecosystem needs:
| Task Keywords | Library | context7 Query Topic | Fallback Docs URL |
|---|---|---|---|
| axum, router, handler, extractor | axum | "axum Router handler extractor" | https://docs.rs/axum/latest/axum/ |
| tower, middleware, layer, service | tower | "tower Layer Service middleware" | https://docs.rs/tower/latest/tower/ |
| tokio, async, runtime, spawn | tokio | "tokio runtime spawn async" | https://docs.rs/tokio/latest/tokio/ |
| serde, serialize, deserialize | serde | "serde Serialize Deserialize" | https://serde.rs/ |
| sqlx, database, query, pool | sqlx | "sqlx query pool PostgreSQL" | https://docs.rs/sqlx/latest/sqlx/ |

### Gap Found: No multi-crate dependency resolution
Rust projects have Cargo.toml with multiple crate dependencies. The agent should read Cargo.toml to identify all relevant crates, not just the primary one.

## Edge Case 2: Load chi + Go stdlib net/http docs
**Repo**: chi

### Gap Found: No Go ecosystem library map
| Task Keywords | Library | context7 Query Topic | Fallback Docs URL |
|---|---|---|---|
| chi, router, middleware, mux | go-chi/chi | "chi Router middleware" | https://pkg.go.dev/github.com/go-chi/chi/v5 |
| net/http, handler, server, request | go stdlib | "net/http Handler Server" | https://pkg.go.dev/net/http |
| context, cancel, timeout, deadline | go stdlib | "context Context cancellation" | https://pkg.go.dev/context |
| gorilla, websocket | gorilla/websocket | "gorilla websocket upgrade" | https://pkg.go.dev/github.com/gorilla/websocket |

### Gap Found: No Go stdlib as library pattern
Go's standard library IS the primary "library" for many tasks. The agent should check if a Go stdlib package exists before looking for third-party libraries.

## Edge Case 3: Load DRF + Django docs
**Repo**: drf

### Gap Found: No DRF-specific library map entries
The Library Map has Django and django-ninja but not DRF:
| Task Keywords | Library | context7 Query Topic | Fallback Docs URL |
|---|---|---|---|
| DRF, serializer, viewset, ModelSerializer | djangorestframework | "DRF serializer viewset" | https://www.django-rest-framework.org/ |
| DRF, permission, IsAuthenticated | djangorestframework | "DRF permissions authentication" | https://www.django-rest-framework.org/api-guide/permissions/ |
| DRF, throttle, rate limit | djangorestframework | "DRF throttling rate limiting" | https://www.django-rest-framework.org/api-guide/throttling/ |
| DRF, filter, search, ordering | django-filter | "django-filter DRF integration" | https://django-filter.readthedocs.io/ |

## Edge Case 4: Load pydantic v2 docs (ensure v2 not v1)
**Repo**: pydantic

### Gap Found: No version-conflict detection
The agent checks versions but doesn't handle the case where context7 returns v1 docs when v2 is needed. Pydantic v1 and v2 have drastically different APIs. The agent should:
- Read `pyproject.toml` for exact pydantic version BEFORE querying
- Include version in query: "Pydantic v2 field_validator" not "Pydantic validator"
- If context7 returns v1 content (detectable by `@validator` decorator, `Config` inner class), flag: "WARNING: context7 returned v1 docs but project uses v2"
- Cross-check returned docs for v1 patterns and reject if found

### Gap Found: No pydantic sub-module awareness
Pydantic v2 has specialized modules that need separate queries:
- `pydantic-settings` (separate package in v2, was built-in in v1)
- `pydantic.functional_validators` (v2 only)
- `pydantic.functional_serializers` (v2 only)

## Edge Case 5: Load Next.js 14+ App Router docs
**Repo**: taxonomy

### Gap Found: No Next.js version-specific doc loading
Next.js 13/14/15 have significant differences in App Router behavior. The agent should:
- Read `package.json` for exact Next.js version
- Query for version-specific features: "Next.js 14 App Router server actions" not generic "Next.js router"
- Separate queries for: App Router, Server Components, Server Actions, Middleware, Image Optimization
- Flag if taxonomy uses Pages Router patterns that conflict with App Router

### Gap Found: No content-library doc loading
Taxonomy uses `contentlayer` for content management. The agent should detect content libraries from config files (`contentlayer.config.js`, `next-mdx-remote`, `next-contentlayer`) and load their docs too.

## Summary of Gaps

| # | Gap | Severity | Fix Applied |
|---|-----|----------|-------------|
| 1 | No Rust ecosystem library map | HIGH | YES |
| 2 | No multi-crate dependency resolution from Cargo.toml | MEDIUM | YES |
| 3 | No Go ecosystem library map | HIGH | YES |
| 4 | No Go stdlib as library pattern | MEDIUM | YES |
| 5 | No DRF-specific library map entries | HIGH | YES |
| 6 | No version-conflict detection (v1 docs returned for v2 project) | CRITICAL | YES |
| 7 | No pydantic sub-module awareness | MEDIUM | YES |
| 8 | No Next.js version-specific doc loading | HIGH | YES |
| 9 | No content-library detection from config files | MEDIUM | YES |

## Claude Code Pattern: Fallback Chain with Reporting
From Claude Code's tool failure handling pattern, every failed operation cascades through alternatives and ALWAYS reports what was tried. Apply to doc loading: context7 fail -> alternate name retry -> WebFetch official docs -> source code reading -> training knowledge. Each step reports what it tried.
