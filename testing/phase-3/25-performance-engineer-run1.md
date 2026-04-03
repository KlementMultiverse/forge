# Test: @performance-engineer — Run 1/10

## Input
Profile and optimize clinic-portal API response times (workflow CRUD endpoints)

## Score: 16/17 applicable (94%) — after fixes

### Core (items 1-15)
1. Single responsibility: PASS — "Optimize system performance through measurement-driven analysis"
2. Forge Cell referenced: PASS — MEASUREMENT-specific (9-step: measure → identify → research → optimize → verify → compare)
3. context7 MCP: PASS — step 4
4. Web search: PASS — step 4
5. Self-executing: PASS — cProfile, EXPLAIN ANALYZE, curl timing commands
6. Handoff protocol: PASS — 6-field
7. [REQ-xxx]: PASS
8. Per-agent judge: PASS
9. Specific rules: PASS — "NEVER optimize without measuring", "one change at a time", "10% threshold"
10. Failure escalation: PASS
11. /learn: PASS
12. Anti-patterns: PASS — 6 items, all measurement-specific
13-15: N/A

### New (items 16-20)
16. Confidence routing: PASS — added
17. Self-correction loop: PASS — added
18. Negative instructions near end: PASS
19. Tool failure handling: PASS — added
20. Chaos resilience: FAIL

## STRENGTH
Exceptional domain adaptation. The Forge Cell is completely rewritten for performance:
"MEASURE first, then OPTIMIZE. Never optimize without data."
Specific Bash commands for profiling (cProfile, EXPLAIN ANALYZE, curl timing).
Honest reporting: "If improvement < 10% → may not be worth the complexity."

## Verdict: EXCELLENT — best domain-adapted Forge Cell
