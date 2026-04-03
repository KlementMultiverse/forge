# Run 10: medusa — API Contract Design, Versioning Strategy

## Source Files
- `/home/intruder/projects/medusa/packages/core/types/src/http/` (40+ HTTP type modules)
- `/home/intruder/projects/medusa/packages/cli/oas/` (OpenAPI spec generation)
- `/home/intruder/projects/medusa/.github/workflows/oas-test.yml`
- `/home/intruder/projects/medusa/.github/workflows/validate-http-types.yml`

## Findings

### API Contract Architecture: Type-First with OpenAPI Validation

**HTTP Types Package:**
The `@medusajs/types` package contains a comprehensive `http/` directory with 40+ modules:
- One module per domain: `cart`, `order`, `customer`, `product`, `payment`, `fulfillment`, etc.
- Each module exports TypeScript interfaces for:
  - Request bodies
  - Response shapes
  - Query parameters
  - Path parameters

**Contract Enforcement:**
1. Types defined in `@medusajs/types/http/` — single source of truth.
2. API routes reference these types — compile-time validation.
3. OpenAPI spec generated from types/routes via `packages/cli/oas/`.
4. CI workflow `oas-test.yml` validates OpenAPI spec.
5. CI workflow `validate-http-types.yml` validates HTTP type consistency.

### Versioning Strategy

**No URL-based versioning visible.** Instead, Medusa uses:
1. **Type evolution**: Add optional fields, deprecate old fields.
2. **Major version via package version**: Medusa v2 is a complete rewrite from v1.
3. **OAS (OpenAPI Spec) as contract**: Generated spec is the canonical API contract.
4. **CI validation**: Any PR that changes API types triggers OAS validation.

### Key Design Patterns

1. **Type-First Design:**
   - Types defined before implementation.
   - All modules share the same type system.
   - Changes to types are visible in PR diffs → reviewable.

2. **Centralized Contract:**
   - All HTTP types in one package (`@medusajs/types`).
   - No scattered type definitions across modules.
   - Single import path for consumers.

3. **Generated Documentation:**
   - OAS/Swagger spec generated from code.
   - `www/apps/api-reference/` — hosted API reference.
   - Documentation automation workflows ensure docs stay current.

4. **Contract Testing in CI:**
   - `oas-test.yml` — validates generated spec matches actual routes.
   - `validate-http-types.yml` — validates type definitions are consistent.
   - Breaking changes caught before merge.

### Comparison: Medusa Contracts vs Other Projects

| Aspect | Medusa | saleor | fastapi-template | clinic-portal |
|---|---|---|---|---|
| Contract definition | TypeScript interfaces | GraphQL SDL | Pydantic schemas | Pydantic schemas |
| Contract location | Centralized (types pkg) | Per-domain schema | Per-endpoint | Per-router |
| Contract testing | CI workflows | GraphQL Inspector | None | None |
| API documentation | OAS + generated docs | GraphQL Playground | None visible | Django Ninja auto-docs |
| Versioning | Package version | Schema evolution | URL (/api/v1/) | None |
| Breaking change detection | CI validation | CI validation | None | None |

### Architectural Lessons for System Architect Agent

1. **Type-first API design** prevents contract drift — types are defined before implementation.
2. **CI contract validation** catches breaking changes before they're merged.
3. **Centralized type packages** make API contracts discoverable and reviewable.
4. **Generated documentation** ensures docs never diverge from implementation.
5. **OAS/OpenAPI as lingua franca** enables client generation, testing, and documentation from a single spec.

## Comprehensive Gap Summary for System Architect Agent Prompt

After 10 runs across 4 projects, these are ALL the gaps found:

### Missing from Forge Cell Compliance
1. **Architecture classification**: Identify monolith/modular monolith/microservices/hybrid.
2. **Module dependency mapping**: Trace imports between modules, identify coupling hotspots.
3. **Extension point analysis**: Identify plugins, middleware, hooks, events, webhooks.
4. **Deployment topology**: Map architecture to deployment units.
5. **Layer dependency direction**: Verify inner layers don't depend on outer layers.
6. **Service layer evaluation**: Check for consistent service layer across all modules.
7. **Cross-module dependency detection**: Flag imports that violate module boundaries.

### Missing from Analysis Framework
8. **API paradigm evaluation**: REST vs GraphQL vs gRPC with trade-offs.
9. **Schema/contract design analysis**: How are API contracts defined, validated, and versioned?
10. **N+1 query prevention**: Check for dataloaders, select_related, or equivalent.
11. **Event-driven pattern evaluation**: Assess whether events would improve the architecture.
12. **Caching pattern consistency**: Verify caching is applied consistently across modules.
13. **Audit/logging consistency**: Verify audit trails are created in consistent locations.

### Missing from Security/Auth Analysis
14. **Auth mechanism evaluation**: JWT vs session vs OAuth with project-specific trade-offs.
15. **Per-tenant authorization**: Check if roles/permissions are scoped per-tenant or global.
16. **Dynamic configuration for multi-tenancy**: CSRF, ALLOWED_HOSTS, CORS for new tenants.

### Missing from Design Pattern Recognition
17. **Design pattern classification**: Name patterns used (Strategy, Observer, etc.).
18. **God Class detection**: Flag classes with too many responsibilities.
19. **Sync vs async evaluation**: Identify synchronous bottlenecks.
20. **External API inventory**: Catalog all external integrations with error handling evaluation.

### Missing from Scalability Analysis
21. **Database connection management**: Connection pooling, read replicas.
22. **Tenant context propagation**: Verify tenant context in all execution paths.
23. **API versioning strategy**: Check if versioning exists and recommend approach.
24. **Contract testing**: Recommend CI-based API contract validation.
