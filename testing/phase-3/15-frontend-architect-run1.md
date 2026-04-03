# Test: @frontend-architect — Run 1/10

## Input
Create responsive dashboard layout for clinic-portal using Django templates + Pico CSS

## Score: 14/17 applicable (82%) — after fixes

### Core (items 1-15)
1. Single responsibility: PASS — "Create accessible, performant user interfaces"
2. Forge Cell referenced: PASS — 9-step
3. context7 MCP: PASS — step 1
4. Web search: PASS — step 2
5. Self-executing (Bash): PASS — test + lint commands
6. Handoff protocol: PASS — 6-field
7. [REQ-xxx] traceability: PASS — step 6
8. Per-agent judge: PASS — step 8
9. Specific rules: WEAK — mentions "React, Vue, Angular" in Focus Areas but Forge is stack-agnostic. Should say "project's chosen framework" instead of naming specific frameworks.
10. Failure escalation: PASS
11. /learn: PASS
12. Anti-patterns: PASS — but missing "NEVER add React/Vue when project uses templates"
13-15: N/A

### New (items 16-20)
16. Confidence routing: PASS — added
17. Self-correction loop: PASS — added
18. Negative instructions near end: PASS
19. Tool failure handling: PASS — added
20. Chaos resilience: FAIL

## GAP: Framework reference
Focus Areas still says "Modern Frameworks: React, Vue, Angular" — should be stack-agnostic since Forge adapts to any project.

## Prompt Fix Needed
- Focus Areas line 5: change to "Modern Frameworks: Project's chosen framework with best practices and optimization"
- Add anti-pattern: "NEVER introduce a frontend framework not specified in CLAUDE.md — always follow the project's tech stack"

## Verdict: GOOD — fix framework reference
