# Run 04: Compare LiteLLM vs Portkey vs direct API for LLM gateway

## Research Topic
"Compare LiteLLM vs Portkey vs direct API for LLM gateway"

## Research Performed
- WebSearch: "LiteLLM vs Portkey vs direct API LLM gateway proxy comparison 2025 2026"

## Prompt Evaluation

### What the prompt guided well
1. **Alternative comparison** -- Three clear alternatives with pros/cons (LiteLLM self-hosted, Portkey managed, direct API)
2. **Current best practices** -- Captured the emerging pattern of LLM gateways as infrastructure standard, not optional
3. **Gotchas** -- Found LiteLLM performance ceiling (~2000 RPS before timeout, 8GB+ memory)
4. **Tool Orchestration** -- Parallel search strategy worked well for this comparison topic

### What the prompt missed or was weak on
1. **No "build vs buy" framework** -- Prompt doesn't push for structured build-vs-buy analysis despite this being the core decision
2. **No operational complexity assessment** -- Self-hosted LiteLLM vs managed Portkey have very different ops burden
3. **No security/compliance lens** -- LLM gateways handle sensitive prompts; prompt doesn't push for security posture comparison
4. **No pricing model comparison** -- Found Portkey starts at $49/mo but prompt doesn't instruct agent to calculate TCO at different scales
5. **Kong AI Gateway emerged as a strong contender** -- Prompt's "compare 2+ approaches" might have missed it if search hadn't returned it; need "look for unexpected alternatives"

### Research Quality Score: 7/10
- Sources found: 5 relevant
- Alternatives compared: 4 (LiteLLM, Portkey, direct API, Kong)
- Actionable recommendation: Yes but lacks depth -- needed deeper dive on Kong and Helicone
- Key insight: LiteLLM hits performance wall at ~2000 RPS; Kong had 65% lower latency than Portkey

## Handoff Output (as agent would produce)

```
## Research Completed
### Summary: LLM gateways are now infrastructure standard. LiteLLM is best for self-hosted Python teams under 500 RPS. Portkey wins for production teams needing observability and governance. Kong AI Gateway outperforms both on latency benchmarks.
### Approach Recommended: Portkey for production teams with multi-provider needs. LiteLLM for self-hosted control. Direct API only for single-provider prototypes.
### Alternatives Considered:
- LiteLLM: Open-source, self-hosted, max customization. Performance ceiling at ~2000 RPS, 8GB+ memory.
- Portkey: Managed, 1600+ LLMs, full observability/governance. Starts $49/mo, may be heavy for prototypes.
- Direct API: Simplest, zero overhead. No redundancy, no cost tracking, provider lock-in.
- Kong AI Gateway: 65% lower latency than Portkey. Enterprise API gateway with MCP support.
### Sources:
- https://resultantai.com/compare
- https://konghq.com/blog/engineering/ai-gateway-benchmark-kong-ai-gateway-portkey-litellm
- https://www.helicone.ai/blog/top-llm-gateways-comparison-2025
- https://dev.to/varshithvhegde/top-5-llm-gateways-in-2026-a-deep-dive-comparison-for-production-teams-34d2
### Delegation Hints: Next: @devops-architect should evaluate gateway options based on current traffic projections and compliance requirements.
### Risks/Unknowns: Benchmark conditions may differ from real workloads. LiteLLM performance under sustained load needs independent validation.
### Insights for Playbook:
INSIGHT: LiteLLM performance ceiling at ~2000 RPS with 8GB+ memory -- plan capacity accordingly for self-hosted.
INSIGHT: Kong AI Gateway outperforms both LiteLLM and Portkey on latency benchmarks (65% lower than Portkey, 86% lower than LiteLLM).
INSIGHT: 15-30 min setup for LiteLLM vs <5 min for managed gateways -- factor into developer time cost.
```

## Prompt Gaps Identified
| Gap | Severity | Fix |
|-----|----------|-----|
| No build-vs-buy framework | High | Add: "For infrastructure topics, explicitly apply build-vs-buy analysis" |
| No operational complexity assessment | High | Add: "Assess operational burden: who maintains it, what breaks, on-call implications" |
| No security/compliance lens | Medium | Add: "For data-handling infrastructure, assess security posture and compliance implications" |
| No pricing model comparison at scale | Medium | Add: "Calculate TCO at multiple traffic levels (100, 1K, 10K RPS)" |
| No instruction to look beyond named alternatives | Medium | Add: "Always search for alternatives beyond those named in the query" |
