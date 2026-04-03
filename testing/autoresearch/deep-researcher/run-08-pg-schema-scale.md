# Run 08: Best practices for PostgreSQL schema-per-tenant at scale (1000+ tenants)

## Research Topic
"Best practices for PostgreSQL schema-per-tenant at scale (1000+ tenants)"

## Research Performed
- WebSearch: "PostgreSQL schema-per-tenant scale 1000 tenants best practices performance 2025 2026"

## Prompt Evaluation

### What the prompt guided well
1. **Temporal Progression** -- Current state (works at 500) -> Recent changes (breaks at 5000) -> Historical context (Citus alternative emerged)
2. **Gotchas** -- Found critical scaling issues: catalog bloat, linear migration times, connection pool exhaustion
3. **Causal Chains** -- Problem (slow queries at scale) -> Contributing factors (catalog bloat, memory pressure) -> Solutions (PgBouncer, Citus, tenant sharding)
4. **Replanning Triggers** -- Recognized need for Citus research after initial search revealed schema limits

### What the prompt missed or was weak on
1. **No operational runbook instruction** -- "Best practices" should produce actionable ops guidance (monitoring queries, migration scripts, connection pool config)
2. **No "escape hatch" planning** -- When schema-per-tenant fails, what's the migration path? Prompt doesn't push for exit strategy
3. **No specific PostgreSQL tuning parameters** -- Found "careful resource tuning needed" but no specific pg settings (shared_buffers, effective_cache_size)
4. **No monitoring/alerting guidance** -- What metrics to watch? What thresholds trigger action?
5. **No real-world case study instruction** -- Prompt doesn't push agent to find companies that have done this at scale

### Research Quality Score: 7/10
- Sources found: 5 relevant
- Alternatives compared: 3 (schema-per-tenant tuning, Citus sharding, migration to RLS)
- Actionable recommendation: Yes but lacks specificity on tuning parameters
- Key insight: Enterprise SaaS saw degradation at 5000+ clients with schema-per-tenant

## Handoff Output (as agent would produce)

```
## Research Completed
### Summary: PostgreSQL schema-per-tenant degrades at 500+ tenants (catalog bloat, query planning overhead) and becomes problematic at 5000+ (memory pressure, linear migration times). Key mitigations: PgBouncer for connection pooling, noisy neighbor monitoring, Citus for horizontal sharding at massive scale.
### Approach Recommended: For <500 tenants, optimize with PgBouncer and monitoring. For 500-5000, evaluate Citus extension. For 5000+, migrate to shared-schema with RLS or Citus distributed.
### Alternatives Considered:
- Optimize schema-per-tenant: PgBouncer, monitoring, resource tuning. Works to ~500 tenants.
- Citus extension: Horizontal sharding, distributed queries. Scales to millions. Added operational complexity.
- Migrate to RLS: Single schema, database-enforced isolation. Eliminates catalog bloat. Major migration effort.
- Dedicated instances for large tenants: Move "noisy neighbors" to their own DB. Hybrid approach.
### Sources:
- https://blog.thnkandgrow.com/a-deep-dive-into-schema-based-multi-tenancy-scaling-maintenance-and-best-practices/
- https://www.crunchydata.com/blog/designing-your-postgres-database-for-multi-tenancy
- https://docs.citusdata.com/en/v7.3/articles/designing_saas.html
- https://medium.com/@parvemayur/scaling-postgresql-for-multi-tenant-saas-a-practical-and-beginner-friendly-guide-using-citus-ec89fbf3c177
### Delegation Hints: Next: @devops-architect should set up PgBouncer connection pooling and tenant monitoring dashboards.
### Risks/Unknowns: Exact degradation curve varies by workload. Citus licensing may affect cost. Migration from schema-per-tenant to shared requires application code changes.
### Insights for Playbook:
INSIGHT: Schema-per-tenant catalog bloat becomes measurable at 500+ tenants and problematic at 5000+.
INSIGHT: PgBouncer is non-negotiable for schema-per-tenant at any scale -- connection overhead compounds with tenant count.
INSIGHT: Citus extension can be added to existing PostgreSQL incrementally -- doesn't require full migration.
```

## Prompt Gaps Identified
| Gap | Severity | Fix |
|-----|----------|-----|
| No operational runbook instruction | High | Add: "For infrastructure topics, produce actionable operational guidance (config, monitoring, scripts)" |
| No escape hatch planning | High | Add: "Always research the migration/exit strategy for the recommended approach" |
| No specific configuration parameters | Medium | Add: "For database/infrastructure topics, seek specific configuration values and tuning parameters" |
| No monitoring/alerting guidance | Medium | Add: "Include monitoring strategy: what metrics, what thresholds, what alerts" |
| No case study instruction | Low | Add: "Find real-world case studies of companies operating at the target scale" |
