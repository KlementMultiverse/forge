# Run 05: Extract Non-Functional Requirements from clinic-portal

## Source: config/settings.py, apps/documents/services.py, SPEC.md (Redis/Observability/Error Handling sections)

## Extracted Requirements

### Performance

- [REQ-PERF001] Dashboard stats cached for 60 seconds
  - Given a dashboard request, When stats are fetched, Then cached result is returned if within 60s TTL
- [REQ-PERF002] Workflow list cached for 30 seconds
  - Given a workflow list request, When data is fetched, Then cached result is returned if within 30s TTL
- [REQ-PERF003] S3 download URLs cached for 14 minutes (840s)
  - Given a document download, When URL is requested, Then cached presigned URL is returned (shorter than 15min expiry for safety margin)
- [REQ-PERF004] LLM summaries cached for 24 hours
  - Given a document, When summary exists in cache, Then cached summary is returned without re-invoking LLM
- [REQ-PERF005] Clinical trial results cached for 6 hours, PubMed papers for 7 days
  - Given a medical search, When same query is repeated, Then cached external API results are returned
- [REQ-PERF006] Performance warning logging for queries > 500ms
  - Given any database query, When execution exceeds 500ms, Then a performance warning is logged

### Security

- [REQ-SEC001] Session cookies are HTTPOnly, SameSite=Lax, Secure in production
  - Given production deployment, When session cookie is set, Then HTTPOnly + Secure + SameSite=Lax flags are applied
  - Evidence: `SESSION_COOKIE_HTTPONLY = True`, `SESSION_COOKIE_SECURE = not DEBUG`
- [REQ-SEC002] CSRF protection with trusted origins whitelist
  - Given a POST request, When CSRF token is validated, Then only trusted origins are accepted
  - Evidence: `CSRF_TRUSTED_ORIGINS` list in settings.py
- [REQ-SEC003] X-Frame-Options: DENY (clickjacking prevention)
  - Given any response, When headers are set, Then X-Frame-Options is DENY
  - Evidence: `X_FRAME_OPTIONS = "DENY"`
- [REQ-SEC004] Content-Type-Options: nosniff
  - Given any response, When headers are set, Then X-Content-Type-Options is nosniff
  - Evidence: `SECURE_CONTENT_TYPE_NOSNIFF = True`
- [REQ-SEC005] LLM output sanitization (XSS prevention)
  - Given any LLM-generated text, When stored in DB, Then strip_tags() is applied first
  - Evidence: `_validate_summary()` and `_validate_tasks_json()` both call strip_tags()
- [REQ-SEC006] S3 key tenant prefix validation
  - Given a document access request, When S3 key is used, Then it must start with current tenant schema name
- [REQ-SEC007] Credentials never hardcoded
  - Given any credential, When accessed in code, Then it comes from os.environ or .env file
  - Evidence: All settings.py credentials use `os.environ.get()`
- [REQ-SEC008] SECRET_KEY validation in production
  - Given DEBUG=False, When SECRET_KEY is empty, Then ValueError is raised on startup
- [REQ-SEC009] Sensitive data never logged
  - Given logging output, When events are logged, Then passwords, API keys, session tokens are excluded

### Availability / Resilience

- [REQ-AVAIL001] Graceful degradation for external services
  - Given S3/Lambda/Claude API failure, When error occurs, Then structured error is returned, never unhandled exception
  - Evidence: Every external call in services.py has try/except for ClientError, timeout, credentials
- [REQ-AVAIL002] Lambda fallback to direct API calls
  - Given LAMBDA_SUMMARIZE_ARN is not set, When LLM functions are called, Then direct Anthropic API is used
- [REQ-AVAIL003] LLM reflexion retry (max 1)
  - Given LLM output fails validation, When retry is attempted, Then error context is included in retry prompt (max 1 retry)
- [REQ-AVAIL004] Empty LLM output handling
  - Given LLM returns empty response, When validation runs, Then "Summary unavailable" is stored (never empty string)

### Observability

- [REQ-OBS001] 10-point structured logging at INFO level
  - Given any operation, When executed, Then entry/exit, errors, external calls, state mutations, security events are logged
- [REQ-OBS002] Function entry/exit logging with parameters
  - Given any service function, When called, Then parameters are logged at entry and result summary at exit
  - Evidence: `logger.info("LLM invoke: task_type=%s", "summarize_document")` and `logger.info("LLM result: %d chars", len(result))`
- [REQ-OBS003] External API call logging
  - Given any S3/Lambda/httpx call, When executed, Then the operation and key/ARN are logged
  - Evidence: `logger.info("S3 generate_upload_url: key=%s", s3_key)`

### Data Integrity

- [REQ-DATA001] AuditLog immutability
  - Given an AuditLog entry, When update or delete is attempted, Then ValueError is raised
- [REQ-DATA002] Task state transition validation
  - Given a task, When status change is requested, Then VALID_TRANSITIONS dict is enforced
- [REQ-DATA003] Tenant-aware Redis cache keys
  - Given any cache operation, When key is computed, Then `django_tenants.cache.make_key` is used (includes schema name)
  - Evidence: `KEY_FUNCTION = "django_tenants.cache.make_key"` in CACHES config

### Infrastructure

- [REQ-INFRA001] Docker Compose for local dev (PG 15+ + Redis 7 + Django)
  - Given a developer, When setting up locally, Then `docker compose up` provides all dependencies
- [REQ-INFRA002] uv for package management (never pip)
  - Given any package operation, When packages are installed, Then `uv` is used
- [REQ-INFRA003] Django migrations separated by schema type
  - Given migrations, When applied, Then `migrate_schemas --shared` and `--tenant` run separately

## Evaluation

### Did the prompt guide good NFR extraction?
- **Discovery**: YES — systematically covered performance, security, availability, observability, data integrity, infrastructure
- **REQ-xxx tagging**: YES — category-prefixed (PERF, SEC, AVAIL, OBS, DATA, INFRA)
- **Acceptance criteria**: PARTIAL — Given/When/Then for most, some just described
- **Completeness**: Good for a single codebase — covered all major NFR categories
- **Duplicate check**: YES

### Prompt Gaps Identified
1. **No NFR extraction taxonomy** — the prompt's Chaos Resilience says "add defaults (performance, security, observability)" but doesn't provide a systematic taxonomy. Should include: "for NFR extraction, use these categories: Performance, Security, Availability, Observability, Data Integrity, Infrastructure, Scalability"
2. **No instruction to extract QUANTITATIVE requirements from code** — the cache TTLs (60s, 30s, 14min, 24hr) are quantitative requirements embedded in code. The prompt should instruct: "when extracting NFRs, look for hard-coded numbers (timeouts, limits, TTLs) and express them as measurable requirements"
