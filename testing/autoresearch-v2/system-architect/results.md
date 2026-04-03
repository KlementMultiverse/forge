# Autoresearch V2 — @system-architect Results

**Date**: 2026-04-02
**Repos tested**: axum (Rust), chi (Go), drf (Django REST Framework), pydantic (Python), taxonomy (Next.js)

## Edge Case 1: axum — Rust tower middleware architecture
**Repo**: axum

### Gap Found: No Rust/Tower middleware architecture patterns
The agent's middleware analysis is HTTP-framework-agnostic. Tower middleware has unique patterns:
- Layer/Service pattern: `Layer` creates `Service` instances (factory pattern)
- `ServiceBuilder` composes middleware (order = outer to inner, execution = inner to outer)
- `tower::timeout::Timeout`, `tower::limit::RateLimit` — built-in middleware as architecture building blocks
- Backpressure via `Service::poll_ready()` — unique to Tower, not present in Django/Express middleware
- Generic middleware: `tower-http` crate provides CORS, compression, tracing, auth layers
- Error handling through `Result<Response, Error>` propagation up the service stack

### Gap Found: No Rust async runtime architecture analysis
The agent should analyze tokio runtime configuration as an architectural decision:
- `#[tokio::main]` vs `tokio::runtime::Builder` (single-threaded vs multi-threaded)
- Work-stealing scheduler implications for request handling
- `tokio::spawn` for background tasks vs tower middleware for request-scoped work

## Edge Case 2: chi — Go middleware chain architecture
**Repo**: chi

### Gap Found: No Go router architecture patterns
Chi's architecture has specific patterns the agent should recognize:
- Radix tree routing (`tree.go`) — O(path_length) routing, not O(n_routes)
- Middleware chain as functional composition: `f(g(h(handler)))`
- Route groups with scoped middleware (`r.Group`, `r.Route`)
- Context-based request scoping (not thread-local like Python/Java)
- Chi's `URLParam` is context-scoped, not global state

### Gap Found: No Go concurrency architecture patterns
Go's concurrency model affects architecture:
- Every request is a goroutine (no thread pool to configure)
- `context.Context` for cancellation propagation (architectural requirement)
- No shared mutable state without explicit synchronization (`sync.Mutex`, channels)
- `sync.Pool` for object reuse (performance architecture)

## Edge Case 3: drf — ViewSet/Router/Serializer architecture layers
**Repo**: drf

### Gap Found: No DRF-specific layer analysis
The agent analyzes generic layers but DRF has its own layered architecture:
- **Router layer**: URL pattern generation from ViewSet registration
- **ViewSet layer**: CRUD operation dispatch (list/create/retrieve/update/destroy)
- **Serializer layer**: Validation, deserialization, nested object handling
- **Permission layer**: Per-view, per-object permission checking
- **Filter layer**: Queryset filtering (DjangoFilterBackend, SearchFilter, OrderingFilter)
- **Throttle layer**: Rate limiting (scoped by user, anonymous, custom)
- **Renderer layer**: Content negotiation (JSON, HTML, CSV)
- The agent should detect when business logic bleeds across these layers

### Gap Found: No "framework overhead" architecture assessment
DRF's layered architecture adds significant overhead per request (serializer validation, permission checks, content negotiation). The agent should assess whether this overhead is justified for the project's scale.

## Edge Case 4: pydantic — Plugin/extension architecture
**Repo**: pydantic

### Gap Found: No library extension architecture patterns
Pydantic's extension architecture is different from application architecture:
- `model_validator` / `field_validator` as extension points (plugin hooks)
- `GetCoreSchemaHandler` for custom type support (type-level extensibility)
- `ConfigDict` as configuration injection (not environment-based)
- `__get_pydantic_core_schema__` protocol for third-party type integration
- JSON schema generation customization (`json_schema_extra`, `__get_pydantic_json_schema__`)
- The agent has no pattern for analyzing library extensibility vs application extensibility

## Edge Case 5: taxonomy — Next.js app router architecture (RSC, layouts, streaming)
**Repo**: taxonomy

### Gap Found: No React Server Component architecture analysis
Next.js App Router introduces a new rendering architecture the agent doesn't analyze:
- Server Components (default) vs Client Components (`'use client'`)
- Component tree serialization boundary analysis (where does server/client split happen?)
- Layout persistence across navigations (layout.tsx never re-renders on navigation)
- Streaming architecture: `loading.tsx` creates Suspense boundaries automatically
- Data fetching architecture: `fetch()` in server components with caching, not `useEffect`
- No pattern for analyzing the "server/client boundary" — which components need interactivity?

### Gap Found: No content-site vs app-site architecture distinction
Taxonomy is a content site (docs, blog). The agent should distinguish content-site architecture (MDX, contentlayer, static generation) from application-site architecture (dynamic data, auth, state management).

## Summary of Gaps

| # | Gap | Severity | Fix Applied |
|---|-----|----------|-------------|
| 1 | No Rust/Tower middleware architecture patterns | HIGH | YES |
| 2 | No async runtime architecture analysis | MEDIUM | YES |
| 3 | No Go router architecture patterns (radix tree, context-scoped routing) | HIGH | YES |
| 4 | No Go concurrency architecture patterns | HIGH | YES |
| 5 | No DRF-specific layer analysis | HIGH | YES |
| 6 | No framework overhead architecture assessment | MEDIUM | YES |
| 7 | No library extension architecture patterns | HIGH | YES |
| 8 | No React Server Component architecture analysis | HIGH | YES |
| 9 | No content-site vs app-site architecture distinction | MEDIUM | YES |

## Claude Code Pattern: Coordinator/Worker Architecture
From Claude Code's `coordinatorMode.ts`, the coordinator pattern separates orchestration from execution: coordinator NEVER executes directly, only delegates to workers via `AgentTool`. Workers have explicit tool allowlists (`ASYNC_AGENT_ALLOWED_TOOLS`). Apply to system architecture: always separate orchestration layer from execution layer with explicit capability boundaries.
