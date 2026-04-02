# Test: @refactoring-expert — Run 1/10

## Input
_require_admin() duplicated in 3 files (workflows, documents, users api.py)

## Score: 11/12 (92%)

## What it did correctly:
- Created shared module (apps/permissions.py)
- Used import alias (as _require_admin) — zero call-site changes
- Preserved custom error message in users app (thin wrapper)
- Provided verification commands (ruff, compile check, tests)
- Actually wrote the code and applied changes
- Atomic: one concern per change

## Gap:
- No /learn insight flagged (e.g., "duplication across api.py files is a pattern — check for other shared utilities")
- No [REQ-xxx] check mentioned (though none existed near this code)

## Verdict: STRONG — real refactoring with zero behavior change
