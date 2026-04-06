# /sc:cleanup — Remove Dead Code

Find and remove unused code, imports, variables, and files.

## What It Does

1. Run ruff check --select F401 (unused imports)
2. Find unreachable code paths
3. Find unused variables and functions
4. Find empty files or placeholder-only files
5. Remove with verification (tests must still pass after each removal)

## Rules
- Run full test suite after EACH removal
- Never remove code that has [REQ-xxx] tags without checking SPEC
- Commit removals separately from additions
