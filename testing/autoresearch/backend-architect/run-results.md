# Autoresearch: Backend Architect Agent — 10 Test Runs

## Research Phase: Web Search Findings (2025 Backend Architecture Patterns)

Key patterns the agent prompt should cover but currently misses:
1. **DataLoader / N+1 detection** — GraphQL-heavy codebases universally use dataloaders; the prompt has zero mention
2. **SELECT FOR UPDATE / pessimistic locking** — critical for financial/order systems
3. **Cascade delete risk analysis** — on_delete=CASCADE on user FKs can silently destroy data
4. **Plugin/extension interface bloat** — manager patterns accumulate methods; prompt has no pattern for evaluating interface surface
5. **Event-driven architecture patterns** — eventual consistency, compensating transactions, saga/workflow patterns
6. **API versioning and error response consistency** — prompt mentions "error handling" generically but has no concrete checklist
7. **Soft delete vs hard delete** — Medusa uses `deleted_at IS NULL` everywhere; prompt has no guidance

Sources:
- [GeeksforGeeks - Design Patterns for Modern Backend Development](https://www.geeksforgeeks.org/system-design/design-patterns-for-modern-backend-development/)
- [Azure Architecture Center - Web API Design Best Practices](https://learn.microsoft.com/en-us/azure/architecture/best-practices/api-design)
- [MyAppAPI - API Design Best Practices in 2025](https://myappapi.com/blog/api-design-best-practices-2025/)

---

## Run 1: saleor — GraphQL Schema Design, Resolver Patterns, DataLoader Usage

**Repo:** `/home/intruder/projects/forge-test-repos/saleor`
**Focus:** GraphQL schema design, resolver patterns, dataloader usage

### Real Issues Found
1. **DataLoader explosion** — `saleor/graphql/product/dataloaders/__init__.py` exports 35+ dataloader classes for product domain alone. This is correct (solves N+1) but the current agent prompt has ZERO guidance on evaluating dataloader coverage or identifying missing dataloaders.
2. **Resolver complexity** — `saleor/graphql/product/types/products.py` is 100+ imports at the top alone. The 300-line file limit in the prompt is good but doesn't address how to evaluate GraphQL type files that legitimately need many resolvers.
3. **Channel context threading** — Resolvers consistently use `get_database_connection_name(info.context)` for read replica routing. The prompt mentions "connection pooling" but not read replica awareness.

### Prompt Gaps
- **GAP-01**: No mention of DataLoader pattern or N+1 query detection
- **GAP-02**: No guidance on evaluating GraphQL schema structure (type nesting, connection patterns, relay compliance)
- **GAP-03**: No read replica / write-read split awareness

### Score: PROMPT 2/5 for this scenario

---

## Run 2: fastapi-template — SQLAlchemy Model Design, Relationships, Migration Strategy

**Repo:** `/home/intruder/projects/forge-test-repos/fastapi-template`
**Focus:** SQLModel design, relationship patterns, migration strategy

### Real Issues Found
1. **Model-schema mixing** — `models.py` has DB models (User, Item) and API schemas (UserCreate, UserPublic) in the same file. Good for small projects; bad at scale. The prompt says "split files >300 lines" but has no guidance on model vs schema separation.
2. **Cascade delete** — `User.items` has `cascade_delete=True` AND `Item.owner_id` has `ondelete="CASCADE"`. Double-cascade is redundant — ORM-level AND DB-level. Not wrong, but the agent should detect and note this.
3. **No updated_at on Item** — `User` has `created_at` but `Item` only has `created_at`. No `updated_at` field, no soft delete. For audit purposes, this is a gap.
4. **Alembic migrations exist** — `1a31ce608336_add_cascade_delete_relationships.py` shows cascade was added after initial design. The prompt has no guidance on reviewing migration history for schema evolution risks.

### Prompt Gaps
- **GAP-04**: No guidance on model vs API schema separation patterns
- **GAP-05**: No checklist for timestamp fields (created_at, updated_at, deleted_at)
- **GAP-06**: No migration history review guidance

### Score: PROMPT 2/5 for this scenario

---

## Run 3: medusa — Entity Design, Repository Pattern, ORM Patterns

**Repo:** `/home/intruder/projects/forge-test-repos/medusa`
**Focus:** MikroORM/DLL patterns, entity design, repository pattern

### Real Issues Found
1. **Declarative model DSL** — Medusa uses `model.define()` DSL (not raw MikroORM decorators). The prompt is Python-centric — no guidance for TypeScript ORM patterns.
2. **Cascade configuration** — `order.ts` cascades delete on `summary`, `items`, `shipping_methods`, `transactions`, `credit_lines` but NOT `returns`. This is intentional (returns should survive order deletion) but the agent should flag cascade asymmetry for review.
3. **Partial indexes everywhere** — Every index has `where: "deleted_at IS NULL"`. This is a soft-delete-aware pattern. The prompt has no concept of partial/conditional indexes.
4. **Nullable FKs as text** — `order.ts` uses `model.text().nullable()` for `region_id`, `customer_id`, `sales_channel_id` — these are cross-module references stored as plain text, not true FKs. This is Medusa's link-module pattern. The prompt has no guidance on evaluating cross-module reference strategies.

### Prompt Gaps
- **GAP-07**: Prompt is Python-only; no TypeScript/Node ORM patterns
- **GAP-08**: No soft delete / partial index review guidance
- **GAP-09**: No cross-module reference pattern evaluation (link tables vs FK vs text refs)

### Score: PROMPT 1/5 for this scenario

---

## Run 4: clinic-portal — on_delete CASCADE Risks, FK Constraints

**Repo:** `/home/intruder/projects/clinic-portal`
**Focus:** CASCADE risks, FK constraints

### Real Issues Found
1. **CASCADE on created_by** — `Workflow.created_by` and `Task.created_by` use `on_delete=models.CASCADE`. If an admin user is deleted, ALL their workflows AND tasks are silently destroyed. This should be `SET_NULL` or `PROTECT`.
2. **CASCADE on uploaded_by** — `Document.uploaded_by` uses `on_delete=models.CASCADE`. Deleting a user destroys their uploaded documents AND orphans S3 objects (no cleanup hook).
3. **CASCADE on ChatThread/ChatMessage** — `search/models.py` cascades on user deletion. Audit trail lost.
4. **No transaction.atomic anywhere** — grep found ZERO uses of `transaction.atomic` or `select_for_update` in the entire `apps/` directory. The `Task.transition_to()` method does `self.save()` then `AuditLog.objects.create()` — if the audit log insert fails, the status change is committed but unaudited.

### Prompt Gaps
- **GAP-10**: No CASCADE risk analysis checklist (user deletion → data loss)
- **GAP-11**: No transaction atomicity enforcement — prompt says "ACID compliance" generically but has no specific "wrap state changes + audit log in transaction.atomic" rule
- **GAP-12**: No orphaned resource detection (S3 objects surviving DB cascade)

### Score: PROMPT 2/5 for this scenario

---

## Run 5: saleor — Plugin Architecture, Interface Bloat, Manager Pattern

**Repo:** `/home/intruder/projects/forge-test-repos/saleor`
**Focus:** Plugin architecture, interface surface area

### Real Issues Found
1. **BasePlugin god-interface** — `base_plugin.py` defines 80+ methods that every plugin must potentially implement. This is classic interface bloat — most plugins only override 2-3 methods.
2. **PluginsManager god-class** — `manager.py` inherits from `PaymentInterface` and has 50+ imports in TYPE_CHECKING block. It orchestrates all plugin calls through a chain-of-responsibility pattern but the class itself is >1000 lines.
3. **Configuration type safety** — Plugin configs use `list[dict]` (PluginConfigurationType) — no schema validation. Configuration errors are runtime failures.

### Prompt Gaps
- **GAP-13**: No interface surface area / ISP (Interface Segregation Principle) analysis
- **GAP-14**: No plugin/extension architecture evaluation patterns
- **GAP-15**: No configuration schema validation guidance

### Score: PROMPT 1/5 for this scenario

---

## Run 6: fastapi-template — Dependency Injection, Service Layer, CRUD Abstraction

**Repo:** `/home/intruder/projects/forge-test-repos/fastapi-template`
**Focus:** DI patterns, service layer, CRUD abstraction

### Real Issues Found
1. **Good DI pattern** — `deps.py` uses `Annotated[Session, Depends(get_db)]` pattern correctly. `CurrentUser` is clean. The prompt mentions DI generically but doesn't have evaluation criteria.
2. **Thin CRUD layer** — `crud.py` has only 5 functions (create_user, update_user, get_user_by_email, authenticate, create_item). No generic CRUD base class. This is fine for a small app but doesn't scale.
3. **Route-level business logic** — `items.py` routes contain inline DB queries (select, filter, count). No service layer between routes and DB. The superuser-vs-regular branching is duplicated in read_items and read_item.
4. **Good timing attack prevention** — `authenticate()` uses dummy hash when user not found. The prompt has no security pattern for this.

### Prompt Gaps
- **GAP-16**: No DI pattern evaluation criteria
- **GAP-17**: No service layer vs fat controller analysis
- **GAP-18**: No timing attack / constant-time comparison detection

### Score: PROMPT 3/5 for this scenario

---

## Run 7: medusa — Event-Driven Architecture, Message Patterns, Eventual Consistency

**Repo:** `/home/intruder/projects/forge-test-repos/medusa`
**Focus:** Event bus, workflow SDK, saga patterns

### Real Issues Found
1. **Workflow-as-code pattern** — `cancel-order.ts` uses `createWorkflow` + `createStep` + `parallelize` + `when` + `transform` — a sophisticated orchestration DSL. The prompt has no concept of workflow/saga evaluation.
2. **Compensating transactions** — The cancel-order workflow: validates -> refunds payments -> deletes reservations -> cancels payments -> emits event -> creates credit lines -> updates payment collections -> cancels order. This is a saga with compensation steps. Prompt has zero saga guidance.
3. **Event priority system** — `event-bus-redis.ts` has priority levels (10=critical, 100=default, 2097152=lowest). The prompt has no event priority or ordering guidance.
4. **Hook extensibility** — `createHook("orderCanceled", { order })` allows custom post-cancel logic. This is a well-designed extension point. The prompt doesn't evaluate hook/extension patterns.

### Prompt Gaps
- **GAP-19**: No workflow/saga pattern evaluation
- **GAP-20**: No compensating transaction analysis
- **GAP-21**: No event bus architecture review (priority, ordering, dead letter)
- **GAP-22**: No hook/extension point evaluation

### Score: PROMPT 1/5 for this scenario

---

## Run 8: clinic-portal — Audit Trail Gaps, State Machine Design

**Repo:** `/home/intruder/projects/clinic-portal`
**Focus:** Audit completeness, state machine correctness

### Real Issues Found
1. **Non-atomic state+audit** — `Task.transition_to()` does `self.save()` THEN `AuditLog.objects.create()` without `transaction.atomic`. If audit insert fails, state change is committed but audit is lost. Violates the project's own Rule #12.
2. **Audit gap on assign** — `assign_task()` in api.py calls `task.save()` without going through `transition_to()`, so the assignment doesn't trigger automatic status transition. But it does create an audit log separately. However, `task.save()` skips the transition validation entirely.
3. **AuditLog immutability is good** — `save()` raises on update, `delete()` raises always. But no DB-level PROTECT — a raw SQL `DELETE FROM workflows_auditlog` would work. The prompt should note DB-level vs ORM-level immutability.
4. **No "completed" terminal state protection** — VALID_TRANSITIONS shows completed=[] and cancelled=[], but there's no DB-level constraint. A raw `UPDATE` could set status back to "created".
5. **Workflow delete cascades tasks** — `Task.workflow` uses `on_delete=CASCADE`. Deleting a workflow destroys all tasks AND their audit history becomes orphaned (entity_id points to deleted task).

### Prompt Gaps
- **GAP-23**: No state machine atomicity verification (state change + audit in same transaction)
- **GAP-24**: No DB-level vs ORM-level constraint analysis
- **GAP-25**: No terminal state protection evaluation
- **GAP-26**: No cascade-through-audit-orphan detection

### Score: PROMPT 2/5 for this scenario

---

## Run 9: saleor — Database Transaction Patterns, Atomicity Guarantees

**Repo:** `/home/intruder/projects/forge-test-repos/saleor`
**Focus:** Transaction patterns, atomicity

### Real Issues Found
1. **Excellent lock_objects pattern** — `order/lock_objects.py` provides `order_qs_select_for_update()` and `order_lines_qs_select_for_update()` with `of=["self"]` to avoid locking joined tables. The prompt has no guidance on selective locking.
2. **traced_atomic_transaction** — `complete_checkout.py` imports `traced_atomic_transaction` — combining tracing with DB transactions. The prompt mentions "observability" but not transaction tracing.
3. **transaction_with_commit_on_errors** — Custom transaction manager that commits partial work on errors. The prompt has no pattern for partial-commit transaction strategies.
4. **14+ files use transaction.atomic in order/ alone** — Saleor is thorough about atomicity. The prompt should guide agents to verify this level of coverage.

### Prompt Gaps
- **GAP-27**: No SELECT FOR UPDATE / pessimistic locking evaluation
- **GAP-28**: No transaction scope analysis (too broad = lock contention, too narrow = inconsistency)
- **GAP-29**: No transaction tracing / observability integration

### Score: PROMPT 2/5 for this scenario

---

## Run 10: fastapi-template — API Versioning, Error Response Consistency, Pagination

**Repo:** `/home/intruder/projects/forge-test-repos/fastapi-template`
**Focus:** API versioning, error responses, pagination

### Real Issues Found
1. **Hardcoded API prefix** — `API_V1_STR = "/api/v1"` in config.py, router uses it in `main.py`. But there's no v2 strategy, no deprecation mechanism. The prompt mentions "API Design" but has no versioning evaluation.
2. **Inconsistent error codes** — `deps.py` returns 403 for invalid token, 404 for missing user, 400 for inactive user. `items.py` returns 404 for not found, 403 for no permission. `users.py` returns 400 for duplicate email in create, 409 for duplicate in update. The 400 vs 409 inconsistency is a real bug.
3. **No cursor-based pagination** — Uses offset/limit pagination (`skip=0, limit=100`). For large datasets, offset pagination is O(n). The prompt has no pagination strategy evaluation.
4. **No max limit enforcement** — `limit: int = 100` has no upper bound validation. A client can pass `limit=1000000`.
5. **Good: conditional route inclusion** — `private.router` only included in local environment. The prompt should note this as a good pattern.

### Prompt Gaps
- **GAP-30**: No API versioning strategy evaluation
- **GAP-31**: No error response consistency audit (status codes, error message structure)
- **GAP-32**: No pagination strategy analysis (offset vs cursor vs keyset)
- **GAP-33**: No rate limiting / query parameter bounds checking

### Score: PROMPT 2/5 for this scenario

---

## Summary: All Gaps

| Gap ID | Category | Description |
|--------|----------|-------------|
| GAP-01 | Data Access | DataLoader / N+1 query detection |
| GAP-02 | GraphQL | Schema structure evaluation |
| GAP-03 | Data Access | Read replica / write-read split |
| GAP-04 | Code Organization | Model vs API schema separation |
| GAP-05 | Schema Design | Timestamp field checklist |
| GAP-06 | Migrations | Migration history review |
| GAP-07 | Polyglot | TypeScript/Node ORM patterns |
| GAP-08 | Schema Design | Soft delete / partial indexes |
| GAP-09 | Architecture | Cross-module reference strategies |
| GAP-10 | Data Integrity | CASCADE risk analysis |
| GAP-11 | Data Integrity | Transaction atomicity enforcement |
| GAP-12 | Data Integrity | Orphaned resource detection |
| GAP-13 | Design Principles | Interface Segregation (ISP) |
| GAP-14 | Architecture | Plugin/extension evaluation |
| GAP-15 | Configuration | Config schema validation |
| GAP-16 | Architecture | DI pattern evaluation |
| GAP-17 | Architecture | Service layer analysis |
| GAP-18 | Security | Timing attack detection |
| GAP-19 | Architecture | Workflow/saga evaluation |
| GAP-20 | Data Integrity | Compensating transactions |
| GAP-21 | Architecture | Event bus review |
| GAP-22 | Architecture | Hook/extension points |
| GAP-23 | Data Integrity | State machine atomicity |
| GAP-24 | Data Integrity | DB-level vs ORM-level constraints |
| GAP-25 | State Machine | Terminal state protection |
| GAP-26 | Data Integrity | Cascade-through-audit orphans |
| GAP-27 | Concurrency | SELECT FOR UPDATE evaluation |
| GAP-28 | Concurrency | Transaction scope analysis |
| GAP-29 | Observability | Transaction tracing |
| GAP-30 | API Design | Versioning strategy |
| GAP-31 | API Design | Error response consistency |
| GAP-32 | API Design | Pagination strategy |
| GAP-33 | API Design | Rate limiting / bounds |

**Average prompt score across 10 runs: 1.8/5**
**Primary weakness:** The prompt is too abstract — it lists focus areas (API Design, Database Architecture, Security) but provides no concrete evaluation checklists or detection patterns.
