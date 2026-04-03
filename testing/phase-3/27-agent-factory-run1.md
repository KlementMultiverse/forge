# Test: @agent-factory — Run 1/10

## Input
Create agents for Svelte stack (no pre-existing agents)

## Score: 16/17 applicable (94%) — after fixes

### Core (items 1-15)
1. Single responsibility: PASS — "Your ONE task: create new domain-specific agents"
2. Forge Cell referenced: PASS — AGENT CREATION-specific (7-step: research → analyze → select archetype → generate → test → install → handoff)
3. context7 MCP: PASS — step 1
4. Web search: PASS — step 1
5. Self-executing: PASS — mkdir, cat, cp commands for agent files
6. Handoff protocol: PASS — custom Agent Creation handoff format
7. [REQ-xxx]: PASS
8. Per-agent judge: PASS
9. Specific rules: PASS — archetype selection, stack folder creation, README requirement
10. Failure escalation: PASS — "context7 has no docs → WebFetch", "too obscure → report honestly"
11. /learn: PASS — "unusual patterns → /learn", "archetype doesn't fit → /learn"
12. Anti-patterns: PASS — 5 items (no generic agents, no untested agents, no missing Forge Integration)
13-15: N/A

### New (items 16-20)
16. Confidence routing: PASS — added
17. Self-correction loop: PASS — added
18. Negative instructions near end: PASS
19. Tool failure handling: PASS — added + original has context7 fallback
20. Chaos resilience: FAIL — no guidance for invalid stack names or empty requirements

## STRENGTH
Step 0 (create folder), archetype selection via docs/patterns/agent-archetypes.md,
test-before-ship requirement, immediate installation to ~/.claude/agents/.
One of the most innovative agents in the framework.

## Verdict: EXCELLENT — creative agent design
