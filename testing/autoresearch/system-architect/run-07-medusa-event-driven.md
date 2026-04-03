# Run 07: medusa — Event-Driven Architecture, Subscriber Patterns

## Source Files
- `/home/intruder/projects/medusa/packages/core/framework/src/subscribers/subscriber-loader.ts`
- `/home/intruder/projects/medusa/packages/core/framework/src/subscribers/types.ts`
- `/home/intruder/projects/medusa/packages/modules/event-bus-local/`
- `/home/intruder/projects/medusa/packages/modules/event-bus-redis/`
- `/home/intruder/projects/medusa/packages/core/types/src/event-bus/`

## Findings

### Event-Driven Architecture: Module Communication via Event Bus

**Event Bus Abstraction:**
- `IEventBusModuleService` — interface in `@medusajs/types` defining the event bus contract.
- Two implementations:
  - `event-bus-local` — in-memory, for development (single process).
  - `event-bus-redis` — Redis-backed, for production (distributed).
- Swappable via configuration — no code changes needed.

**Subscriber Pattern:**

Subscribers are loaded dynamically from the filesystem:

1. `SubscriberLoader` extends `ResourceLoader` — file-based auto-discovery.
2. Each subscriber file exports a `config` (SubscriberConfig) and a `handler` function.
3. `SubscriberConfig` specifies which events to listen to.
4. Handler receives `SubscriberArgs<T>` with typed event data.

**Loading Process:**
```
Application boot
  → SubscriberLoader scans sourceDir for subscriber files
  → Each file is validated (must export config + handler)
  → Subscribers registered with EventBusModuleService
  → Events emitted by modules → dispatched to matching subscribers
```

**Key Design Decisions:**

1. **Convention-based discovery**: Subscribers placed in specific directories are auto-loaded.
2. **File skip support**: `isFileSkipped(fileExports)` allows conditional subscriber loading.
3. **Dev server integration**: `registerDevServerResource` — subscribers can hot-reload in development.
4. **Typed events**: Event types defined in `@medusajs/types` — compile-time safety.
5. **kebabCase normalization**: Event names normalized for consistency.

### Event-Driven Patterns Analysis

| Pattern | Medusa Implementation | Strength |
|---|---|---|
| Pub/Sub | Event Bus (local or Redis) | Decouples modules |
| Event discovery | Filesystem convention | Zero-config subscriber registration |
| Event typing | TypeScript interfaces | Compile-time safety |
| Distributed events | Redis-backed event bus | Multi-process support |
| Event replay | Not visible | Would need event store |
| Dead letter queue | Not visible | Error handling unclear |

### Comparison: Medusa Events vs clinic-portal (No Events)

clinic-portal has NO event-driven communication:
- Workflow state changes are synchronous — `task.transition_to()` directly creates AuditLog.
- Document summarization is synchronous — `invoke_summarize_lambda()` blocks the request.
- No pub/sub pattern — all inter-module communication is via direct function calls.

If clinic-portal needed events:
- AuditLog creation could be event-driven (publish "task.status_changed", subscriber creates log).
- LLM summarization could be async (publish "document.uploaded", subscriber triggers summarization).
- Cache invalidation could be event-driven (publish "workflow.updated", subscriber invalidates cache).

### Gaps Identified for Agent Prompt
1. **Event-driven architecture evaluation**: Agent should assess whether the project would benefit from event-driven patterns and recommend if appropriate.
2. **Sync vs async communication analysis**: Agent should identify synchronous bottlenecks that could benefit from async event-based communication.
3. **Event bus implementation options**: Agent should know common event bus patterns (in-memory, Redis, Kafka, database-backed) with trade-offs.
4. **Subscriber discovery patterns**: Agent should evaluate auto-discovery vs explicit registration.
5. **Error handling in event systems**: Agent should check for dead letter queues, retry policies, and idempotency.
6. **Event typing and contracts**: Agent should evaluate whether events have typed contracts or are loosely typed.
