# Run 08: Extract Multi-Tenancy Requirements from Medusa (If Any)

## Source: packages/modules/store/*, packages/medusa/src/api/admin/stores/route.ts, packages/modules/rbac/*, package.json

## Extracted Requirements

### Multi-Tenancy Assessment

Medusa does NOT implement traditional multi-tenancy (schema-per-tenant or row-level). Instead, it uses a different isolation model:

### What Medusa Has Instead: Module-Based Isolation

- [REQ-ARCH001] Store as a first-class entity (not tenant)
  - Given the admin API, When stores are listed, Then they are queryable entities, not isolated tenants
  - Evidence: `GET /admin/stores` returns a list, not a single "current tenant"
- [REQ-ARCH002] Modular architecture with dependency injection
  - Given any API route, When data is needed, Then `remoteQuery` resolves it from the appropriate module via the DI container
  - Evidence: `req.scope.resolve(ContainerRegistrationKeys.REMOTE_QUERY)` — each request has its own DI scope
- [REQ-ARCH003] Sales channel as soft isolation
  - Given products and orders, When accessed, Then they are scoped to a sales channel (not a tenant)
  - Evidence: `sales_channel_id` on Order, Cart, and most commerce entities
- [REQ-ARCH004] RBAC module exists (role-based access control)
  - Given the system, When authorization is needed, Then an RBAC module provides role-based access
  - Evidence: `packages/modules/rbac/` exists with MikroORM config

### Absence of Traditional Multi-Tenancy

- [REQ-ABSENT001] No schema-per-tenant isolation
  - Evidence: All modules share one database schema; no `django_tenants`-style schema switching
- [REQ-ABSENT002] No tenant-scoped middleware
  - Evidence: No middleware that sets a "current tenant" per request
- [REQ-ABSENT003] No tenant-prefixed cache keys
  - Evidence: No tenant-aware cache key function in codebase

### How Multi-Tenancy Could Be Added (Inferred)

Based on the architecture, multi-tenancy in Medusa would likely use:
1. Sales channels as the isolation boundary (already exists)
2. Custom middleware to resolve tenant from request
3. Module-level filtering using the DI container scope
4. The Store entity as the tenant record

This is NOT implemented — it's inferred from the architecture's extension points.

## Evaluation

### Did the prompt guide good requirements extraction?
- **Discovery**: PARTIAL — the task asked to extract multi-tenancy requirements, but the codebase doesn't have traditional multi-tenancy. The agent correctly identified the absence and extracted what exists instead.
- **REQ-xxx tagging**: YES
- **Acceptance criteria**: PARTIAL — hard to write Given/When/Then for absent features
- **Completeness**: Good for the question asked
- **Duplicate check**: YES

### Prompt Gaps Identified
1. **No instruction for handling "requirement not found" scenarios** — when reverse-engineering a specific capability that doesn't exist in the codebase, the prompt doesn't say what to do. Should include: "if the requested capability is absent, document what EXISTS instead, what's ABSENT, and how the architecture could ACCOMMODATE it"
2. **No instruction to distinguish "implemented" vs "could be implemented" vs "incompatible"** — the prompt should instruct: "when a requirement is absent, classify it as: (a) implementable with existing architecture, (b) requires architecture change, or (c) fundamentally incompatible"
