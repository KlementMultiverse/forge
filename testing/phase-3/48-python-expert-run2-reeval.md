# Test: @python-expert — Run 2 (re-eval after quality gates + chaos)

## Input (DIFFERENT from Run 1)
Implement a rate limiter decorator with Redis backend and tenant-aware bucketing

## Score: 17/17 (100%)

1-12: All PASS
16. Confidence routing: PASS
17. Self-correction loop: PASS
18. Negative instructions: PASS
19. Tool failure handling: PASS
20. Chaos resilience: PASS — handles empty module, circular imports, missing deps, type conflicts, version mismatch

## Verdict: PERFECT (100%) ✓
