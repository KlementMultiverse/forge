# REAL TEST: @backend-architect on clinic-portal

## Input
"Review database schema design — relationships, field types, constraints, tenant isolation, audit trail"

## Real Findings: 15 issues

| # | Severity | Finding |
|---|---|---|
| 1 | CRITICAL | Workflow.created_by and Task.created_by use CASCADE — deleting user destroys all their data |
| 2 | CRITICAL | Cross-schema FKs (tenant→shared user) with CASCADE is unreliable in PostgreSQL |
| 3 | CRITICAL | Document.s3_key has no unique constraint — duplicate records possible |
| 4 | HIGH | Staff invite/remove NOT audit-logged (violates CLAUDE.md Rule 12) |
| 5 | HIGH | Tenant creation NOT audit-logged |
| 6 | HIGH | Password reset NOT audit-logged |
| 7 | MODERATE | Document.size_bytes is IntegerField (allows negatives, caps at 2GB) — should be PositiveBigIntegerField |
| 8 | MODERATE | Tenant.name has no unique constraint — race condition for duplicates |
| 9 | MODERATE | AuditLog.entity_id is IntegerField — should be PositiveIntegerField |
| 10 | LOW | No related_name on 5+ ForeignKeys — will cause reverse accessor clashes |
| 11 | LOW | No standalone index on AuditLog.entity_type |
| 12 | LOW | Task.due_date is DateTimeField but due dates are day-precision |

## Tenant Isolation Assessment: CORRECT
All 10 models correctly placed in shared vs tenant apps.

## Score: EXCELLENT — found 3 CRITICAL schema bugs + 3 audit gaps
