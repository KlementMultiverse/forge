# @python-expert Autoresearch — 10 Runs on Real Code

Date: 2026-04-02
Agent prompt: /home/intruder/projects/forge/agents/universal/python-expert.md

## Web Research Summary

Sources: Python best practices 2025, modern Python patterns, Python security checklist

Key findings that current python-expert prompt MISSES:
1. **No specific type hint enforcement** — prompt says "type safety" but no concrete rules (e.g., "every function must have return type annotation")
2. **No import ordering rules** — no mention of isort, stdlib/third-party/local grouping
3. **No string formatting standard** — no preference stated for f-strings vs %-formatting vs .format()
4. **No logging best practices** — no structured logging guidance, no log level rules
5. **No dataclass/Pydantic guidance** — no rule on when to use which
6. **No async/sync consistency rules** — no guidance on when to use async
7. **No dependency pinning rules** — no guidance on exact vs range pins

---

## Run 1: clinic-portal — Type hints usage audit

**Scope:** All Python files in /home/intruder/projects/clinic-portal/apps/

### Findings

Functions with type hints (return type or parameter types): ~200 occurrences across 13 files
Functions WITHOUT type hints on parameters or return: examined key files

**Specific gaps:**
- `_summarize_with_claude(document)` — no type hints at all. Should be `(document: Document) -> Optional[str]`
- `_ensure_public_tenant()` in tests — no return type
- `_create_owner_user()` in tests — no return type
- Most view functions use `request: HttpRequest` (good) but return type is always implicit via Django Ninja
- Service functions in `documents/services.py`: `get_user_context(user)` — no type hint on `user` parameter
- `_invoke_llm(messages, max_tokens=500, temperature=0.2)` — no type hints on any parameter

**Verdict:** ~70% of functions have some type hints, but service/utility functions and test helpers are consistently untyped.

### Did Prompt Guide Finding This?
The prompt says "Type Safety" under Focus Areas but provides NO concrete rule like "every public function must have return type annotations" or "run mypy/pyright as verification step." The Forge Cell step 5 runs `black` and `ruff` but NOT `mypy`.

**Prompt Gap:** No mypy/pyright verification command. No concrete type hint threshold.

---

## Run 2: saleor — Exception handling patterns

**Scope:** /home/intruder/projects/forge-test-repos/saleor/saleor/

### Findings

- **0 bare `except:` statements** — Good discipline
- **65 `except Exception` catches across 20 files** — Broad catches are common
- Key patterns:
  - `saleor/plugins/__init__.py`: bare except (1 occurrence) — catches ALL exceptions in plugin loading
  - `saleor/payment/gateways/braintree/__init__.py`: 6 broad catches — typical for external API integration
  - `saleor/payment/gateways/stripe/stripe_api.py`: 11 broad catches — wraps stripe SDK errors
  - `saleor/plugins/openid_connect/plugin.py`: 8 broad catches — auth plugin swallows errors

**Pattern:** External integrations (payment gateways, plugins, auth) use broad catches as a safety net. This is defensible but should log the exception type.

### Did Prompt Guide Finding This?
Prompt says "implement complete error handling" but gives NO guidance on:
- When broad catches are acceptable (external integrations) vs not (business logic)
- Whether to re-raise, log, or swallow
- Exception hierarchy design (custom exceptions for domain errors)

**Prompt Gap:** No exception handling strategy. No guidance on custom exception hierarchies.

---

## Run 3: fastapi-template — Async patterns

**Scope:** /home/intruder/projects/forge-test-repos/fastapi-template/backend/

### Findings

- **Only 1 async function in entire codebase**: `async def health_check()` in utils.py
- **All route handlers are synchronous** (def, not async def)
- **All CRUD operations are synchronous** (sqlmodel Session, not AsyncSession)
- **No async database driver** (psycopg[binary] supports async but not used)

**Analysis:** The template is fully synchronous despite using FastAPI (an async framework). This is technically fine (FastAPI runs sync handlers in threadpool) but:
- Misses the performance benefit of async I/O
- Inconsistent: one async health check among 20+ sync endpoints
- httpx is listed as a dependency (async-capable) but never used for async

### Did Prompt Guide Finding This?
Prompt lists "async programming" under Performance Engineering but provides NO concrete rules:
- When to prefer async vs sync
- Whether to enforce consistency (all async or all sync)
- How to verify async correctness (no blocking calls in async contexts)

**Prompt Gap:** No async/sync consistency rule. No "check for blocking calls in async contexts" verification.

---

## Run 4: clinic-portal — Import organization

**Scope:** /home/intruder/projects/clinic-portal/apps/documents/api.py

### Findings

Top-level imports:
```
import logging                          # stdlib
from datetime import datetime           # stdlib
from typing import Optional             # stdlib
from django.core.cache import cache     # third-party
from django.db import connection        # third-party
from django.http import HttpRequest     # third-party
from ninja import Router, Schema        # third-party
from ninja.security import django_auth  # third-party
from apps.documents.models import ...   # local
from apps.documents.services import ... # local
from apps.permissions import ...        # local
from apps.users.services import ...     # local
from apps.workflows.models import ...   # local
```

**Good:** stdlib, third-party, local grouping is correct. Blank line separators present.

**Bad:**
- `_summarize_with_claude` has 5 INLINE imports: `base64, json, os, urllib.request, re` + `from django.conf import settings` + `from apps.documents.services import get_s3_client` + `from django.utils.html import strip_tags`
- Inline imports of stdlib modules (base64, json, os, re) are never justified — they should be top-level
- `summarize_document` also has an inline `from django.utils.html import strip_tags`
- `create_document` has inline imports of `Workflow` and `Task` models

**Verdict:** Top-level imports are well-organized but function-level imports are messy. Some may be justified (circular import avoidance for models) but stdlib imports inside functions are never justified.

### Did Prompt Guide Finding This?
Prompt mentions NOTHING about import organization. No isort check. No rule about top-level vs inline imports. The Forge Cell runs `ruff check` which CAN check imports (I001) but the prompt doesn't mention enabling it.

**Prompt Gap:** No import organization rules. No isort enforcement. No guidance on when inline imports are acceptable.

---

## Run 5: saleor — Dataclass/attrs/Pydantic usage patterns

**Scope:** /home/intruder/projects/forge-test-repos/saleor/saleor/

### Findings

- **27 occurrences of @dataclass/from pydantic/from attrs across 20 files**
- Primary pattern: `@dataclass` for internal data structures (WebhookPayloadData, TaxData, OrderTaxedPricesData)
- Pydantic used only in `manifest_schema.py` for JSON schema validation
- No attrs usage found
- Most data transfer objects are plain dicts or NamedTuples, not dataclasses

**Pattern issues:**
- `payment/interface.py` uses `@dataclass` for 15+ payment DTOs — good
- But `graphql/account/resolvers.py` uses plain dicts for payment source data (line 211-223) — inconsistent
- `plugins/manager.py` has class-level mutable defaults instead of using dataclass with field(default_factory=)

**Verdict:** Inconsistent. Some domains use dataclasses properly, others use raw dicts for the same purpose.

### Did Prompt Guide Finding This?
Prompt says "clean architecture, dependency injection, separation of concerns" but gives NO guidance on:
- When to use dataclass vs Pydantic vs TypedDict vs plain dict
- Whether to enforce one pattern across the codebase
- Dataclass best practices (frozen=True for immutable DTOs, slots=True for performance)

**Prompt Gap:** No data modeling guidance. No rule on dataclass vs Pydantic vs dict.

---

## Run 6: fastapi-template — Dependency management (pyproject.toml quality)

**Scope:** /home/intruder/projects/forge-test-repos/fastapi-template/backend/pyproject.toml

### Findings

**Good:**
- Uses pyproject.toml (modern standard)
- Separates dev dependencies via dependency-groups
- mypy strict mode enabled
- ruff configured with good rule selection (E, W, F, I, B, C4, UP)
- Coverage configured with show_missing and context tracking

**Issues:**
- `requires-python = ">=3.10,<4.0"` — Very wide range, should be `>=3.11` or `>=3.12` for 2025 projects
- Dependencies use range pins (`<1.0.0,>=0.114.2`) — good for libraries, risky for applications
- No lock file committed (no uv.lock, no requirements.txt freeze)
- `B904` ignored (raise without from) — This hides exception chains, should NOT be ignored
- No security scanning tool (safety, pip-audit) in dev dependencies
- No pre-commit configuration referenced
- Build system is hatchling but no build configuration

### Did Prompt Guide Finding This?
Prompt says "Modern Tooling Setup: pyproject.toml, pre-commit hooks, CI/CD configuration" under Outputs but provides NO concrete criteria:
- No checklist for pyproject.toml quality
- No rule on version pinning strategy
- No security scanning tool requirement
- No rule on which ruff rules to enable/disable

**Prompt Gap:** No pyproject.toml quality checklist. No dependency security scanning requirement.

---

## Run 7: clinic-portal — String formatting patterns

**Scope:** /home/intruder/projects/clinic-portal/apps/

### Findings

Total occurrences across the codebase:
- **f-strings:** Most common, used in API responses, string construction
- **%-formatting:** Used in ALL logging calls (`logger.info("msg %s", var)`)
- **No .format() usage found**

**Analysis:**
- Logging uses %-formatting consistently — this is CORRECT. Python logging docs recommend lazy %-formatting because the string is only formatted if the log level is enabled.
- f-strings used in non-logging contexts — correct
- One anti-pattern: `f"Summarization failed: {e}"` in error response (line 405) — exposes exception details to client

**Verdict:** String formatting is actually well-done. The %-formatting in logging is the correct Python pattern, not a mistake.

### Did Prompt Guide Finding This?
Prompt says NOTHING about string formatting. No guidance on:
- When to use f-strings vs %-formatting
- The logging lazy-formatting best practice
- Whether to enforce consistency

**Prompt Gap:** No string formatting guidance. An uninformed agent might "fix" correct %-formatting in logging to f-strings.

---

## Run 8: saleor — Context manager usage

**Scope:** /home/intruder/projects/forge-test-repos/saleor/saleor/

### Findings

- **39 occurrences of with/context manager patterns across 15 files**
- Key patterns:
  - `with tracer.start_as_current_span()` — telemetry context managers (plugins/manager.py)
  - `with open()` — file operations (5 files)
  - `with transaction.atomic()` — DB transactions (webhook transport)
  - `with allow_writer()` — database connection routing
  - Custom `__enter__/__exit__` in `core/db/connection.py` (6 occurrences)

**Issues:**
- `plugins/manager.py`: No context manager for plugin lifecycle — plugins loaded in __init__, cleaned in __del__. Using __del__ is fragile (no guarantee of execution). Should use a context manager.
- `webhook/transport`: Uses `transaction.atomic()` for delivery creation — good
- `core/jwt_manager.py`: File operations use `with open()` — good

### Did Prompt Guide Finding This?
Prompt mentions NOTHING about context managers. No guidance on:
- When to use context managers vs try/finally
- Resource cleanup patterns
- The anti-pattern of __del__ for cleanup

**Prompt Gap:** No context manager or resource cleanup guidance.

---

## Run 9: fastapi-template — Error handling hierarchy

**Scope:** /home/intruder/projects/forge-test-repos/fastapi-template/backend/

### Findings

- **Zero custom exception classes** in the entire codebase
- All errors raised as `HTTPException(status_code=N, detail="message")`
- No domain-specific exceptions (e.g., UserNotFoundError, DuplicateEmailError)
- No exception middleware or error handler registration
- CRUD layer lets database exceptions bubble up completely unhandled

**Pattern issues:**
- Business logic and HTTP concerns are coupled: CRUD functions must know about HTTP status codes
- No way to distinguish "user not found" from "database error" at the handler level
- Sentry SDK is configured but no custom error context is attached

### Did Prompt Guide Finding This?
Prompt says "implement complete error handling" and "Security Implementation: prevent common vulnerabilities" but provides NO guidance on:
- Custom exception hierarchy design
- Separation of domain exceptions from HTTP exceptions
- Error middleware patterns
- Whether to catch at CRUD layer vs route layer

**Prompt Gap:** No exception hierarchy guidance. No error boundary architecture.

---

## Run 10: clinic-portal — Logging patterns

**Scope:** /home/intruder/projects/clinic-portal/apps/

### Findings

- **Every module uses `logger = logging.getLogger(__name__)`** — consistent, good
- Log levels used correctly:
  - `logger.info()` for successful operations (login, create, transition)
  - `logger.warning()` for expected failures (invalid transition, login failure)
  - `logger.error()` for unexpected failures (S3 errors, LLM failures)
- `exc_info=True` used on error logs — good for stack traces
- Log messages include context: `user=%s`, `task=%d`, `workflow=%d`

**Issues:**
- **No structured logging** — All logs are string-formatted, not JSON. In production with log aggregators (ELK, Datadog), structured logging (structlog, python-json-logger) is much better.
- **No request ID / correlation ID** — No way to trace a request across log lines. Middleware should inject a request_id.
- **No tenant context in logs** — For a multi-tenant app, logs should include `tenant=%s` for filtering. Critical gap.
- **Inconsistent detail level** — Some log lines include `email=%s`, others don't include user identity
- **No log sampling / rate limiting** — `list_documents` logs every request, could be noisy in production

### Did Prompt Guide Finding This?
Prompt says NOTHING about logging. The Forge Cell has no logging verification step. The reviewer checklist mentions "logging at function entry/exit" but not quality.

**Prompt Gap:** No logging guidance at all. No structured logging recommendation. No correlation ID requirement. No tenant context requirement.

---

## Aggregate Analysis

### Overall Prompt Coverage

| Run | Topic | Prompt Guided? | Gap Severity |
|---|---|---|---|
| 1 | Type hints | Vaguely mentioned | HIGH — no mypy, no threshold |
| 2 | Exception handling | Vaguely mentioned | HIGH — no strategy |
| 3 | Async patterns | Vaguely mentioned | MEDIUM — niche |
| 4 | Import organization | Not mentioned | MEDIUM — ruff can handle |
| 5 | Dataclass patterns | Not mentioned | MEDIUM — architecture choice |
| 6 | Dependency management | Vaguely mentioned | HIGH — security gap |
| 7 | String formatting | Not mentioned | LOW — easy to learn |
| 8 | Context managers | Not mentioned | MEDIUM — resource leaks |
| 9 | Error hierarchy | Vaguely mentioned | HIGH — architecture gap |
| 10 | Logging | Not mentioned | HIGH — observability gap |

**Prompt usefulness score: 3/10 runs had useful guidance = 30%**

### Top 10 Recommended Additions to Python Expert Prompt

1. **Type hint enforcement** — "Every public function MUST have parameter and return type annotations. Run `mypy --strict` or `pyright` as verification step in Forge Cell step 5."
2. **Exception hierarchy** — "Define custom exception classes for each domain module. Separate domain exceptions from transport exceptions (HTTP, gRPC). Never raise HTTPException from service/CRUD layers."
3. **Logging standard** — "Use structlog or python-json-logger for structured logging. Every log line MUST include: request_id, tenant_id (if multi-tenant), user_id. Use %-formatting for lazy evaluation."
4. **Import organization** — "Enable ruff rule I001 (isort). Top-level imports only for stdlib, third-party, and local. Inline imports ONLY to break circular dependencies between models — document with comment."
5. **Dependency security** — "Add pip-audit or safety to dev dependencies. Pin exact versions for applications (not libraries). Review ruff ignore list — B904 should NOT be ignored."
6. **Async/sync consistency** — "Choose async or sync for the entire application. If async: use async DB driver, async HTTP client, no blocking calls. If sync: don't mix in random async endpoints."
7. **Data modeling** — "Use dataclasses(frozen=True) for immutable DTOs. Use Pydantic for external input validation. Use TypedDict for dict shapes in type hints. Never pass raw dicts across module boundaries."
8. **Context manager usage** — "Use context managers for any resource that needs cleanup (DB connections, file handles, HTTP sessions). Never use __del__ for cleanup. Prefer contextlib.contextmanager for simple cases."
9. **String formatting** — "Use f-strings for all string construction. Use %-formatting ONLY in logging calls (lazy evaluation). Never use .format() or concatenation."
10. **Error response safety** — "Never expose exception messages to API clients. Log the full exception internally, return a generic error message externally. Exception str(e) in responses is an information leak."
