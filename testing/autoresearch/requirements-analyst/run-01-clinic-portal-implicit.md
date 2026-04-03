# Run 01: Extract All Implicit Requirements from clinic-portal SPEC.md + Code

## Source: clinic-portal SPEC.md, config/settings.py, apps/workflows/models.py, apps/documents/services.py

## Extracted Requirements

### Functional Requirements (Explicit in SPEC.md)

- [REQ-F001] Multi-tenant isolation via PostgreSQL schema-per-tenant
  - Given a clinic tenant, When any query runs, Then only that tenant's schema is accessed
- [REQ-F002] Clinic registration creates new tenant with subdomain
  - Given a new clinic signup, When registration completes, Then a new PG schema and Domain record are created
- [REQ-F003] User authentication with session-based auth
  - Given valid credentials, When user logs in, Then a session is created and stored in Redis
- [REQ-F004] Workflow CRUD with audit logging
  - Given an admin user, When creating/updating/deleting a workflow, Then an AuditLog entry is created
- [REQ-F005] Task state machine with enforced transitions
  - Given a task in status X, When transitioning to status Y, Then VALID_TRANSITIONS dict is checked
- [REQ-F006] Document upload via S3 presigned URLs
  - Given a user, When requesting upload, Then a presigned PUT URL with 900s expiry is returned
- [REQ-F007] AI summarization of documents via Claude Haiku
  - Given a document, When summarize is requested, Then LLM output is validated and sanitized before storage
- [REQ-F008] AI task generation with reflexion retry
  - Given a workflow description, When AI generation is requested, Then 3-8 tasks are generated with JSON validation
- [REQ-F009] Clinical QA search (ClinicalTrials.gov + PubMed + RAG)
  - Given a medical query, When search runs, Then parallel API calls fetch trials and papers, RAG summary is generated
- [REQ-F010] Conversational clinical chat with thread context
  - Given a chat thread, When user sends message, Then last 10 messages + stored context are sent to Claude

### Implicit Requirements (NOT Explicitly Stated, Inferred from Code)

- [REQ-I001] **Idempotent seed data**: `seed_demo.py` must be idempotent (SPEC says "idempotent" but code must handle existing records gracefully)
  - Given seed_demo has been run, When it runs again, Then no duplicate records are created
- [REQ-I002] **Railway deployment compatibility**: settings.py parses `DATABASE_URL` env var for Railway hosting
  - Given DATABASE_URL is set, When Django starts, Then it parses the URL but overrides the engine to django_tenants backend
- [REQ-I003] **Ngrok/external domain support**: CSRF_TRUSTED_ORIGINS includes ngrok and custom domain patterns
  - Given NGROK_URL is set, When requests come from that domain, Then CSRF validation passes
- [REQ-I004] **Static file serving via WhiteNoise**: WhiteNoise middleware serves static files in production without a separate nginx
  - Given a production deployment, When static files are requested, Then WhiteNoise serves them from STATIC_ROOT
- [REQ-I005] **Password reset enforcement middleware**: Staff invited by admin must reset password before accessing any page
  - Given a user with must_reset_password=True, When they access any page, Then they are redirected to password reset
- [REQ-I006] **Session-scoped recent actions tracking**: Last 5 user actions stored in session (not DB)
  - Given a user action, When it completes, Then it's appended to request.session["recent_actions"] (max 5)
- [REQ-I007] **LLM output sanitization as security requirement**: strip_tags() on ALL LLM output before storage
  - Given LLM output, When it's processed, Then HTML tags are stripped (defense against prompt injection/XSS)
- [REQ-I008] **Graceful degradation when Lambda is not configured**: Falls back to direct Claude API calls
  - Given LAMBDA_SUMMARIZE_ARN is empty, When summarization runs, Then direct Anthropic API is called instead
- [REQ-I009] **Tenant prefix validation on S3 keys**: Download URL generation must verify the S3 key belongs to the current tenant
  - Given a document download request, When the S3 key is checked, Then it must start with the current tenant's schema name
- [REQ-I010] **AuditLog immutability enforced at model level**: save() rejects updates, delete() raises error
  - Given an existing AuditLog entry, When update or delete is attempted, Then ValueError is raised

### Non-Functional Requirements (Implicit)

- [REQ-NF001] **Cache TTLs are differentiated by data volatility**: Dashboard 60s, workflow list 30s, S3 URLs 14min, LLM summaries 24hr
- [REQ-NF002] **10-point structured logging**: Every app logs entry/exit, errors, external calls, security events, performance warnings
- [REQ-NF003] **Never log sensitive data**: passwords, API keys, session tokens, PII (email OK in auth only)
- [REQ-NF004] **All external calls wrapped in try/except**: ClientError, timeout, credentials errors handled separately
- [REQ-NF005] **LLM temperature tuned per use case**: 0.2 for summarization (deterministic), 0.5 for task generation (creative)

## Evaluation

### Did the prompt guide good requirements extraction?
- **Discovery via Socratic questioning**: N/A - reverse engineering mode, no stakeholder to question
- **REQ-xxx tagging**: YES - all requirements tagged
- **Acceptance criteria (Given/When/Then)**: PARTIAL - provided for functional reqs but not all implicit ones
- **Completeness check**: PARTIAL - cross-checked SPEC vs code but may have missed edge cases
- **Duplicate check**: YES - no duplicates found

### Prompt Gaps Identified
1. **No explicit "reverse engineering" mode** — the prompt focuses on discovery FROM stakeholders, not FROM code. When extracting from existing code, the Socratic questioning approach doesn't apply. The prompt needs a "reverse engineering" workflow.
2. **No instruction to categorize implicit vs explicit** — the prompt doesn't distinguish between requirements stated in docs vs requirements only visible in code. This distinction matters for validation.
3. **No instruction to check for "defensive requirements"** — security measures, error handling, and graceful degradation are requirements even if nobody wrote them down. The prompt should instruct: "look for defensive coding patterns and extract the implicit requirement they satisfy."
