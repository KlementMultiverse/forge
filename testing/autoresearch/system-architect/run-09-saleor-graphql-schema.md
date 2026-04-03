# Run 09: saleor — GraphQL Schema Design Decisions

## Source Files
- `/home/intruder/projects/saleor/saleor/graphql/schema.py`
- `/home/intruder/projects/saleor/saleor/graphql/core/` (types, validators, filters, mutations)
- `/home/intruder/projects/saleor/saleor/graphql/` (per-domain schema modules)

## Findings

### GraphQL Schema Architecture: Domain-Organized with Unified Root

**Schema Composition Pattern:**
```python
# schema.py aggregates all domain schemas:
from .account.schema import AccountMutations, AccountQueries
from .app.schema import AppMutations, AppQueries
from .attribute.schema import AttributeMutations, AttributeQueries
from .channel.schema import ChannelMutations, ChannelQueries
from .checkout.schema import CheckoutMutations, CheckoutQueries
from .order.schema import OrderMutations, OrderQueries
from .product.schema import ProductMutations, ProductQueries
from .payment.schema import PaymentMutations, PaymentQueries
# ... 15+ more domain schemas
```

Each domain module has its own:
- `schema.py` — Queries + Mutations classes
- `types/` — GraphQL type definitions
- `mutations.py` — Mutation resolvers
- `filters.py` — Filterable fields
- `enums.py` — GraphQL enums

**Root Schema Pattern:**
- Single `Query` class inheriting from all domain Query classes.
- Single `Mutation` class inheriting from all domain Mutation classes.
- Built as a `GraphQLSchema` via `build_federated_schema()` — supports Apollo Federation.

### Schema Design Decisions

| Decision | Rationale | Trade-off |
|---|---|---|
| GraphQL over REST | Complex nested queries (product + variants + pricing + stock) | Caching harder, security surface larger |
| Graphene (v2) over Strawberry | Legacy choice, deep integration with Django ORM | Older library, no async resolvers |
| Federation support | Enables splitting schema across services | Complexity of federated deployment |
| Per-domain schema modules | Clean separation, each domain owns its types | Many files, cross-domain types require imports |
| Channel-scoped queries | Multi-channel commerce needs channel context | Every query needs channel resolution |
| Permission-based field resolution | Fine-grained access control | Performance overhead per field |

### Schema Organization

```
graphql/
├── schema.py          ← Root: composes all domain schemas
├── core/              ← Shared types, validators, base classes
│   ├── types/         ← Base GraphQL types (Money, DateTime, etc.)
│   ├── mutations.py   ← Base mutation classes with permissions
│   ├── validators/    ← Input validation
│   ├── filters/       ← Base filter classes
│   ├── federation/    ← Apollo Federation support
│   └── context.py     ← SaleorContext (request + plugins + dataloaders)
├── account/schema.py  ← User, Address, Group queries/mutations
├── product/schema.py  ← Product, Category, Collection
├── order/schema.py    ← Order, Fulfillment
├── checkout/schema.py ← Checkout flow
├── payment/schema.py  ← Payment, Transaction
└── ... (15+ more)
```

### Key GraphQL Patterns

1. **SaleorContext**: Custom context object passed to all resolvers containing:
   - Request object
   - PluginsManager instance
   - Dataloaders (for N+1 prevention)
   - App/user authentication
   - Channel context

2. **Dataloader Pattern**: Prevents N+1 queries. Dataloaders are per-request, batching multiple ID lookups into single SQL queries.

3. **Field-level Permissions**: Base mutation classes check permissions before execution. Different operations require different permissions.

4. **Caching**: `GraphQLCachedBackend` for query parsing cache. Schema introspection cached.

5. **Field Usage Metrics**: `record_field_usage()` — telemetry on which fields are actually used (helps deprecation decisions).

### Comparison: saleor GraphQL vs clinic-portal REST (Django Ninja)

| Aspect | saleor (GraphQL) | clinic-portal (Django Ninja REST) |
|---|---|---|
| Schema definition | Python classes → GraphQL SDL | Pydantic schemas → OpenAPI |
| Query flexibility | Client chooses fields | Server defines response shape |
| N+1 prevention | Dataloaders | Manual select_related/prefetch |
| API versioning | Schema evolution (deprecation) | URL versioning (not implemented) |
| API documentation | GraphQL Playground/introspection | OpenAPI (auto-generated) |
| Caching | Complex (per-field, per-resolver) | Simple (per-endpoint, TTL-based) |
| Error handling | GraphQL errors array | HTTP status codes |

## Gaps Identified for Agent Prompt
1. **API paradigm evaluation**: Agent should assess whether GraphQL, REST, or gRPC is appropriate for the project's requirements and recommend with trade-offs.
2. **Schema design patterns**: Agent should evaluate how API schemas are organized (per-domain, per-operation, per-resource).
3. **N+1 query prevention**: Agent should check for dataloader patterns, select_related, or equivalent optimizations.
4. **API evolution strategy**: Agent should evaluate how the API handles versioning and deprecation.
5. **Cross-cutting API concerns**: Agent should check for consistent error handling, pagination, filtering, and permission patterns across all endpoints.
6. **API documentation**: Agent should verify auto-generated or maintained API documentation exists.
