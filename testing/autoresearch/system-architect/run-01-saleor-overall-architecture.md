# Run 01: saleor — Overall Architecture (Monolith, Microservices, Modular Monolith?)

## Source Files
- `/home/intruder/projects/saleor/saleor/` (package structure)
- `/home/intruder/projects/saleor/saleor/settings.py`
- `/home/intruder/projects/saleor/Dockerfile`
- `/home/intruder/projects/saleor/pyproject.toml`

## Findings

### Architecture Classification: Modular Monolith with Plugin Extension Points

Saleor is a **modular monolith** deployed as a single process (uvicorn ASGI), but with clear internal module boundaries:

**Core Modules (Django apps):**
- `account` — User management, authentication, groups
- `order` — Order processing, fulfillment
- `checkout` — Cart and checkout flows
- `product` — Catalog management
- `payment` — Payment processing
- `discount` — Promotions, vouchers
- `shipping` — Shipping methods
- `channel` — Multi-channel commerce
- `plugins` — Extension system
- `graphql` — API layer (GraphQL)
- `core` — Shared utilities, models, telemetry

**Extension Points:**
- Plugin system via `plugins/manager.py` — dynamic loading of plugin classes.
- Webhook-based events for external integrations.
- App system for third-party extensions.

**Why Modular Monolith (not microservices):**
1. Single database (PostgreSQL) — no service-per-database.
2. Single deployable unit (one Docker image, one CMD).
3. In-process function calls between modules (not HTTP/gRPC).
4. Celery for background jobs — separate worker process but same codebase.
5. Django ORM for all data access — no separate data stores per module.

**Why not a simple monolith:**
1. Clear module boundaries (each Django app is self-contained).
2. Plugin system allows extension without modifying core.
3. GraphQL schema acts as a formal API contract.
4. Channel model provides logical multi-tenancy.

### Architectural Decisions Visible in Code

| Decision | Rationale (Inferred) | Trade-off |
|---|---|---|
| GraphQL over REST | Complex queries for commerce (product + variant + pricing + stock) | Steeper learning curve, complex caching |
| Django ORM (not raw SQL) | Developer productivity, migration management | Performance ceiling for complex queries |
| Plugin system (in-process) | Low-latency extensions | Plugins run in same process (crash risk) |
| Celery for background jobs | Proven Python task queue | Adds Redis/broker dependency |
| Multi-channel (not multi-tenant) | Different pricing/inventory per channel | Not schema-level isolation |
| ASGI via uvicorn | Async support for I/O-bound operations | More complex than WSGI |

## What the System Architect Agent Prompt Covers vs Misses

| Concern | Covered? | Notes |
|---|---|---|
| Classify architecture style | NO | Agent should identify monolith/modular monolith/microservices |
| Module boundary analysis | NO | Agent should map module dependencies |
| Extension point identification | NO | Agent should identify how the system can be extended |
| Data access patterns | NO | Agent should analyze ORM usage, N+1 queries, etc. |
| Deployment topology | NO | Agent should describe single-process vs multi-process vs multi-service |
| Cross-cutting concerns | NO | Agent should identify logging, auth, caching patterns |

## Gaps Identified for Agent Prompt
1. **Architecture classification**: Agent should explicitly classify projects as monolith, modular monolith, microservices, or hybrid.
2. **Module dependency mapping**: Agent should trace import dependencies between modules to identify coupling.
3. **Extension point analysis**: Agent should identify plugin systems, middleware, hooks, and events.
4. **Deployment topology**: Agent should describe how the architecture maps to deployment units.
