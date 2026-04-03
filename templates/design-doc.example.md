# Multi-Tenant Clinic Management Portal — Design Document

<!-- COMPLETENESS: Header establishes traceability back to proposal and current status -->
**Date:** 2026-03-30
**Proposal:** docs/proposals/01-clinic-portal-mvp.md
**Status:** Approved

---

## 1. Current Context
<!-- REQUIRED: Every design doc starts with WHERE WE ARE, not where we're going -->

### Existing System
Greenfield project. No existing code beyond project configuration (CLAUDE.md, SPEC.md, pyproject.toml stub).

### Gap Being Addressed
Small/medium medical clinics lack affordable tools for internal business process management. Current solutions (spreadsheets, Trello, Notion) offer no data isolation between organizations, no audit trails, and no domain-specific AI assistance.

### Scope
- **Users:** Clinic admins (CRUD workflows), clinic staff (execute tasks), platform superadmins (monitor tenants)
- **Scale:** MVP targets 10-50 tenants, designed to scale to 100+ without architecture changes
- **Deployment:** Local development via Docker Compose (PostgreSQL + Redis + Django)
- **Tenancy:** Full schema-per-tenant isolation via django-tenants

<!-- COMPLETENESS: Section 1 must answer: what exists, what's missing, who uses it, how big -->

---

## 2. Requirements
<!-- REQUIRED: Every requirement gets a [REQ-xxx] tag so tests and code can trace back -->

### Functional Requirements
- **[REQ-001]** Clinic signup creates an isolated tenant with its own PostgreSQL schema and subdomain
- **[REQ-002]** Session-based authentication with Redis backend; users are global, tenant access is granted
- **[REQ-003]** Role-based access: admin (full CRUD) and staff (read + task operations)
- **[REQ-004]** Workflow CRUD with task management via enforced state machine (created -> assigned -> in_progress -> completed/cancelled)
- **[REQ-005]** AuditLog tracks every state mutation with entity type, action, performer, and timestamp
- **[REQ-006]** Document upload/download via S3 presigned URLs with tenant-namespaced keys
- **[REQ-007]** AI document summarization and task generation via Lambda invocation
- **[REQ-008]** Dashboard with aggregate statistics per tenant
- **[REQ-009]** Staff management: add by email, remove (admin only)
- **[REQ-010]** Superadmin can list all tenants

### Non-Functional Requirements
<!-- REQUIRED: Every NFR must have a MEASURABLE number, not "fast" or "scalable" -->
- **Performance:** API responses < 200ms p95 for CRUD; < 500ms p95 for list endpoints; Lambda summarization < 30s
- **Scalability:** Schema-per-tenant supports 100+ tenants; stateless Django for horizontal scaling
- **Observability:** Structured JSON logging at 10 required points; AuditLog for all mutations
- **Security:** CSRF on all session-authenticated mutating endpoints; tenant isolation at DB/S3/Redis layers
- **Reliability:** Graceful degradation when AWS credentials missing; Lambda timeout handling; transaction-wrapped mutations

<!-- COMPLETENESS: Performance targets are numbers, not adjectives. A developer can write a test for "< 200ms" but not for "fast" -->

---

## 3. Design Decisions
<!-- REQUIRED: Minimum 8 decisions. Every decision uses this exact format -->

### Decision 1: Schema-per-Tenant via django-tenants
Will implement PostgreSQL schema-per-tenant isolation because:
- Complete data isolation at DB level — a queryset bug cannot leak data across tenants
- Tenant deletion is `DROP SCHEMA CASCADE` — clean and atomic
- Trade-off: Migration complexity grows linearly with tenant count
- Alternative considered: Row-level tenancy with `tenant_id` FK — simpler migrations but weaker isolation; a single missing filter leaks all tenant data

### Decision 2: Django Ninja for API Layer
Will implement Django Ninja with Pydantic Schema classes because:
- Native Python type hints for request/response validation
- Faster request handling than DRF; less boilerplate
- Trade-off: Smaller ecosystem and community than DRF
- Alternative considered: DRF — more mature but explicitly prohibited by project rules

### Decision 3: Session Auth via Redis (not JWT)
Will implement session-based authentication with Redis backend because:
- Django's built-in session framework handles creation, rotation, and expiry
- Redis provides sub-millisecond session lookups
- Session cookies are `HttpOnly` — not accessible to JavaScript (XSS-resistant)
- Trade-off: Requires Redis as a runtime dependency; sessions are server-stateful
- Alternative considered: JWT tokens — stateless but token revocation is complex

### Decision 4: S3 Presigned URLs (never proxy uploads)
Will implement presigned URL upload/download pattern because:
- Django never handles file bytes — keeps the server stateless and lightweight
- Keys namespaced by `{tenant_schema_name}/{uuid}/{filename}` enforce tenant isolation
- 15-minute expiry limits the window for URL leakage
- Trade-off: Two-step upload flow adds client complexity
- Alternative considered: Server-proxied uploads — simpler client but creates bandwidth bottleneck

### Decision 5: Lambda for LLM Integration (not direct OpenAI)
Will implement AWS Lambda as the sole LLM integration point because:
- Django never holds OpenAI API keys — isolates cost, rate limiting, and credential rotation
- Lambda scales independently; cold starts acceptable for user-triggered summarization
- Trade-off: Added AWS dependency; Lambda cold starts add 1-3s latency
- Alternative considered: Direct OpenAI SDK calls from Django — puts API keys in the web server

### Decision 6: Django Templates + Vanilla JS (no SPA)
Will implement server-rendered templates with Pico CSS because:
- No build step, no Node dependency, simpler deployment
- Staff-facing internal tool — does not need SPA-level interactivity
- Trade-off: Less responsive UI for complex interactions; full page reloads for navigation
- Alternative considered: React SPA — explicitly prohibited by SPEC

### Decision 7: CSRF via SessionAuth(csrf=True), NOT NinjaAPI(csrf=True)
<!-- COMPLETENESS: This is a CORRECTED decision — the original used NinjaAPI(csrf=True) which does not work correctly with django-ninja's auth system -->
Will implement CSRF per auth class using `SessionAuth(csrf=True)` because:
- django-ninja handles CSRF enforcement at the auth class level, not the API level
- `NinjaAPI(csrf=True)` applies CSRF globally including to unauthenticated endpoints, causing false rejections
- Frontend JS must include CSRF token in `X-CSRFToken` header for all mutating requests
- Trade-off: Must verify the `csrf` parameter exists in the installed django-ninja version
- Alternative considered: `NinjaAPI(csrf=True)` — applies CSRF too broadly; breaks unauthenticated endpoints like login/register

### Decision 8: AuditLog in Tenant Schema with INSERT-Only
Will implement AuditLog as a tenant-scoped model with write-only access because:
- Every tenant's audit trail is isolated within their schema
- `INSERT`-only DB permissions prevent admin users from tampering with audit records
- Trade-off: Audit table grows linearly with mutations; needs eventual partitioning
- Alternative considered: Centralized audit in public schema — breaks isolation principle

### Decision 9: Tenant User Provisioning via django-tenant-users
Will implement `provision_tenant()` and `tenant.add_user()` from django-tenant-users because:
- Users are global (public schema); tenant access is a separate relationship
- A single user can belong to multiple tenants
- Trade-off: Global user table means email uniqueness is system-wide
- Alternative considered: Per-tenant user tables — breaks global identity model

### Decision 10: Temporary Password with Server-Side Forced Reset
Will implement temporary password flow with `must_reset_password` middleware because:
- SPEC excludes email/SMS — cannot send invite links
- Middleware intercepts all requests from users with `must_reset_password=True`
- Trade-off: Admin must securely communicate temp password out-of-band
- Alternative considered: Email invite links — explicitly excluded by SPEC

---

## 4. Technical Design

### 4.1 Project Structure
```
config/
+-- settings.py          # Django settings (see 4.5)
+-- urls.py              # Tenant-specific URL routing (mounts NinjaAPI)
+-- urls_public.py       # Public schema URLs (landing, signup)
+-- wsgi.py

apps/
+-- tenants/             # SHARED — Tenant + Domain models, provisioning
+-- users/               # SHARED — Global user model, auth
+-- workflows/           # TENANT — Business process automation
+-- documents/           # TENANT — S3 file management
+-- dashboard/           # TENANT — Statistics
```

### 4.2 Data Models

<!-- REQUIRED: Every model needs field names, types, constraints, relationships, on_delete, indexes -->

```python
# apps/tenants/models.py (SHARED)
class Tenant(TenantBase):
    name = CharField(max_length=100)
    created_at = DateTimeField(auto_now_add=True)
    auto_create_schema = True

class Domain(DomainMixin):
    pass  # Maps hostname -> tenant

# apps/users/models.py (SHARED)
class User(UserProfile):
    name = CharField(max_length=150)
    role = CharField(choices=["admin", "staff"], default="staff")
    must_reset_password = BooleanField(default=False)

# apps/workflows/models.py (TENANT)
class Workflow(Model):
    name = CharField(max_length=200)
    description = TextField(blank=True)
    created_by = FK(User, on_delete=CASCADE)
    created_at = DateTimeField(auto_now_add=True)
    modified_at = DateTimeField(auto_now=True)
    class Meta:
        indexes = [models.Index(fields=["-created_at"])]

class Task(Model):
    VALID_TRANSITIONS = {
        "created": ["assigned", "cancelled"],
        "assigned": ["in_progress", "cancelled"],
        "in_progress": ["completed", "cancelled"],
        "completed": [],
        "cancelled": [],
    }
    workflow = FK(Workflow, related_name="tasks", on_delete=CASCADE)
    title = CharField(max_length=300)
    description = TextField(blank=True)
    status = CharField(choices=[...], default="created", db_index=True)
    assigned_to = FK(User, null=True, blank=True, on_delete=SET_NULL)
    created_by = FK(User, on_delete=CASCADE)
    due_date = DateTimeField(null=True, blank=True)
    created_at = DateTimeField(auto_now_add=True)
    modified_at = DateTimeField(auto_now=True)

class AuditLog(Model):
    entity_type = CharField(max_length=50)  # "task", "workflow", "document"
    entity_id = IntegerField()
    action = CharField(max_length=200)
    details = JSONField(default=dict, blank=True)
    performed_by = FK(User, null=True, on_delete=SET_NULL)
    timestamp = DateTimeField(auto_now_add=True)
    class Meta:
        ordering = ["-timestamp"]
        indexes = [
            models.Index(fields=["entity_type", "entity_id"]),
            models.Index(fields=["-timestamp"]),
        ]

# apps/documents/models.py (TENANT)
class Document(Model):
    name = CharField(max_length=300)
    s3_key = CharField(max_length=500)  # {tenant_schema}/{uuid}/{filename}
    content_type = CharField(max_length=100)
    size_bytes = IntegerField()
    summary = TextField(blank=True)  # LLM-generated, strip_tags() before storage
    workflow = FK(Workflow, null=True, blank=True, on_delete=SET_NULL)
    task = FK(Task, null=True, blank=True, on_delete=SET_NULL)
    uploaded_by = FK(User, on_delete=CASCADE)
    created_at = DateTimeField(auto_now_add=True)
```

### 4.3 Pydantic Schema Classes
<!-- COMPLETENESS: The original design doc had models but NO schemas. Without these, developers invent their own request/response shapes and they diverge. -->

```python
# apps/workflows/schemas.py
from ninja import Schema
from datetime import datetime

class WorkflowIn(Schema):
    name: str
    description: str = ""

class WorkflowOut(Schema):
    id: int
    name: str
    description: str
    created_by_id: int
    created_at: datetime
    modified_at: datetime

class TaskIn(Schema):
    title: str
    description: str = ""
    workflow_id: int
    due_date: datetime | None = None

class TaskTransitionIn(Schema):
    new_status: str

class TaskAssignIn(Schema):
    assigned_to: int

class TaskOut(Schema):
    id: int
    title: str
    description: str
    status: str
    workflow_id: int
    assigned_to_id: int | None
    created_by_id: int
    due_date: datetime | None
    created_at: datetime
    modified_at: datetime

# apps/documents/schemas.py
class UploadUrlIn(Schema):
    filename: str
    content_type: str

class UploadUrlOut(Schema):
    presigned_url: str
    s3_key: str

class DocumentRegisterIn(Schema):
    name: str
    s3_key: str
    content_type: str
    size_bytes: int
    workflow_id: int | None = None
    task_id: int | None = None

class DocumentOut(Schema):
    id: int
    name: str
    content_type: str
    size_bytes: int
    summary: str
    workflow_id: int | None
    task_id: int | None
    uploaded_by_id: int
    created_at: datetime
```

### 4.4 Error Response Standard
<!-- COMPLETENESS: Without this, each endpoint invents its own error format. ONE shape for all errors. -->

```python
class ErrorOut(Schema):
    """Standard error response — used by ALL endpoints."""
    detail: str           # Human-readable message
    code: str             # Machine-readable code (e.g., "invalid_transition", "not_found")
    field: str | None = None  # Which field caused the error (for validation)

# Usage in endpoints:
@router.post("/", response={201: WorkflowOut, 400: ErrorOut, 403: ErrorOut})
def create_workflow(request, payload: WorkflowIn):
    ...
```

Standard error codes:
| Code | HTTP Status | When |
|------|-------------|------|
| `validation_error` | 422 | Pydantic schema rejects input |
| `not_found` | 404 | Entity does not exist in tenant schema |
| `forbidden` | 403 | Role insufficient or wrong tenant |
| `invalid_transition` | 400 | Task state machine rejects transition |
| `external_error` | 502 | S3 or Lambda call failed |
| `unauthenticated` | 401 | No valid session |

### 4.5 settings.py Skeleton
<!-- COMPLETENESS: Without this, the implementer guesses at config. This is copy-paste ready. -->

```python
import os
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = os.environ["SECRET_KEY"]
DEBUG = os.environ.get("DEBUG", "False").lower() == "true"
ALLOWED_HOSTS = os.environ.get("ALLOWED_HOSTS", "localhost").split(",")

# --- Multi-tenancy ---
TENANT_MODEL = "tenants.Tenant"
TENANT_DOMAIN_MODEL = "tenants.Domain"
AUTH_USER_MODEL = "users.User"
AUTHENTICATION_BACKENDS = ["tenant_users.permissions.backend.UserBackend"]

SHARED_APPS = [
    "django_tenants",
    "apps.tenants",
    "apps.users",
    "tenant_users.permissions",
    "tenant_users.tenants",
    "django.contrib.contenttypes",
    "django.contrib.auth",
    "django.contrib.admin",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
]

TENANT_APPS = [
    "django.contrib.contenttypes",
    "django.contrib.auth",
    "tenant_users.permissions",
    "apps.dashboard",
    "apps.workflows",
    "apps.documents",
]

INSTALLED_APPS = list(SHARED_APPS) + [
    app for app in TENANT_APPS if app not in SHARED_APPS
]

MIDDLEWARE = [
    "django_tenants.middleware.main.TenantMainMiddleware",  # MUST be position 0
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "apps.users.middleware.PasswordResetMiddleware",
    "tenant_users.tenants.middleware.TenantAccessMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"
PUBLIC_SCHEMA_URLCONF = "config.urls_public"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [BASE_DIR / "templates"],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

# --- Database ---
DATABASES = {
    "default": {
        "ENGINE": "django_tenants.postgresql_backend",  # NEVER django.db.backends.postgresql
        "NAME": os.environ.get("DB_NAME", "clinic_portal"),
        "USER": os.environ.get("DB_USER", "postgres"),
        "PASSWORD": os.environ.get("DB_PASSWORD", "postgres"),
        "HOST": os.environ.get("DB_HOST", "localhost"),
        "PORT": os.environ.get("DB_PORT", "5432"),
    }
}
DATABASE_ROUTERS = ["django_tenants.routers.TenantSyncRouter"]

# --- Cache (Redis, tenant-aware) ---
CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.redis.RedisCache",
        "LOCATION": os.environ.get("REDIS_URL", "redis://localhost:6379/0"),
        "KEY_FUNCTION": "django_tenants.cache.make_key",
        "REVERSE_KEY_FUNCTION": "django_tenants.cache.reverse_key",
    }
}

SESSION_ENGINE = "django.contrib.sessions.backends.cache"
SESSION_CACHE_ALIAS = "default"
SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SAMESITE = "Lax"
SESSION_COOKIE_SECURE = not DEBUG

# --- Security headers ---
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = "DENY"

# --- Static files ---
STATIC_URL = "static/"
STATICFILES_DIRS = [BASE_DIR / "static"]
```

### 4.6 Dockerfile
<!-- COMPLETENESS: Without this, implementer chooses their own base image, installs differently -->

```dockerfile
# Stage 1: Install dependencies
FROM python:3.12-slim AS builder
RUN pip install uv
WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev

# Stage 2: Runtime
FROM python:3.12-slim
RUN pip install uv
WORKDIR /app
COPY --from=builder /app/.venv /app/.venv
COPY . .
ENV PATH="/app/.venv/bin:$PATH"
EXPOSE 8000
CMD ["uv", "run", "python", "manage.py", "runserver", "0.0.0.0:8000"]
```

### 4.7 URL Routing Config
<!-- COMPLETENESS: Without this, developers don't know how NinjaAPI mounts into Django -->

```python
# config/urls.py (tenant-specific routes)
from django.urls import path
from apps.users.api import api  # NinjaAPI instance lives in users app

urlpatterns = [
    path("api/", api.urls),
    # Template views
    path("", views.dashboard_view, name="dashboard"),
    path("login/", views.login_view, name="login"),
    path("workflows/", views.workflows_view, name="workflows"),
    path("documents/", views.documents_view, name="documents"),
    path("staff/", views.staff_view, name="staff"),
]

# apps/users/api.py (NinjaAPI instance + router mounting)
from ninja import NinjaAPI
from ninja.security import SessionAuth

class TenantSessionAuth(SessionAuth):
    csrf = True  # CSRF per auth class, NOT NinjaAPI(csrf=True)

api = NinjaAPI(title="Clinic Portal", version="1.0")

# Mount routers
from apps.workflows.api import router as workflows_router
from apps.documents.api import router as documents_router
from apps.dashboard.api import router as dashboard_router

api.add_router("/auth/", auth_router)
api.add_router("/staff/", staff_router, auth=TenantSessionAuth())
api.add_router("/workflows/", workflows_router, auth=TenantSessionAuth())
api.add_router("/documents/", documents_router, auth=TenantSessionAuth())
api.add_router("/dashboard/", dashboard_router, auth=TenantSessionAuth())
api.add_router("/tenants/", tenants_router, auth=TenantSessionAuth())
```

### 4.8 Cache Key Patterns
<!-- COMPLETENESS: Without explicit keys, developers invent inconsistent key formats -->

| What | Key Pattern | TTL | Invalidated By |
|------|------------|-----|----------------|
| Dashboard stats | `dashboard:stats` | 60s | Any workflow/task/document CRUD |
| Workflow list | `workflows:list` | 30s | Workflow create/update/delete |
| S3 download URL | `s3:download:{doc_id}` | 840s (14min) | Document delete |
| LLM summary | `llm:summary:{doc_id}` | 86400s (24hr) | Re-summarize request |
| LLM tasks | `llm:tasks:{workflow_id}:{hash}` | 3600s (1hr) | Never (content-addressed) |

All keys are automatically tenant-prefixed by `django_tenants.cache.make_key`. Never construct raw Redis keys.

### 4.9 Async Lambda Flow
<!-- COMPLETENESS: Every async flow needs BOTH sides specified — trigger and result handling -->

```
Sequence: Document Summarization

Browser                    Django                      S3                    Lambda                 OpenAI
  |                          |                          |                      |                      |
  |-- POST /summarize ------>|                          |                      |                      |
  |                          |-- check cache ---------->|                      |                      |
  |                          |<-- cache miss ---------- |                      |                      |
  |                          |                          |                      |                      |
  |                          |-- invoke(sync) -------->>>>>                    |                      |
  |                          |                          |  Lambda reads doc    |                      |
  |                          |                          |<-- get_object -------|                      |
  |                          |                          |--- content -------->|                       |
  |                          |                          |                      |-- chat.completions ->|
  |                          |                          |                      |<-- summary --------- |
  |                          |<-- summary ------------ <<<<<                   |                      |
  |                          |                          |                      |                      |
  |                          |-- strip_tags(summary) -->|                      |                      |
  |                          |-- Document.summary = ... |                      |                      |
  |                          |-- cache.set(key, 24hr)   |                      |                      |
  |                          |-- AuditLog.create(...)   |                      |                      |
  |<-- 200 {summary} -------|                          |                      |                      |

Error handling:
- Lambda timeout (30s): return 502 + ErrorOut(code="external_error")
- Lambda error: return 502 + ErrorOut(code="external_error")
- No credentials: return 502 + ErrorOut(code="external_error", detail="AWS not configured")
- All errors logged at WARNING with exc_info
```

---

## 5. Implementation Plan
<!-- REQUIRED: Each step links to [REQ-xxx], names exact files, specifies commit granularity -->

| Step | Phase | What | Files | Reqs | Commit |
|------|-------|------|-------|------|--------|
| 1 | Infra | Docker Compose + pyproject.toml + uv setup | `docker-compose.yml`, `Dockerfile`, `pyproject.toml` | — | `feat: add Docker and dependency config` |
| 2 | Infra | Django scaffold + settings.py | `config/settings.py`, `config/urls.py`, `config/urls_public.py`, `manage.py` | — | `feat: scaffold Django project with tenant config` |
| 3 | Models | Tenant + Domain models + migrations | `apps/tenants/models.py`, `apps/tenants/apps.py` | REQ-001 | `feat: add tenant and domain models` |
| 4 | Models | User model + migrations | `apps/users/models.py`, `apps/users/apps.py` | REQ-002 | `feat: add user model with role and password reset flag` |
| 5 | Models | create_public_tenant command | `apps/tenants/management/commands/create_public_tenant.py` | REQ-001 | same commit as step 3 |
| 6 | Auth | Auth API (login, register, logout, me, reset-password) | `apps/users/api.py`, `config/urls.py` | REQ-002, REQ-003 | `feat: add auth endpoints` |
| 7 | Tenants | Tenant signup API | `apps/tenants/api.py`, `apps/tenants/services.py` | REQ-001 | `feat: add tenant signup endpoint` |
| 8 | Tenants | Staff management API | `apps/users/services.py` | REQ-009 | `feat: add staff invite and remove endpoints` |
| 9 | Workflows | AuditLog + Workflow + Task models | `apps/workflows/models.py`, `apps/workflows/schemas.py` | REQ-004, REQ-005 | `feat: add workflow, task, and audit models` |
| 10 | Workflows | Workflow CRUD + Task state machine API | `apps/workflows/api.py`, `apps/workflows/services.py` | REQ-004, REQ-005 | `feat: add workflow and task endpoints` |
| 11 | Documents | Document model + S3 presigned URLs | `apps/documents/models.py`, `apps/documents/api.py`, `apps/documents/services.py` | REQ-006 | `feat: add document management with S3` |
| 12 | AI | Lambda function + invocation endpoints | `lambdas/summarize/handler.py`, `apps/documents/api.py` | REQ-007 | `feat: add Lambda summarization` |
| 13 | Dashboard | Dashboard stats API | `apps/dashboard/api.py` | REQ-008 | `feat: add dashboard stats endpoint` |
| 14 | Frontend | Base template + all pages | `templates/*.html`, `static/styles.css`, `static/app.js` | All | `feat: add frontend templates` |
| 15 | Data | Seed demo data script | `apps/tenants/management/commands/seed_demo.py` | — | `feat: add demo seed command` |
| 16 [P] | Test | All test suites | `apps/*/tests.py` | All | `test: add unit and integration tests` |

**[P]** = parallelizable with previous step.
**Commit granularity:** One commit per step. Each commit must leave the project in a passing state (`uv run python manage.py test` green).

---

## 6. Testing Strategy
<!-- REQUIRED: Minimum 15 scenarios. Each links to [REQ-xxx] and specifies test base class -->

| # | Scenario | Input | Expected | Req | Base Class |
|---|----------|-------|----------|-----|------------|
| 1 | Create tenant via signup | `{name, subdomain, email, password}` | 201, schema created | REQ-001 | TestCase |
| 2 | Login valid credentials | `{email, password}` | 200, session cookie set | REQ-002 | TestCase |
| 3 | Login wrong password | `{email, wrong_password}` | 401, no session | REQ-002 | TestCase |
| 4 | Access tenant without membership | Auth user on wrong subdomain | 403 | REQ-003 | TenantTestCase |
| 5 | Create workflow (admin) | `{name, description}` | 201, AuditLog entry | REQ-004 | TenantTestCase |
| 6 | Create workflow (staff -- forbidden) | Same payload, staff role | 403 | REQ-003 | TenantTestCase |
| 7 | Valid task transition | created -> assigned | 200, status updated | REQ-004 | TenantTestCase |
| 8 | Invalid task transition | created -> completed | 400, rejected | REQ-004 | TenantTestCase |
| 9 | Terminal state transition | completed -> assigned | 400, rejected | REQ-004 | TenantTestCase |
| 10 | Generate presigned upload URL | `{filename, content_type}` | 200, URL with tenant prefix | REQ-006 | TenantTestCase |
| 11 | Register document after upload | `{s3_key, name, ...}` | 201, AuditLog entry | REQ-006 | TenantTestCase |
| 12 | Summarize document | POST on document | 200, summary saved | REQ-007 | TenantTestCase |
| 13 | Lambda failure graceful | Invalid Lambda ARN | 502, document unchanged | REQ-007 | TenantTestCase |
| 14 | Dashboard stats accuracy | Tenant with known data | 200, counts match | REQ-008 | TenantTestCase |
| 15 | Staff invite (admin) | `{email, name}` | 201, must_reset_password=True | REQ-009 | TenantTestCase |
| 16 | Staff invite (staff -- forbidden) | Same payload, staff role | 403 | REQ-003 | TenantTestCase |
| 17 | Cross-tenant data isolation | Query from wrong tenant | Empty result | REQ-001 | TenantTestCase |
| 18 | CSRF protection | POST without CSRF token | 403 | — | TenantTestCase |
| 19 | Empty input validation | `{name: ""}` | 422, validation error | — | TenantTestCase |
| 20 | Superadmin list tenants | GET /api/tenants/ as superadmin | 200, all tenants | REQ-010 | TestCase |

---

## 7. Observability

### 10 Required Logging Points

| # | Category | What to Log | Level |
|---|----------|------------|-------|
| 1 | API entry/exit | Method, path, tenant, response time | INFO |
| 2 | Errors | Exception type, message, traceback, tenant | ERROR |
| 3 | External calls | S3 presigned gen, Lambda invoke (ARN, duration) | INFO |
| 4 | State mutations | Task transitions (old -> new), CRUD ops | INFO |
| 5 | Security events | Login success/failure, logout, access denied | WARNING |
| 6 | Business milestones | Tenant created, workflow completed | INFO |
| 7 | Performance anomalies | Lambda > 10s, DB query > 500ms | WARNING |
| 8 | Config changes | Tenant provisioned, user role changed | INFO |
| 9 | Validation failures | Invalid transitions, Pydantic errors | WARNING |
| 10 | Resource limits | S3 size exceeded, Lambda payload too large | ERROR |

### Log Format
Structured JSON via `logging.config.dictConfig`. Each entry includes: `timestamp`, `level`, `logger`, `message`, `tenant_schema`, `user_id`.

### Never Log
Passwords, session tokens, AWS keys, OpenAI keys, full document content.

---

## 8-10. Future, Dependencies, Security

### Known Limitations
- Sync Lambda may be slow for large documents (accepted for MVP)
- Schema migrations scale linearly with tenant count (OK up to ~100)
- No email delivery -- temp passwords communicated out-of-band
- No rate limiting (add before production)

### Dependencies
Python 3.12, Django 5.x, django-ninja >= 1.0, django-tenants >= 3.6, django-tenant-users >= 1.0, boto3 >= 1.34, redis >= 5.0, python-dotenv >= 1.0. External: PostgreSQL 15+, Redis 7, AWS S3, AWS Lambda.

### Security
- Auth: Session-based via Redis, HttpOnly cookies, SameSite=Lax
- CSRF: `SessionAuth(csrf=True)` per auth class
- Tenant isolation: DB (search_path), S3 (key prefix), Redis (make_key), Auth (TenantAccessMiddleware)
- Input validation: Pydantic schemas, strip_tags() on LLM output
- Secrets: All from os.environ, .env in .gitignore
- Headers: X-Content-Type-Options: nosniff, X-Frame-Options: DENY
