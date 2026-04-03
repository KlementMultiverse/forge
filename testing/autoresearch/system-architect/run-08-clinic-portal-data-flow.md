# Run 08: clinic-portal — Data Flow Architecture (Request → Middleware → View → Service → DB)

## Source Files
- `/home/intruder/projects/clinic-portal/config/settings.py` (middleware chain)
- `/home/intruder/projects/clinic-portal/apps/users/api.py` (NinjaAPI setup)
- `/home/intruder/projects/clinic-portal/apps/workflows/api.py` (router example)
- `/home/intruder/projects/clinic-portal/apps/documents/services.py` (service layer)
- `/home/intruder/projects/clinic-portal/apps/search/services.py` (external API integration)

## Findings

### Request Data Flow

```
HTTP Request
  │
  ├─ [1] TenantMainMiddleware → resolve subdomain → set connection.schema_name
  ├─ [2] SecurityMiddleware → add security headers (X-Content-Type-Options, etc.)
  ├─ [3] WhiteNoiseMiddleware → serve static files (short-circuit if static)
  ├─ [4] SessionMiddleware → load session from Redis (tenant-aware key)
  ├─ [5] CommonMiddleware → URL normalization
  ├─ [6] CsrfViewMiddleware → validate CSRF token (for session auth)
  ├─ [7] AuthenticationMiddleware → load User from session
  ├─ [8] PasswordResetMiddleware → redirect if must_reset_password
  ├─ [9] SafeTenantAccessMiddleware → verify user belongs to tenant
  ├─ [10] MessageMiddleware → flash messages
  ├─ [11] XFrameOptionsMiddleware → X-Frame-Options: DENY
  │
  ├─ URL Resolution (config/urls.py or config/urls_public.py)
  │
  ├─ Django Ninja Router
  │   ├─ Auth check (django_auth → session-based)
  │   ├─ Schema validation (Pydantic input schemas)
  │   ├─ View function
  │   │   ├─ Permission check (require_admin decorator)
  │   │   ├─ Service call (if external API or complex logic)
  │   │   │   ├─ S3 operations (presigned URLs)
  │   │   │   ├─ LLM calls (Claude API or Lambda)
  │   │   │   ├─ External APIs (ClinicalTrials.gov, PubMed)
  │   │   │   └─ Error handling (try/except for every external call)
  │   │   ├─ ORM query (routed to tenant schema by TenantSyncRouter)
  │   │   ├─ AuditLog creation (for state mutations)
  │   │   ├─ Session tracking (track_action for recent_actions)
  │   │   └─ Cache operations (get/set with tenant-aware keys)
  │   └─ Schema validation (Pydantic output schemas)
  │
  └─ HTTP Response
```

### Architectural Layers Analysis

| Layer | Implementation | Separation Quality |
|---|---|---|
| Presentation | Django templates + vanilla JS | GOOD — separate from API |
| API | Django Ninja routers + Pydantic schemas | GOOD — typed contracts |
| Middleware | Django middleware chain | GOOD — well-ordered |
| Authorization | Session auth + role check | PARTIAL — role is global, not per-tenant |
| Service | `services.py` files in some apps | INCONSISTENT — not all apps have services |
| Data Access | Django ORM via models | GOOD — automatic tenant routing |
| Cache | Redis with tenant-aware keys | GOOD — transparent to application code |
| External Integration | `services.py` with error handling | GOOD — all external calls have try/except |

### Inconsistencies Found

1. **Service layer inconsistency:**
   - `documents/services.py` — comprehensive (S3, LLM, validation).
   - `search/services.py` — comprehensive (external APIs, caching, query rewriting).
   - `users/services.py` — minimal (only `track_action()`).
   - `workflows/` — NO services.py. Business logic (including LLM task generation) is called from api.py via `documents/services.py`.
   - `dashboard/` — NO services.py. Stats aggregation is in api.py.

2. **Cross-app service dependency:**
   - `workflows/api.py` imports `from apps.documents.services import get_user_context, invoke_generate_tasks_lambda`.
   - The workflows app depends on documents for LLM functionality — this is a module boundary violation.
   - LLM services should be in a shared location (e.g., `apps.core.services` or a standalone `services/llm.py`).

3. **Caching pattern inconsistency:**
   - Workflows use cache in api.py (inline `cache.get()`/`cache.set()`).
   - Documents use cache for download URLs (in api.py).
   - Search uses cache in services.py.
   - No central cache abstraction — each app implements caching differently.

4. **AuditLog creation location:**
   - In `Task.transition_to()` — model method.
   - In `workflows/api.py` — view function for CRUD.
   - In `documents/api.py` — view function.
   - Not consistent — sometimes in model, sometimes in view.

### Data Flow for External API Calls

```
Search Query Flow:
  User → API → services.rewrite_query(query) → Claude API (with caching)
                → services.search_clinical_trials(rewritten_query) → ClinicalTrials.gov API (with caching)
                → services.search_pubmed(rewritten_query) → PubMed API (with caching)
                → services.summarize_results(trials, papers) → Claude API (RAG)
                → Save to SearchHistory
                → Return to user

Document Summarize Flow:
  User → API → services.invoke_summarize_lambda(text)
                → Lambda (if ARN set) OR direct Claude API
                → services._validate_summary(raw_output) → strip_tags, length check
                → Save summary to Document
                → Return to user
```

## Gaps Identified for Agent Prompt
1. **Service layer consistency**: Agent should verify all apps have consistent service layers and flag when business logic is in the wrong layer (views vs services).
2. **Cross-module dependency analysis**: Agent should identify and flag cross-app service imports that violate module boundaries.
3. **Caching pattern consistency**: Agent should check that caching is applied consistently (same location, same patterns) across all modules.
4. **Data flow tracing**: Agent should trace the full request-response flow including middleware, authorization, service, DB, and cache interactions.
5. **AuditLog/logging location consistency**: Agent should verify audit trail creation is in a consistent location (always in models, always in services, or always in views).
6. **External API call inventory**: Agent should catalog all external API integrations and verify they have proper error handling, caching, and timeout configuration.
