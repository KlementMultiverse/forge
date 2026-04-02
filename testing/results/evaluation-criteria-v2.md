# Agent Evaluation Criteria v2

Updated based on web research (Anthropic engineering, promptfoo, Scale AI ResearchRubrics).

## Previous: 12-point checklist
## New: 20-point checklist (15 existing + 5 from research)

### Core (items 1-15 — existing)
1. Single responsibility ("Your ONE task")
2. Forge Cell referenced
3. context7 MCP for library research
4. Web search for best practices + alternatives
5. Self-executing (RUN code via Bash)
6. Handoff protocol format
7. [REQ-xxx] traceability
8. Per-agent judge mentioned
9. Specific rules (not generic)
10. Failure escalation path
11. /learn for insights
12. Anti-patterns (what NOT to do)
13. Tenant isolation check (reviewer)
14. Caching compliance (reviewer)
15. Observability/logging (reviewer)

### New (items 16-20 — from research)
16. **Confidence routing** — agent states confidence level, routes low-confidence to human
17. **Self-correction loop** — agent reviews own output against rules BEFORE finalizing
18. **Negative instructions near end** — NEVER rules placed where models weight them most
19. **Tool failure handling** — what happens when context7/Bash/web search fails?
20. **Chaos resilience** — tested with bad inputs (empty, malformed, adversarial)?

## Scoring
- 18-20/20 = 5 (excellent)
- 15-17/20 = 4 (good — accept)
- 12-14/20 = 3 (needs improvement)
- 8-11/20 = 2 (significant issues)
- <8/20 = 1 (reject)

## Key Insight from Research
> "pass@1 hides unreliability. pass^5 is the real production metric."
> If a prompt works 70% of the time, pass^5 = 17%.
> Run each agent 5+ times with varied inputs to measure CONSISTENCY.

## Sources
- Anthropic: anthropic.com/engineering/demystifying-evals-for-ai-agents
- promptfoo: jonesrussell.github.io/blog/eval-harness-agency-agents
- Scale AI ResearchRubrics: github.com/scaleapi/researchrubrics
- Softcery: softcery.com/lab/why-ai-agent-prototypes-fail-in-production
