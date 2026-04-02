# Test: @code-archaeologist — Run 2/10 (after prompt fix)

## Input
apps/documents/ folder only (focused scope)

## Score: 12/12 (100%) — IMPROVEMENT FROM 10/12

| # | Criterion | Run 1 | Run 2 |
|---|-----------|-------|-------|
| 10 | /learn insights | FAIL | PASS — 4 INSIGHT entries! |
| 12 | Real data | PASS | PASS — actual line counts, grep results |

## Prompt Fix Verified:
Adding "MANDATORY — flag NON-OBVIOUS patterns as INSIGHT:" worked.
Agent now produces specific, actionable playbook entries.

## NEW ISSUES FOUND (not in Run 1):
1. [CRITICAL] Test mocks reference OLD function (invoke_summarize_lambda)
   but endpoint now calls _summarize_with_claude — tests pass vacuously!
2. [HIGH] Cache keys NOT tenant-aware — ID collision across tenants
3. [HIGH] Two divergent LLM paths (api.py vs services.py) with different sanitization
4. [MEDIUM] size_bytes allows negatives (IntegerField not PositiveIntegerField)

## INSIGHTS Generated (for /learn):
1. Mock staleness: when implementation changes, test mocks pass silently
2. Cache key collision: schema-per-tenant has separate ID sequences
3. Dual LLM paths = maintenance trap
4. Ad-hoc sanitization vs centralized validation function

## Verdict: FIX CONFIRMED — agent now produces complete output
