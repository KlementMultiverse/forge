# Run 03: medusa — Modular Commerce Architecture, Package Boundaries

## Source Files
- `/home/intruder/projects/medusa/packages/` (directory structure)
- `/home/intruder/projects/medusa/packages/core/` (framework, types, utils, workflows-sdk, modules-sdk, orchestration)
- `/home/intruder/projects/medusa/packages/modules/` (20+ module packages)
- `/home/intruder/projects/medusa/turbo.json`
- `/home/intruder/projects/medusa/package.json`

## Findings

### Architecture Classification: Modular Framework with Dependency Inversion

Medusa v2 is a **modular commerce framework** — not a monolith, not microservices, but a framework that lets you compose modules into an application.

**Package Taxonomy:**

1. **Core packages (`packages/core/`):**
   - `framework` — Application bootstrap, container, config, subscriber loading, HTTP server
   - `types` — TypeScript interfaces for ALL modules (dependency inversion — contracts without implementations)
   - `utils` — Shared utility functions
   - `modules-sdk` — Module loading and registration
   - `workflows-sdk` — Workflow orchestration primitives
   - `orchestration` — Transaction management, saga patterns
   - `core-flows` — Pre-built business logic workflows

2. **Module packages (`packages/modules/`):**
   - `auth`, `cart`, `customer`, `order`, `payment`, `fulfillment`, `inventory`, `pricing`, `notification`, `file`, etc.
   - Each module is an independent npm package with its own `package.json`.
   - Modules implement interfaces from `@medusajs/types`.
   - Modules are loaded dynamically at runtime via the module SDK.

3. **Provider packages (`packages/modules/providers/`):**
   - Implementation-specific providers (Stripe, S3, SendGrid, etc.).
   - Pluggable via configuration — no code changes to switch providers.

4. **CLI packages (`packages/cli/`):**
   - `medusa-cli` — Project scaffolding, development server.
   - `oas` — OpenAPI spec generation.

5. **Admin packages (`packages/admin/`):**
   - React-based admin dashboard.
   - Independent from server — communicates via HTTP API.

### Architectural Principles

1. **Dependency Inversion via Types Package:**
   - `@medusajs/types` defines interfaces for every module.
   - Modules depend on types, not on each other.
   - Example: `IEventBusModuleService`, `MedusaContainer`, `Subscriber` are all type imports.
   - This enables swapping implementations without changing consumers.

2. **Module Isolation:**
   - Each module is a separate npm package with explicit dependencies.
   - No cross-module imports of implementation code.
   - Communication between modules goes through the framework container.

3. **Workflow-Based Business Logic:**
   - `workflows-sdk` provides a DSL for composable business operations.
   - `core-flows` implements standard commerce workflows using the SDK.
   - Workflows are transactional with compensation (saga pattern via `orchestration`).

4. **Event-Driven Communication:**
   - `event-bus-local` for development (in-memory).
   - `event-bus-redis` for production (distributed).
   - Subscribers loaded dynamically from filesystem (`subscriber-loader.ts`).
   - Events are typed (from `@medusajs/types`).

5. **Link Modules:**
   - `link-modules` package defines cross-module relationships.
   - Instead of direct foreign keys between modules, relationships are declared in links.
   - Enables modules to remain independent while still being composable.

### Comparison with clinic-portal Architecture

| Pattern | Medusa | clinic-portal |
|---|---|---|
| Module isolation | STRONG (npm packages) | WEAK (Django apps share imports) |
| Dependency inversion | YES (types package) | NO (direct model imports) |
| Event-driven | YES (event bus) | NO (synchronous) |
| Saga/compensation | YES (orchestration) | NO |
| Workflow SDK | YES | NO |
| Dynamic module loading | YES | NO (INSTALLED_APPS is static) |
| Cross-module relationships | Explicit (link-modules) | Implicit (ForeignKey) |

## Gaps Identified for Agent Prompt
1. **Module boundary analysis**: Agent should evaluate how well modules are isolated (shared imports, direct dependencies vs interfaces).
2. **Dependency inversion evaluation**: Agent should check if interfaces/contracts exist between modules or if they depend directly on implementations.
3. **Event-driven patterns**: Agent should identify whether the system uses events for inter-module communication and evaluate the pattern.
4. **Workflow/saga patterns**: Agent should identify transactional workflows and evaluate compensation strategies.
5. **Cross-module relationship modeling**: Agent should analyze how relationships between modules are declared (ForeignKey vs link tables vs event-based).
6. **Dynamic vs static module loading**: Agent should evaluate module registration approach.
