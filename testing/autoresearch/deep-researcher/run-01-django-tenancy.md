# Run 01: Compare django-tenants vs django-multitenant vs row-level tenancy for SaaS

## Research Topic
"Compare django-tenants vs django-multitenant vs row-level tenancy for SaaS"

## Research Performed
- WebSearch: "django-tenants vs django-multitenant vs row-level tenancy SaaS 2025 2026"
- WebFetch: Medium article on 2026 Django multi-tenant architecture (403 - paywalled)
- WebFetch: Dev.to article on PostgreSQL RLS approach (successful)
- WebSearch: "PostgreSQL schema-per-tenant scale 1000 tenants best practices"

## Prompt Evaluation

### What the prompt guided well
1. **Alternative comparison** - Prompt requires "compare 2+ approaches with pros/cons" -- this naturally led to comparing three approaches (schema-per-tenant, row-level, separate DB)
2. **Gotchas** - Prompt asks for "common mistakes, performance traps" -- led to discovering the 500+ tenant catalog bloat issue with schema-per-tenant
3. **Multi-hop reasoning** - Entity Expansion pattern (Concept -> Applications -> Implications) worked well for tracing tenancy -> isolation -> performance at scale
4. **Self-reflection** - After first search, recognized need for deeper performance data, triggering additional searches
5. **Failure escalation** - When Medium 403'd, fell back to Dev.to source as prompt instructs

### What the prompt missed or was weak on
1. **No guidance on quantitative thresholds** - Found that schema-per-tenant degrades at 500+ tenants and breaks at 5000+, but prompt doesn't instruct agent to seek specific numbers/benchmarks
2. **No "decision matrix" template** - Prompt says "compare 2+ approaches" but doesn't push for a structured decision matrix (when to use X vs Y based on criteria)
3. **No instruction to check if the user's project already uses one approach** - Should cross-reference CLAUDE.md/SPEC.md to contextualize research
4. **Missing: "Check for migration paths"** - Real research should include how to migrate between approaches, not just compare them

### Research Quality Score: 8/10
- Sources found: 6 relevant, 1 paywalled
- Alternatives compared: 3 (schema-per-tenant, row-level RLS, separate DB) + Citus hybrid
- Actionable recommendation produced: Yes (RLS for >1000 tenants, schema-per-tenant for <500 with isolation needs)
- Key insight: PostgreSQL RLS provides "fail-closed" security vs schema-per-tenant's "fail-open" -- missed filter returns 0 rows, not all rows

## Handoff Output (as agent would produce)

```
## Research Completed
### Summary: Compared three Django multi-tenancy approaches. Schema-per-tenant (django-tenants) works well up to ~500 tenants but suffers catalog bloat and linear migration times beyond that. Row-level security (RLS) scales to thousands but requires PostgreSQL-only and loses per-tenant schema customization. Citus offers horizontal sharding for massive scale.
### Approach Recommended: For clinic-portal (which uses django-tenants already), stay with schema-per-tenant if expected tenant count is <500. If scaling beyond, plan migration to RLS or Citus.
### Alternatives Considered:
- django-tenants (schema-per-tenant): Best isolation, Django ecosystem support, but catalog bloat at scale
- django-multitenant (row-level): Cost-effective, single migration run, but application-level filtering is error-prone
- PostgreSQL RLS: Database-enforced isolation, fail-closed security, but requires PostgreSQL-only
- Citus: Horizontal sharding for millions of tenants, but operational complexity
### Sources:
- https://dev.to/dvoraj75/why-postgresql-row-level-security-is-the-right-approach-to-django-multitenancy-3e1m
- https://blog.thnkandgrow.com/a-deep-dive-into-schema-based-multi-tenancy-scaling-maintenance-and-best-practices/
- https://django-tenants.readthedocs.io/
- https://medium.com/simform-engineering/mastering-multi-tenant-architectures-in-django-three-powerful-approaches-178ff527c03f
### Delegation Hints: Next: @django-tenants-agent should review current tenant count expectations and validate schema-per-tenant is appropriate for projected scale.
### Risks/Unknowns: Exact performance degradation curve between 500-5000 tenants not precisely documented.
### Insights for Playbook:
INSIGHT: PostgreSQL RLS provides "fail-closed" security -- a missed filter returns 0 rows instead of all tenant data. Schema-per-tenant relies on search_path which can "fail-open."
INSIGHT: Migration time scales linearly with tenant count in schema-per-tenant -- each migrate_schemas runs N times.
INSIGHT: Citus extension can be added to existing PostgreSQL without changing application code significantly.
```

## Prompt Gaps Identified
| Gap | Severity | Fix |
|-----|----------|-----|
| No quantitative benchmark guidance | Medium | Add: "Seek specific numbers: latency, throughput, scale limits" |
| No decision matrix template | Medium | Add: "Produce a decision matrix with criteria columns" |
| No project context cross-reference | High | Add: "Check CLAUDE.md/SPEC.md to contextualize findings for the current project" |
| No migration path research | Medium | Add: "Research migration paths between alternatives, not just static comparison" |
