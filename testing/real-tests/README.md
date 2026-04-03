# Real Agent Test Results

These are REAL tests — agents were actually spawned on the clinic-portal codebase and their outputs captured.

## Test Results Summary

| # | Agent | Input | Real Findings | Score |
|---|---|---|---|---|
| 01 | @security-engineer | Full security scan | 11 issues (2 CRITICAL, 2 HIGH, 5 MEDIUM, 2 LOW) + 9 positive findings | EXCELLENT |
| 02 | @quality-engineer | Test coverage analysis | 280 tests counted, TenantTestCase compliance 100%, found wrong mock target | EXCELLENT |
| 03 | @root-cause-analyst | "401 vs 302" investigation | Root cause: SafeTenantAccessMiddleware redirects before API auth runs | EXCELLENT |
| 04 | @refactoring-expert | documents/api.py analysis | 6 refactoring opportunities, 130-line monolith decomposition plan | EXCELLENT |
| 05 | @code-archaeologist | workflows/ deep analysis | 12 issues (1 CRITICAL cache leak, 1 HIGH unsanitized LLM, state machine gaps) | EXCELLENT |
| 06 | @performance-engineer | Full performance audit | 14 issues (N+1 queries, missing indexes, unbounded querysets, sync LLM blocking) | EXCELLENT |
| 07 | @backend-architect | Schema design review | 15 issues (3 CRITICAL CASCADE+unique, 3 HIGH audit gaps, field types) | EXCELLENT |
| 08 | @learning-guide | Explain multi-tenancy | Progressive 4-layer explanation using real project code, 100% accuracy | EXCELLENT |

## Total REAL Issues Found Across All Tests: 83 unique findings

### By Severity
- CRITICAL: 8
- HIGH: 10
- MEDIUM: 20+
- LOW: 15+

### Key Discoveries (not previously known)
1. CASCADE on cross-schema FKs — deleting a user cascades across schemas
2. Document.s3_key has no unique constraint
3. Staff invite/remove/password reset not audit-logged
4. generate_tasks doesn't sanitize LLM output (violates Rule 18)
5. Login N+1: fires 1 query per tenant for Domain lookup
6. 5 timestamp fields missing db_index across models
7. Sync LLM calls can block all WSGI workers for 90+ seconds

## Methodology
Each agent was spawned as a Claude Code subagent with a specific task targeting the real clinic-portal codebase at /home/intruder/projects/clinic-portal/. Agents read actual files, traced actual code paths, and reported findings with exact file:line references.
