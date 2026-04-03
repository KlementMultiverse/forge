# Stage 2: ARCHITECT — Output

Project: Bookmark Manager with AI Summaries
Status: COMPLETE (75% implementation-ready)

## What Was Produced
- 10-section design doc following exact template
- 8 design decisions with "Will implement X because" format
- Exact API contracts with JSON shapes for all endpoints
- 30 test scenarios (15+ required, delivered 30)
- 10 logging points
- Django Ninja Schema classes defined

## CRITICAL Gaps Found

### Blocking (would stop Stage 3):
1. Lambda async flow ambiguous — document says async polling but no callback endpoint defined
2. No summary-callback webhook endpoint in API contracts

### Causing Developer Guesswork:
3. No settings.py skeleton (DATABASES, MIDDLEWARE, CACHES config)
4. No error response JSON shapes (only status codes)
5. No Redis cache key patterns or invalidation rules
6. No urls.py routing specification (NinjaAPI mounting)
7. SearchVector update trigger unspecified (signal vs explicit)
8. No pagination implementation (django-ninja has no built-in)
9. Title auto-fetch service not specified (sync/async, HTML parser)
10. No migration note for pg_trgm extension / django.contrib.postgres

## Prompt Enhancements Needed for /design-doc

The /design-doc template should MANDATE these sections in Section 4:
1. **Settings skeleton** — at minimum DATABASES, MIDDLEWARE, CACHES, INSTALLED_APPS
2. **Error response schema** — standard error JSON shape for all endpoints
3. **Cache key patterns** — exact key strings with TTL and invalidation rules
4. **URL routing config** — how NinjaAPI/routers are mounted in urls.py
5. **Async flow completeness** — if any flow is async, BOTH sides must be specified
6. **Pagination strategy** — library choice, page_size default, max
