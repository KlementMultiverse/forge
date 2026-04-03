# Test: @backend-architect — Run 1/10

## Input
Design the database schema and API layer for clinic-portal workflows module

## Score: 15/17 applicable (88%) — after fixes

### Core (items 1-15)
1. Single responsibility: PASS — "Design reliable backend systems"
2. Forge Cell referenced: PASS — 9-step with Bash commands
3. context7 MCP: PASS — step 1
4. Web search: PASS — step 2 "compare 2+ alternatives"
5. Self-executing (Bash): PASS — test commands, lint, import verification
6. Handoff protocol: PASS — 6-field format
7. [REQ-xxx] traceability: PASS — step 6 SYNC
8. Per-agent judge: PASS — step 8
9. Specific rules: PASS — backend-specific patterns
10. Failure escalation: PASS — max 3, /investigate
11. /learn: PASS
12. Anti-patterns: PASS — 7 items, all specific
13-15: N/A (reviewer-specific)

### New (items 16-20)
16. Confidence routing: PASS — added
17. Self-correction loop: PASS — added (4-step self-check)
18. Negative instructions near end: PASS — anti-patterns at bottom
19. Tool failure handling: PASS — added (context7 → web → training fallback)
20. Chaos resilience: FAIL — no explicit guidance for empty/malformed input

## Prompt Fix Applied
Added items 16, 17, 19 via batch update (Confidence Routing, Self-Correction Loop, Tool Failure Handling).

## GAP REMAINING
- Item 20: No explicit guidance on handling empty or malformed inputs.
  Acceptable for now — the Self-Correction Loop partially addresses this.

## Verdict: STRONG — 88% pass rate, 1 minor gap
