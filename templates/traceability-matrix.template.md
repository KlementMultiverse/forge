# Traceability Matrix

Maps every spec requirement to its test and implementation. Run `scripts/traceability.sh` to auto-verify.

## Requirements → Tests → Code

| REQ ID | Requirement | Test File | Test Function | Code File | Status |
|--------|------------|-----------|---------------|-----------|--------|
| [REQ-001] | [Description] | tests/test_X.py | test_create_X | apps/X/models.py | Implemented |
| [REQ-002] | [Description] | tests/test_X.py | test_transition | apps/X/models.py | Implemented |
| [REQ-003] | [Description] | — | — | — | Not Started |

## Coverage Summary

- Total requirements: [N]
- With tests: [N] ([%])
- With code: [N] ([%])
- Fully traced (spec + test + code): [N] ([%])
- Orphan tests (no REQ): [N]
- Orphan code (no REQ): [N]

## How To Use

1. Add [REQ-xxx] tags to SPEC.md for every requirement
2. Reference [REQ-xxx] in test comments: `def test_create():  # [REQ-001]`
3. Reference [REQ-xxx] in code comments: `class Workflow:  # [REQ-001]`
4. Run `./scripts/traceability.sh` to auto-check coverage
5. Update this matrix after each implementation phase
