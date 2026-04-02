# Test: @reviewer — Code Review (Run 1/10)

## Input
Sample Django Ninja endpoint (bare minimum — no auth, no audit, no tests)

## Score Given by Reviewer: 2/12 — REJECT

## Evaluation of Reviewer Performance
The reviewer correctly caught 11 issues across 4 severity levels. Excellent.

## GAPS FOUND IN REVIEWER PROMPT (5 missing checklist items)

| # | Missing Check | Why It Matters |
|---|-------------|---------------|
| 1 | Tenant isolation | Multi-tenant project — data scoping is CRITICAL |
| 2 | Caching per spec | SPEC defines TTLs — reviewer should verify |
| 3 | Observability/logging | 10 logging points required — reviewer doesn't check |
| 4 | Architecture rules source | Says "rules/{stack}.md" but project uses CLAUDE.md |
| 5 | CSRF specifics | Generic "CSRF missing" vs project-specific SessionAuth pattern |

## Action: Add items 13-15 to reviewer checklist
