# Run 05: clinic-portal -- Write multi-tenancy architecture decision record (ADR)

## Task
Write an Architecture Decision Record (ADR) for the multi-tenancy approach in clinic-portal.

## Code Read
- `/home/intruder/projects/clinic-portal/apps/tenants/models.py` -- Tenant(TenantBase), Domain(DomainMixin)
- `/home/intruder/projects/clinic-portal/config/settings.py` -- SHARED_APPS, TENANT_APPS, django_tenants config
- `/home/intruder/projects/clinic-portal/SPEC.md` -- schema-per-tenant requirement
- `/home/intruder/projects/clinic-portal/CLAUDE.md` -- Architecture rules including TenantMainMiddleware position 0

## Prompt Evaluation

### What the prompt guided well
1. **CONTEXT step** -- Reading CLAUDE.md + SPEC.md correctly captures the decision context (schema-per-tenant mandate)
2. **RESEARCH step** -- Reading actual model code confirms the implementation (TenantBase, DomainMixin)
3. **Technical Specifications** output type -- "Clear system documentation with architecture details" matches ADR
4. **CROSS-CHECK step** -- Can map to SPEC.md requirements for tenant isolation

### What the prompt missed or was weak on
1. **No ADR template instruction** -- ADRs have a specific format (Title, Status, Context, Decision, Consequences). Prompt says "Technical Specifications" but doesn't know ADR format
2. **No "alternatives considered" requirement for ADRs** -- ADRs MUST document why alternatives were rejected. Prompt doesn't enforce this for architecture docs specifically
3. **No "consequences" section instruction** -- ADRs must document trade-offs and implications. Prompt covers "Risks/Blockers" in handoff but not in the document itself
4. **No "reversibility" assessment** -- Can this decision be changed later? At what cost? Critical for ADRs but not in prompt
5. **No instruction to reference external research** -- ADR should cite research on schema-per-tenant scaling issues. Prompt doesn't connect documentation to research agent output
6. **No stakeholder context instruction** -- Who made this decision and why? ADRs need this but prompt doesn't push for it

### Sample ADR Structure (what agent should produce):

```
# ADR-001: PostgreSQL Schema-Per-Tenant for Multi-Tenancy

## Status: Accepted

## Context
clinic-portal is a multi-tenant SaaS where each medical clinic gets an isolated workspace.
Data isolation is critical -- clinics must never see each other's data.

## Decision
Use django-tenants with PostgreSQL schema-per-tenant isolation.

## Alternatives Considered
1. Row-level security (RLS) -- rejected: weaker isolation guarantees for medical data
2. Separate databases per tenant -- rejected: operational complexity at scale
3. Shared schema with tenant_id column -- rejected: risk of data leakage via missed filters

## Consequences
- GOOD: Strong data isolation at database level
- GOOD: Django ORM works transparently per-tenant
- BAD: Migration time scales linearly with tenant count
- BAD: Catalog bloat above 500 tenants
- RISK: May need to migrate to Citus if exceeding 1000 tenants
```

### Documentation Quality Score: 6/10
- Agent would produce decent ADR content from code/spec reading
- Missing: proper ADR template, alternatives analysis depth, reversibility assessment
- The CROSS-CHECK step helps ensure requirements coverage

## Prompt Gaps Identified
| Gap | Severity | Fix |
|-----|----------|-----|
| No ADR template instruction | High | Add: "For ADRs, use standard format: Title, Status, Context, Decision, Alternatives Considered, Consequences" |
| No alternatives analysis requirement for arch docs | High | Add: "Architecture docs MUST document alternatives considered and why each was rejected" |
| No consequences/trade-offs section | Medium | Add: "Document positive consequences, negative consequences, and risks explicitly" |
| No reversibility assessment | Medium | Add: "Assess decision reversibility: can this be changed? At what cost?" |
| No cross-reference to research | Medium | Add: "Reference @deep-researcher output when documenting architecture decisions" |
