# @python-expert Prompt Changes — Autoresearch 2026-04-02

## Added: "Python Code Standards" section (9 sub-sections)

| Sub-section | Gap Found In Run | Key Rule Added |
|---|---|---|
| Type Hints | Run 1 (clinic-portal audit) | Every public function MUST have annotations; run mypy |
| Exception Handling | Run 2 (saleor), Run 9 (fastapi) | Custom domain exceptions; never str(e) in responses |
| Import Organization | Run 4 (clinic-portal) | Enable I001; no stdlib inline imports |
| String Formatting | Run 7 (clinic-portal) | f-strings default; %-formatting only in logger |
| Logging | Run 10 (clinic-portal) | structlog; tenant_id/user_id in every line |
| Data Modeling | Run 5 (saleor) | dataclass(frozen) for DTOs; no raw dicts across boundaries |
| Context Managers | Run 8 (saleor) | Never __del__; use with for cleanup |
| Async/Sync | Run 3 (fastapi) | Choose one and be consistent |
| Dependency Management | Run 6 (fastapi pyproject) | Exact pins for apps; include pip-audit |

## Forge Cell Step 5: Added mypy
Before: `black . && ruff check . --fix`
After: `black . && ruff check . --fix` + `uv run mypy apps/{app}/`

## Anti-Patterns: 7 -> 14 items
Added 7 new concrete anti-patterns matching the code standards.

## Before/After Usefulness

Prompt guidance score on same 10 runs:
- Before: 3/10 runs had useful guidance = 30%
- After (projected): 8/10 runs would have actionable rules = 80%

Remaining gap: Structured logging (structlog) is recommended but not enforced via verification command. Would need a custom ruff rule or grep check.
