# @security-engineer — Autoresearch V3 Results

## Run 1: Flask
**Target**: Blueprint security, session config, Werkzeug debug mode, secret key in config
**Files Read**: `src/flask/sessions.py`, `src/flask/config.py`, `src/flask/app.py`, `src/flask/helpers.py`, `CHANGES.rst`
**Gap Found**: No Flask-specific security checklist existed
**Patterns Identified**:
- `SECRET_KEY_FALLBACKS` (3.1+) for key rotation
- `TRUSTED_HOSTS` config (3.1+) for host header validation
- `SESSION_COOKIE_PARTITIONED` for CHIPS (3.1+)
- `MAX_CONTENT_LENGTH` per-request override (3.1+)
- Werkzeug debug mode gives interactive Python shell
- Blueprint endpoint name collisions (silent override)
- `redirect()` default changed to 303 in 3.2
**Fix**: Added Flask-Specific checklist (11 items) + Flask grep patterns

## Run 2: Hono
**Target**: Edge runtime security, middleware auth, CORS on edge, JWT validation
**Files Read**: `src/middleware/cors/index.ts`, `src/middleware/csrf/index.ts`, `src/middleware/jwt/index.ts`, `src/helper/cookie/index.ts`
**Gap Found**: No edge/Hono-specific security checklist
**Patterns Identified**:
- CSRF via `Sec-Fetch-Site` header (unique to Hono)
- Cookie prefix security (`__Secure-`, `__Host-`)
- CORS with function-based origin validation
- JWT middleware with re-exported verify/decode/sign
- `secure-headers` middleware for HSTS/CSP
- Edge runtime: no filesystem, secrets in env bindings
**Fix**: Added Hono/Edge-Specific checklist (8 items) + Hono grep patterns

## Run 3: SvelteKit
**Target**: Server-side form actions CSRF, hooks.server.ts auth, endpoint security
**Files Read**: `packages/kit/src/core/config/options.js`, `packages/kit/src/runtime/server/index.js`, `packages/kit/src/exports/public.d.ts`
**Gap Found**: No SvelteKit-specific security checklist
**Patterns Identified**:
- `csrf.checkOrigin` deprecated, `csrf.trustedOrigins` is replacement
- `hooks.server.ts` `handle()` for auth middleware
- Form actions have built-in CSRF via Origin check
- `+page.server.ts` vs `+page.ts` security boundary
- CSP via `kit.csp` config
- Form file validation (v2.52 security fix)
**Fix**: Added SvelteKit-Specific checklist (9 items) + SvelteKit grep patterns

## Run 4: Fiber
**Target**: Go fiber security: rate limiting, CORS, helmet middleware, TLS config
**Files Read**: `app.go`, `ctx.go`, `go.mod`, `addon/retry/`, `client/client.go`
**Gap Found**: Go section existed but no Fiber-specific patterns
**Patterns Identified**:
- Fiber uses fasthttp (NOT net/http) — different security middleware ecosystem
- Middleware addons in separate `gofiber/contrib` repos
- `Ctx.Locals()` request-scoped (pool resets)
- TLS via fasthttp config
- Body limits via `app.Config.BodyLimit`
- Error handler centralization
**Fix**: Added Fiber-Specific checklist (8 items) + Fiber grep patterns

## Run 5: Actix-Web
**Target**: Rust actix guards, authentication extractors, HTTPS config
**Files Read**: `actix-web/src/guard/mod.rs`, `actix-web/src/extract.rs`, `actix-web/src/scope.rs`, `actix-web/CHANGES.md`
**Gap Found**: Rust section existed via Axum but no actix-specific patterns
**Patterns Identified**:
- Guard system for route-level authorization
- `Route::to()` after `Route::wrap()` PANICS in v4.13
- `FromRequest` trait for custom auth extractors
- Scope-level middleware isolation
- `middleware::from_fn()` (v4.9+)
- Rustls version proliferation
- `experimental-introspection` feature
**Fix**: Added Actix-Web-Specific checklist (9 items) + Actix-Web grep patterns

## Run 6: FastAPI
**Target**: OAuth2 scopes, dependency injection auth, CORS origins
**Files Read**: `fastapi/security/`, `fastapi/dependencies/utils.py`, `fastapi/sse.py`, `fastapi/background.py`
**Gap Found**: Existing FastAPI section was minimal, missing new features
**Patterns Identified**:
- `SecurityScopes` for OAuth2 scope validation
- `DependencyScopeError` for scope violations
- Dependency caching `use_cache=True` (default)
- `EventSourceResponse` (SSE) - new feature
- `BackgroundTasks` timing (post-response)
- `ServerSentEvent.id` null character validation
**Fix**: Updated FastAPI-Specific checklist (8 items)
