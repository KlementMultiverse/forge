# Gap-to-Fix Mapping: Backend Architect Agent

## Prompt Changes Made

**File:** `/home/intruder/projects/forge/agents/universal/backend-architect.md`

### What Changed
1. **Expanded Focus Areas** (line 19-25): Added versioning, pagination, CASCADE analysis, transaction atomicity, constraint enforcement, orphan detection, timing attacks, saga/workflow patterns, read replicas, N+1 detection, dataloader patterns, plugin/extension systems, event-driven design, service layer separation, DI evaluation.

2. **Added 7 Review Checklists** (lines 34-91): Concrete, actionable detection patterns organized by category:
   - Schema Design (7 items)
   - Data Integrity & Transactions (6 items)
   - API Design (6 items)
   - Security (4 items)
   - Architecture Patterns (6 items)
   - Performance & Observability (4 items)
   - Polyglot Support (4 items)

### Gap Coverage

| Gap ID | Fixed By | Checklist Item |
|--------|----------|----------------|
| GAP-01 | Performance & Observability | N+1 query detection / DataLoader |
| GAP-02 | API Design | GraphQL connection pattern |
| GAP-03 | Performance & Observability | Read replica awareness |
| GAP-04 | Schema Design | Model vs API schema separation |
| GAP-05 | Schema Design | Timestamp field checklist |
| GAP-06 | Schema Design | Migration history review |
| GAP-07 | Polyglot Support | TypeScript/Node ORM patterns |
| GAP-08 | Schema Design | Soft delete / partial indexes |
| GAP-09 | Architecture Patterns | Cross-module references |
| GAP-10 | Schema Design | CASCADE risk analysis |
| GAP-11 | Data Integrity | Transaction atomicity enforcement |
| GAP-12 | Schema Design | Orphaned resource detection |
| GAP-13 | Architecture Patterns | Plugin interface ISP |
| GAP-14 | Architecture Patterns | Plugin/extension evaluation |
| GAP-15 | Architecture Patterns | (covered by DI + plugin items) |
| GAP-16 | Architecture Patterns | DI pattern evaluation |
| GAP-17 | Architecture Patterns | Service layer analysis |
| GAP-18 | Security | Timing attack detection |
| GAP-19 | Architecture Patterns | Workflow/saga orchestration |
| GAP-20 | Data Integrity | Compensating transactions |
| GAP-21 | Architecture Patterns | Event-driven architecture |
| GAP-22 | Architecture Patterns | Workflow hooks/extension points |
| GAP-23 | Data Integrity | State mutation atomicity |
| GAP-24 | Data Integrity | DB-level vs ORM-level constraints |
| GAP-25 | Data Integrity | State machine terminal states |
| GAP-26 | Schema Design | Cascade + orphan detection |
| GAP-27 | Data Integrity | SELECT FOR UPDATE |
| GAP-28 | Data Integrity | Transaction scope analysis |
| GAP-29 | Performance & Observability | Transaction tracing |
| GAP-30 | API Design | Versioning strategy |
| GAP-31 | API Design | Error response consistency |
| GAP-32 | API Design | Pagination strategy |
| GAP-33 | API Design | Rate limiting / bounds |

### Score Impact (Projected)

| Run | Before | After (projected) | Reason |
|-----|--------|-------------------|--------|
| 1: saleor GraphQL | 2/5 | 4/5 | DataLoader, N+1, read replica checklists |
| 2: fastapi models | 2/5 | 4/5 | Timestamp, schema separation, migration items |
| 3: medusa entities | 1/5 | 4/5 | Polyglot support, soft delete, cross-module refs |
| 4: clinic CASCADE | 2/5 | 5/5 | CASCADE analysis, orphan detection |
| 5: saleor plugins | 1/5 | 4/5 | Plugin ISP, interface evaluation |
| 6: fastapi DI | 3/5 | 4/5 | DI evaluation, service layer, timing attack |
| 7: medusa events | 1/5 | 4/5 | Event-driven, saga, hooks/extension |
| 8: clinic audit | 2/5 | 5/5 | Atomicity, DB constraints, terminal states |
| 9: saleor transactions | 2/5 | 5/5 | SELECT FOR UPDATE, transaction scope, tracing |
| 10: fastapi API | 2/5 | 5/5 | Versioning, error consistency, pagination, bounds |

**Average: 1.8/5 -> 4.4/5 (projected)**
