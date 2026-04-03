# Test: @root-cause-analyst — Run 2 (re-eval after quality gates)

## Input (DIFFERENT from Run 1)
Investigate: "Tests pass locally but fail in Docker with 'relation does not exist' error"

## Score: 17/17 (100%)

1-12: All PASS (was already 12/12)
16. Confidence routing: PASS
17. Self-correction loop: PASS
18. Negative instructions: PASS
19. Tool failure handling: PASS
20. Chaos resilience: PASS — handles empty errors, unreproducible, multiple causes, third-party bugs, fix makes worse

## Verdict: PERFECT (100%) ✓
