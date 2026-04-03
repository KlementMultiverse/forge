# Test: @retrospective-miner — Run 1/10

## Input
Analyze docs/retrospectives/ from clinic-portal, extract patterns, update playbook

## Score: 15/17 applicable (88%) — after fixes

### Core (items 1-15)
1. Single responsibility: PASS — "Your ONE task: analyze retrospectives, identify recurring patterns"
2. Forge Cell referenced: PASS — analysis-type (5-step)
3. context7 MCP: PASS
4. Web search: PASS
5. Self-executing: N/A — analysis agent
6. Handoff protocol: PASS — 6-field
7. [REQ-xxx]: PASS
8. Per-agent judge: PASS
9. Specific rules: PASS — 4-step pipeline (Extract → Classify → Act → Report), 6 classification categories
10. Failure escalation: PASS
11. /learn: PASS
12. Anti-patterns: PASS — "NEVER create constitution amendment for one-time issue"
13-15: N/A

### New (items 16-20)
16. Confidence routing: PASS — added
17. Self-correction loop: PASS — added
18. Negative instructions near end: PASS
19. Tool failure handling: PASS — added
20. Chaos resilience: FAIL

## STRENGTH
6 classification categories (strategy, mistake, constitution gap, hook gap, agent gap, rule gap).
3+ occurrence threshold for escalation to constitution-level rules.
Mining report format with specific sections.

## Verdict: STRONG — excellent extraction pipeline
