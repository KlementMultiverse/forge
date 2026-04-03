# Root Cause Analyst — Autoresearch Test Results

**Date:** 2026-04-02
**Agent prompt:** `/home/intruder/projects/forge/agents/universal/root-cause-analyst.md`
**Method:** Karpathy-style improvement loop — present real bug scenarios, trace code paths, evaluate prompt coverage

## Research: RCA Techniques for Software Bugs

Key techniques evaluated against the current prompt:

| Technique | Description | In Prompt? |
|---|---|---|
| **5 Whys** | Iterative "why" questioning to drill past symptoms | NO — prompt says "form hypotheses" but never mandates iterative deepening |
| **Fishbone (Ishikawa)** | Categorize causes: Code, Config, Data, Environment, Dependencies, Timing | NO — no structured categorization framework |
| **Fault Tree Analysis** | Top-down Boolean logic tree (AND/OR gates) for multi-cause failures | NO — no guidance on multi-factor root causes |
| **Change Analysis** | Compare working vs broken state — what changed? | PARTIAL — "check git log" but no systematic before/after comparison |
| **Barrier Analysis** | What safeguard failed to prevent the bug? | NO — no prevention-layer analysis |
| **Timeline Reconstruction** | When did it start? What happened before/after? | PARTIAL — mentions "timeline" in outputs but no method for building one |

---

## Test Run Results

### RUN 1: clinic-portal — "Tests expect 401 but get 302" (middleware ordering)

**Bug scenario:** An API test calls a protected endpoint without authentication and expects HTTP 401. Instead it gets HTTP 302 (redirect to /login/).

**Actual code trace:**
1. `config/settings.py` line 88-100: MIDDLEWARE list has `TenantMainMiddleware` at position 0 (correct per rules), then `SafeTenantAccessMiddleware` at position 7.
2. `apps/tenants/middleware.py` line 42-43: `SafeTenantAccessMiddleware.__call__()` — for unauthenticated users on tenant subdomains, returns `redirect("/login/")` which is HTTP 302.
3. The API test expects 401 Unauthorized but gets 302 because `SafeTenantAccessMiddleware` was designed for browser views (redirect), not API endpoints.
4. The `/api/` prefix is NOT in `EXEMPT_PATHS` (line 24: only `/login/`, `/api/auth/`, `/static/`, `/admin/`), so non-auth API calls hit the redirect.

**Root cause:** `SafeTenantAccessMiddleware` does not distinguish between browser requests and API requests. It redirects ALL unauthenticated requests instead of returning 401 for API paths.

**What the prompt would guide:**
- CHECK: "Read relevant source files" — yes, would read middleware
- CHECK: "Check config (settings.py, middleware order)" — yes, would find MIDDLEWARE
- MISS: No guidance to trace the HTTP response code through the middleware chain
- MISS: No guidance to check whether middleware behavior differs for API vs browser requests
- MISS: No structured approach to trace "expected 401, got 302" — the prompt says "form hypothesis" but gives no framework for status code mismatches

**Prompt gap:** No guidance on **tracing HTTP response flow through middleware chains** or distinguishing API vs view responses.

---

### RUN 2: saleor — "GraphQL query returns null for authenticated user" (permission system)

**Bug scenario:** A `{ me { email } }` GraphQL query returns `null` even when user is authenticated.

**Actual code trace:**
1. `saleor/graphql/account/schema.py` line 259-261: `resolve_me()` returns `info.context.user if user else None`
2. The `info.context.user` is populated by authentication middleware. If the auth token is invalid/expired, `user` is `None` (not AnonymousUser — it's actually falsy).
3. Saleor uses multiple auth backends: JWT, App tokens, and bearer tokens. The permission system at `saleor/permission/utils.py` has `all_permissions_required()`.
4. The `resolve_me` does NOT check `is_authenticated` — it just checks truthiness. An `AnonymousUser` instance is truthy but has no email.
5. But the actual issue: if token is passed in wrong header format (e.g., `Bearer ` prefix missing), auth middleware sets `user=None` silently.

**Root cause:** Silent auth failure — middleware sets `user=None` without raising an error when token format is invalid. The resolver returns `null` instead of an auth error because it has no way to distinguish "no token sent" from "invalid token sent."

**What the prompt would guide:**
- CHECK: "Read relevant source files" — would find resolve_me
- CHECK: "Check config" — would check settings
- MISS: No guidance on **tracing authentication flow end-to-end** (token → middleware → context → resolver)
- MISS: No guidance on distinguishing "silent failure" patterns where errors are swallowed
- MISS: No pattern for "null return vs error return" investigation

**Prompt gap:** No guidance on **tracing authentication/authorization chains** or detecting **silent failure patterns** where errors are absorbed instead of raised.

---

### RUN 3: fastapi-template — "Alembic migration fails with 'relation already exists'" (migration state)

**Bug scenario:** Running `alembic upgrade head` fails with "relation 'user' already exists."

**Actual code trace:**
1. `backend/app/alembic/env.py` line 22-25: imports `SQLModel` and uses `SQLModel.metadata` as target.
2. `backend/app/models.py`: defines `User(UserBase, table=True)` and `Item(ItemBase, table=True)` — SQLModel table models.
3. `backend/app/alembic/versions/`: 5 migration files exist, starting with `e2412789c190_initialize_models.py`.
4. The issue: if someone ran `SQLModel.metadata.create_all(engine)` manually (e.g., in tests or `init_db`), tables exist in DB but Alembic's `alembic_version` table still points to an older revision.
5. `backend/app/core/db.py` line 15: `init_db(session)` exists and could create tables outside Alembic.

**Root cause:** Split migration authority — both Alembic and `SQLModel.metadata.create_all()` can create tables. When `init_db` runs first, tables exist but Alembic has no record of creating them. Subsequent `alembic upgrade head` tries to CREATE the same tables.

**What the prompt would guide:**
- CHECK: "Run diagnostic commands" — would try the failing migration
- CHECK: "Check git log for recent changes" — might find when init_db was added
- MISS: No guidance on **checking database state vs migration state** (what tables exist vs what Alembic thinks exists)
- MISS: No pattern for "dual authority" bugs where two systems manage the same resource
- MISS: No guidance on checking `alembic_version` table or comparing DB schema to migration history

**Prompt gap:** No guidance on **database state vs migration state comparison** or **dual authority conflicts**.

---

### RUN 4: medusa — "TypeScript build fails in CI but passes locally" (env differences)

**Bug scenario:** `turbo run build` passes locally but fails in CI with TypeScript errors.

**Actual code trace:**
1. `_tsconfig.base.json`: `"incremental": false`, `"skipLibCheck": true`, `"strictNullChecks": true`
2. `turbo.json` line 4-6: build pipeline uses `"dependsOn": ["^build"]` — builds dependencies first
3. Monorepo structure: `packages/medusa` depends on `packages/core/framework` and others
4. Key issue: locally, incremental builds cache `.tsbuildinfo` files. In CI, fresh clone means no cache. Also, `node_modules` hoisting via yarn workspaces may resolve differently in CI vs local.
5. The `_tsconfig.base.json` sets `"module": "Node16"` and `"moduleResolution": "Node16"` — strict about `.js` extensions in imports. Local IDE may hide these errors.

**Root cause:** Two likely factors: (1) CI has clean `node_modules` with potentially different hoisted dependency versions, (2) TypeScript strict mode with `Node16` module resolution enforces `.js` extensions in imports which the IDE silently resolves locally but fails in clean builds.

**What the prompt would guide:**
- CHECK: "Check config" — would find tsconfig
- MISS: No guidance on **environment comparison** (local vs CI)
- MISS: No pattern for "works locally, fails in CI" — this is an extremely common bug class
- MISS: No guidance on checking dependency resolution differences (hoisting, lockfile, node version)
- MISS: No mention of checking **build cache effects** or **incremental compilation state**

**Prompt gap:** No framework for **environment-difference analysis** or **build reproducibility** investigation. No specific guidance for "works here, fails there" bugs.

---

### RUN 5: clinic-portal — "Cache returns wrong tenant's data" (cache key generation)

**Bug scenario:** Tenant A sees data cached by Tenant B.

**Actual code trace:**
1. `config/settings.py` line 124-131: Cache config uses `"KEY_FUNCTION": "django_tenants.cache.make_key"` and `"REVERSE_KEY_FUNCTION": "django_tenants.cache.reverse_key"`.
2. `django_tenants.cache.make_key` prepends the current tenant's schema name to cache keys, using `connection.schema_name`.
3. Bug path: if code caches data BEFORE `TenantMainMiddleware` sets the tenant (e.g., in a signal handler or middleware that runs before position 0), `connection.schema_name` returns `public`, and both tenants share the same key.
4. Alternative path: if using `cache.set()` in a management command or Celery task where `connection.schema_name` is not set per-tenant.
5. The `FlexibleTenantMiddleware` (line 54-82) does session-based fallback — if it falls back to session tenant, the connection might briefly be on `public` schema before switching.

**Root cause:** Cache key generation depends on `connection.schema_name` being set at call time. Any code path that runs outside the request-response cycle (management commands, signals, background tasks) or before `TenantMainMiddleware` processes the request will generate keys with `public` schema prefix, causing cross-tenant cache pollution.

**What the prompt would guide:**
- CHECK: "Check config (settings.py)" — would find cache config
- MISS: No guidance on **tracing cache key construction** or verifying key isolation
- MISS: No pattern for **multi-tenant data isolation bugs** — extremely critical bug class
- MISS: No guidance on checking **execution context** (are we in request cycle? background task? signal?)
- MISS: No guidance on checking **timing of middleware execution** relative to cache calls

**Prompt gap:** No framework for **data isolation verification** in multi-tenant systems. No guidance on **execution context analysis** (request vs background vs signal).

---

### RUN 6: saleor — "Celery task silently drops" (task routing, queue config)

**Bug scenario:** A Celery task is called but never executes. No error in logs.

**Actual code trace:**
1. `saleor/celeryconf.py` line 32-34: `app = Celery("saleor", ...)`, `app.config_from_object("django.conf:settings", namespace="CELERY")`, `app.autodiscover_tasks()`
2. `saleor/settings.py` line 622-633: `CELERY_BROKER_URL` from env, `CELERY_TASK_ALWAYS_EAGER = not CELERY_BROKER_URL`
3. Critical: If `CELERY_BROKER_URL` is empty/unset, `CELERY_TASK_ALWAYS_EAGER = True` — tasks run synchronously inline. BUT if broker URL is set but broker is down, tasks are sent and lost.
4. Multiple `autodiscover_tasks` calls with `related_name` parameters (lines 36-69) — tasks in migration packages like `saleor3_23`, `saleor3_22`, etc. If a task is in a package that isn't discovered, it silently fails.
5. No `CELERY_TASK_REJECT_ON_WORKER_LOST` or `CELERY_TASK_ACKS_LATE` visible — default behavior is to ACK before execution, so if worker dies, task is lost.

**Root cause:** Multiple possible causes: (1) Broker URL set but broker unreachable — task published but no consumer, (2) Task module not in any `autodiscover_tasks` call — task import fails silently, (3) Task routed to wrong queue with no consumer on that queue. The `autodiscover_tasks` with `related_name` means tasks must be in specific submodules, not just `tasks.py`.

**What the prompt would guide:**
- CHECK: "Check config" — would find celery settings
- MISS: No guidance on **tracing async task lifecycle** (publish → broker → queue → consumer → execute)
- MISS: No pattern for "silently drops" — no error means no stack trace to analyze
- MISS: No guidance on checking **broker connectivity** or **queue consumer status**
- MISS: No guidance on verifying **task discovery/registration** (is the task even registered?)

**Prompt gap:** No framework for **async task lifecycle tracing**. No guidance for "no error, no output" silent failure investigation. No pattern for verifying task registration/discovery.

---

### RUN 7: fastapi-template — "SQLAlchemy session not rolling back on error" (session lifecycle)

**Bug scenario:** After an error in an API endpoint, corrupted data remains in the database.

**Actual code trace:**
1. `backend/app/api/deps.py` line 21-23: `get_db()` yields a `Session(engine)` using a context manager (`with Session(engine) as session: yield session`).
2. SQLModel's `Session` (inherits from SQLAlchemy `Session`) with `with` statement calls `session.close()` on exit, NOT `session.rollback()`.
3. The `yield session` inside a `with` block means: if the endpoint raises an exception AFTER a `session.add()` + `session.flush()` but BEFORE `session.commit()`, the session is closed without explicit rollback.
4. SQLAlchemy behavior: `session.close()` does call `session.rollback()` if there's an active transaction. BUT if `autoflush` is True (default), partial writes may have been flushed.
5. The actual gap: there's no explicit `try/except` with rollback in `get_db()`. The FastAPI exception handler catches the error, but the session's `__exit__` cleanup depends on SQLAlchemy's internal state.

**Root cause:** The `get_db()` generator does not have explicit error handling. While SQLAlchemy's `Session.close()` does rollback uncommitted transactions, there's no guarantee about the state if `flush()` was called. The real bug is when code does `session.commit()` inside a try/except that catches and re-raises — the commit partially succeeds, the rollback never happens.

**What the prompt would guide:**
- CHECK: "Read relevant source files" — would find deps.py
- MISS: No guidance on **tracing resource lifecycle** (open → use → error → cleanup)
- MISS: No pattern for **implicit vs explicit cleanup** bugs
- MISS: No guidance on understanding **generator-based dependency injection** lifecycle in FastAPI
- MISS: No mention of checking **transaction boundaries** or **autoflush behavior**

**Prompt gap:** No framework for **resource lifecycle analysis** (DB sessions, connections, file handles). No guidance on **implicit cleanup vs explicit cleanup** patterns.

---

### RUN 8: medusa — "API returns 500 with no error details" (error handling chain)

**Bug scenario:** An API call returns `{"code": "unknown_error", "message": "An unknown error occurred.", "type": "unknown_error"}` with status 500.

**Actual code trace:**
1. `packages/core/framework/src/http/middlewares/error-handler.ts` line 16-103: The `errorHandler()` catches all errors.
2. Line 80-84: The `default` case in the switch statement — if `err.type` and `err.name` don't match ANY known `MedusaError.Types`, it returns `unknown_error` with the generic message, **HIDING the original error message**.
3. `packages/core/framework/src/http/middlewares/exception-formatter.ts`: `formatException()` only handles Postgres errors (duplicate, foreign key, serialization, null violation). All other errors pass through unchanged.
4. Line 87-91: errors with statusCode >= 500 are logged via `logger.error(err)`, but the CLIENT only sees the generic message.
5. The original error details (stack trace, message) are only in server logs, never exposed to the API consumer.

**Root cause:** The error handler's `default` case intentionally strips error details for security (don't leak internals). But this makes debugging impossible for API consumers. The original error IS logged server-side (line 88), but the response body has no correlation ID, no request ID, and no way to trace back to the server log entry.

**What the prompt would guide:**
- CHECK: "Read relevant source files" — would find error-handler.ts
- CHECK: "Full stack trace, not just message" — but the whole point is there IS no stack trace in the response
- MISS: No guidance on **tracing error transformation chains** (original error → formatter → handler → response)
- MISS: No pattern for investigating **error masking** — where the handler intentionally hides information
- MISS: No guidance on checking **server-side logs** when client-side error is generic
- MISS: No guidance on checking for **correlation IDs** or request tracing

**Prompt gap:** No framework for **error transformation chain analysis**. No guidance on checking both client-side response AND server-side logs. No pattern for **error masking/stripping** bugs.

---

### RUN 9: clinic-portal — "AuditLog.objects.all().delete() works despite immutability" (ORM vs model)

**Bug scenario:** `AuditLog` model has `delete()` that raises ValueError, but `AuditLog.objects.all().delete()` successfully deletes all records.

**Actual code trace:**
1. `apps/workflows/models.py` line 35-36: `AuditLog.delete()` raises `ValueError("AuditLog entries are immutable and cannot be deleted.")`.
2. This overrides the **instance** `delete()` method. When you call `audit_log_instance.delete()`, it raises.
3. BUT: `AuditLog.objects.all().delete()` calls `QuerySet.delete()`, which issues a SQL `DELETE FROM` directly — it NEVER calls the model's `delete()` method.
4. Django's `QuerySet.delete()` bypasses model-level `delete()` entirely — it's a bulk SQL operation.
5. Similarly, `AuditLog.objects.filter(...).delete()` would also bypass the model guard.

**Root cause:** Django's ORM has two separate deletion paths: instance `delete()` (calls model method) and QuerySet `delete()` (direct SQL). The model-level override only guards the instance path. The immutability guarantee is incomplete — a database-level constraint (trigger or removing DELETE permission) would be needed for true immutability.

**What the prompt would guide:**
- CHECK: "Read relevant source files" — would find the model
- MISS: No guidance on **distinguishing ORM abstraction layers** (model instance vs QuerySet vs raw SQL)
- MISS: No pattern for **incomplete guard** analysis — checking ALL paths that could perform an operation
- MISS: No guidance on verifying that a constraint is enforced at the RIGHT layer (model vs DB vs application)
- MISS: No "5 Whys" drill-down: Why does delete work? → QuerySet bypass. Why does QuerySet bypass? → It's SQL-level. Why is the guard only model-level? → Developer assumed all deletes go through model.

**Prompt gap:** No framework for **abstraction layer analysis** — verifying a guard works at ALL layers (model, ORM QuerySet, raw SQL, admin). No structured "all paths" analysis for operations that should be blocked.

---

### RUN 10: saleor — "Webhook fires but payload is empty" (serialization chain)

**Bug scenario:** Webhook delivery is triggered and received by the target, but the payload body is empty/minimal.

**Actual code trace:**
1. `saleor/webhook/payloads.py` line 140-157: `generate_metadata_updated_payload()` — uses `PayloadSerializer().serialize()` with `fields=[]` — empty fields list means only PK is serialized.
2. Line 274+: `generate_order_payload()` explicitly lists field tuples like `ORDER_FIELDS`.
3. `saleor/webhook/transport/asynchronous/transport.py` line 31-35: Uses `generate_payload_promise_from_subscription()` for subscription-type webhooks.
4. Two payload paths: (a) Legacy payloads use `generate_*_payload()` functions with explicit field lists, (b) Subscription payloads use GraphQL subscription queries.
5. For subscription webhooks: if the subscription query is malformed or references fields the user doesn't have permission to read, the payload resolves to null/empty for those fields.
6. `PayloadSerializer` uses `fields=[]` in `generate_metadata_updated_payload` — this is intentional (metadata events only send PK + meta), but if a developer copies this pattern for a new event type without specifying fields, the payload is empty.

**Root cause:** The serialization chain has multiple points of failure: (1) `PayloadSerializer.serialize(fields=[])` produces minimal output by design — copying the wrong template yields empty payloads, (2) For subscription webhooks, the GraphQL query determines the payload — if the query is wrong or permissions are insufficient, fields resolve to null silently, (3) The `@traced_payload_generator` decorator wraps the function but doesn't validate that the output is non-empty.

**What the prompt would guide:**
- CHECK: "Read relevant source files" — would find payloads.py
- MISS: No guidance on **tracing data serialization chains** (model → serializer → payload → transport)
- MISS: No pattern for "data is produced but content is missing" — partial output bugs
- MISS: No guidance on checking **field list configuration** or **serializer behavior with empty field lists**
- MISS: No guidance on distinguishing between "no data sent" and "data sent but empty" — wire-level vs application-level investigation

**Prompt gap:** No framework for **serialization chain analysis**. No guidance on verifying that output data matches expected shape. No pattern for "data exists but content is missing."

---

## Gap Summary

| Gap ID | Description | Runs Affected | Priority |
|---|---|---|---|
| G1 | No 5 Whys iterative deepening method | 1,3,5,9 | HIGH |
| G2 | No Fishbone categorization framework (Code/Config/Data/Env/Deps/Timing) | ALL | HIGH |
| G3 | No HTTP response flow tracing (middleware chain analysis) | 1,2 | HIGH |
| G4 | No authentication/authorization chain tracing | 2 | MEDIUM |
| G5 | No "silent failure" detection pattern | 2,6 | HIGH |
| G6 | No database state vs migration state comparison | 3 | MEDIUM |
| G7 | No environment-difference analysis ("works here fails there") | 4 | HIGH |
| G8 | No multi-tenant data isolation verification | 5 | HIGH |
| G9 | No execution context analysis (request vs background vs signal) | 5,6 | MEDIUM |
| G10 | No async task lifecycle tracing | 6 | MEDIUM |
| G11 | No resource lifecycle analysis (sessions, connections) | 7 | MEDIUM |
| G12 | No error transformation chain analysis | 8 | MEDIUM |
| G13 | No ORM abstraction layer analysis | 9 | MEDIUM |
| G14 | No serialization chain analysis | 10 | MEDIUM |
| G15 | No "all paths" analysis for guarded operations | 9 | HIGH |
| G16 | No dual authority / split responsibility detection | 3 | LOW |
| G17 | No correlation ID / request tracing guidance | 8 | LOW |

**Score: 3/10 runs would be fully guided by current prompt. 7/10 have significant gaps.**
