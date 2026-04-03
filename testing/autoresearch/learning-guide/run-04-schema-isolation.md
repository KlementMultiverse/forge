# Run 04: Explain django-tenants Schema Isolation vs Row-Level Tenancy

## Source Repo: clinic-portal
## Key Files: config/settings.py, apps/tenants/models.py (via SPEC.md), apps/workflows/models.py

## Teaching Output

### The Problem: Multiple Clinics, One Database

You're building a SaaS where 100 clinics sign up. Each clinic has workflows, documents, tasks. Clinic A must NEVER see Clinic B's data. How do you isolate them?

### Approach 1: Row-Level Tenancy (What You Probably Think Of First)

Every table has a `tenant_id` column:

```python
class Workflow(models.Model):
    tenant = models.ForeignKey(Tenant, on_delete=models.CASCADE)
    name = models.CharField(max_length=200)
```

Every query must filter by tenant:
```python
Workflow.objects.filter(tenant=current_tenant)
```

**Pros**: Simple, one schema, easy backups
**Cons**: One missing `.filter(tenant=...)` = data leak. Every query, every model, every admin page must remember.

### Approach 2: Schema-Per-Tenant (What django-tenants Does)

PostgreSQL has a feature called "schemas" — think of them as namespaces within a database. Schema `public` has shared tables. Schema `clinic_sunrise` has its own copy of every tenant table.

```
Database: clinic_portal
  Schema: public           → tenants, users (shared)
  Schema: clinic_sunrise   → workflows, tasks, documents (clinic A's data)
  Schema: clinic_downtown  → workflows, tasks, documents (clinic B's data)
```

When a request comes in for `clinic1.localhost`, django-tenants sets `SET search_path TO clinic_sunrise, public`. Now `Workflow.objects.all()` automatically queries `clinic_sunrise.workflows_workflow` — no filter needed.

### How clinic-portal Implements This

**settings.py** separates apps:
```python
SHARED_APPS = [
    "django_tenants",       # Must be first
    "apps.tenants",         # Tenant + Domain models
    "apps.users",           # Global user model
]

TENANT_APPS = [
    "apps.workflows",       # Each tenant gets its own workflows table
    "apps.documents",       # Each tenant gets its own documents table
]
```

**Middleware resolves tenant from subdomain** (position 0 in MIDDLEWARE):
```python
MIDDLEWARE = [
    "django_tenants.middleware.main.TenantMainMiddleware",  # MUST be first
    ...
]
```

When `clinic1.localhost` hits the server:
1. `TenantMainMiddleware` extracts `clinic1` from the hostname
2. Looks up Domain model to find the Tenant
3. Sets `connection.schema_name = "clinic1"`
4. All subsequent ORM queries hit the `clinic1` schema

**The Workflow model is completely unaware of tenancy**:
```python
class Workflow(models.Model):
    name = models.CharField(max_length=200)
    # NO tenant_id column!
```

This is the key difference. The model is clean. Isolation happens at the database level, not the application level.

### Comparison Table

| Aspect | Row-Level (filter-based) | Schema-Per-Tenant (django-tenants) |
|---|---|---|
| Data leak risk | High (one missed filter) | Low (wrong schema = table doesn't exist) |
| Model complexity | Every model has tenant FK | Models are clean, no tenant column |
| Migration complexity | Normal Django migrations | `migrate_schemas --shared` + `--tenant` |
| Query performance | Index on tenant_id needed | Each schema's tables are smaller |
| Backup granularity | Backup whole DB | Can pg_dump one schema |
| Scale limit | Millions of rows per table | ~1000 schemas before PG slows |
| When to use | Many small tenants (10K+) | Fewer tenants needing hard isolation (<1000) |

### The Gotcha: Shared vs Tenant Data

Users need to exist across tenants (one person, multiple clinics). That's why `apps.users` is in `SHARED_APPS` — the `users_user` table lives in the `public` schema. `django-tenant-users` handles the mapping of which users belong to which tenants.

## Evaluation

### Did the prompt guide good pedagogy?
- **Anchor to existing knowledge**: YES - Started with the intuitive approach (row-level) before introducing the new concept
- **Progressive disclosure**: YES - Problem → naive solution → better solution → implementation → tradeoffs
- **Practical examples**: YES - Real clinic-portal code
- **Multiple explanation approaches**: YES - Code, database diagram, comparison table
- **Verify understanding**: NO - No exercises

### Prompt Gaps Identified
1. **No instruction to present the "naive" approach first** — this is a powerful teaching technique (show what they'd naturally do, then show why the alternative is better). The prompt should include: "when explaining a design choice, first show the alternative the learner would likely reach for"
2. **No instruction to include a "gotchas" section** — transitions between frameworks always have surprises (shared vs tenant data, migration commands). The prompt's Chaos Resilience section covers confusion but doesn't mandate a gotchas section in output.
3. **Still no exercises mandate** — this is a recurring gap across all runs.
