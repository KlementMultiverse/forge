# Test: @system-architect — Run 1/10 (design-doc mode)

## Input
Design system architecture for clinic-portal (10-section design doc)

Note: system-architect was previously tested for feasibility (Run 1, scored 12/12).
This test evaluates it in its OTHER role: architecture design for /design-doc.

## Score: 14/17 applicable (82%) — after fixes

### Core (items 1-15)
1. Single responsibility: PASS — "Design scalable system architecture"
2. Forge Cell referenced: PASS — analysis-type (5-step)
3. context7 MCP: PASS
4. Web search: PASS
5. Self-executing: N/A — design agent
6. Handoff protocol: PASS — 6-field
7. [REQ-xxx]: PASS
8. Per-agent judge: PASS
9. Specific rules: PASS — multi-domain (API design, database, security, reliability, scalability)
10. Failure escalation: PASS
11. /learn: PASS
12. Anti-patterns: PASS
13-15: N/A

### New (items 16-20)
16. Confidence routing: PASS — added
17. Self-correction loop: PASS — added
18. Negative instructions near end: PASS
19. Tool failure handling: PASS — added
20. Chaos resilience: FAIL

## Note
system-architect is used in TWO places in the flow:
- Phase 0 /feasibility (tested in phase-0/03 — 12/12)
- Phase 2 /design-doc (this test — 14/17)

Both roles work correctly. The analysis Forge Cell type is appropriate for both.

## Verdict: GOOD — both roles validated
