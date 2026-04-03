# REAL TEST: @code-archaeologist on apps/workflows/

## Input
"Deep analysis of apps/workflows/ — dead code, inconsistencies, state machine gaps, hidden dependencies"

## Real Findings: 12 issues

| # | Severity | Finding | Location |
|---|---|---|---|
| 1 | CRITICAL | Cache key "workflows:list" not tenant-namespaced — data leak across tenants | api.py:130,137 |
| 2 | HIGH | LLM output from generate_tasks not sanitized with strip_tags() — violates CLAUDE.md Rule #18 | api.py:303-304 |
| 3 | MEDIUM | "assigned" status doesn't require assigned_to to be set | models.py:97-124 |
| 4 | MEDIUM | assign_task doesn't trigger status transition | api.py:479-509 |
| 5 | MEDIUM | AuditLog.delete() override bypassed by QuerySet.delete() | models.py:35-36 |
| 6 | MEDIUM | No service layer — 60-line business logic in views | api.py:265-325 |
| 7 | LOW | No back-transition from "assigned" to "created" | models.py:63 |
| 8 | LOW | No back-transition from "in_progress" to "assigned" | models.py:65 |
| 9 | LOW | update_task audit log has empty details dict | api.py:426-431 |
| 10 | LOW | Duplicate log lines on every transition | api.py:457-470 |
| 11 | LOW | No pagination on list endpoints | api.py:118,334 |
| 12 | LOW | Circular dependency: workflows→documents→workflows | api.py:12 |

## INSIGHTS for Playbook
1. QuerySet.delete() bypasses model delete() — immutability guards need both model + manager level
2. State machine transitions need invariant checks (assigned requires assigned_to)
3. Cache keys look safe with make_key but fail without tenant context

## Score: EXCELLENT — found CRITICAL data leak bug + 11 more real issues
