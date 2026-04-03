# Test: @refactoring-expert — Run 2 (re-eval after quality gates)

## Input (DIFFERENT from Run 1)
Refactor a 500-line views.py with mixed concerns (auth, business logic, serialization)

## Score: 17/17 (100%)

1-12: All PASS (was 11/12 → fixed /learn)
16. Confidence routing: PASS
17. Self-correction loop: PASS
18. Negative instructions: PASS
19. Tool failure handling: PASS
20. Chaos resilience: PASS — handles no tests, already clean, circular deps, >300 lines, breaks tests

## Verdict: PERFECT (100%) ✓
