# Run 10: AI evaluation frameworks -- DeepEval vs RAGAS vs promptfoo vs LangSmith

## Research Topic
"AI evaluation frameworks -- DeepEval vs RAGAS vs promptfoo vs LangSmith"

## Research Performed
- WebSearch: "DeepEval vs RAGAS vs promptfoo vs LangSmith AI evaluation framework comparison 2025 2026"
- WebFetch: Braintrust article on DeepEval alternatives (successful)

## Prompt Evaluation

### What the prompt guided well
1. **Alternative comparison** -- Four frameworks clearly compared with differentiated use cases
2. **Conceptual Deepening** -- Overview (paradigms) -> Details (metric counts, pricing) -> Examples (RAG eval, security testing) -> Edge cases (team scaling friction)
3. **Current best practices** -- Captured the lifecycle pattern: RAGAS for fast RAG validation -> DeepEval/promptfoo for dev-time rigor -> LangSmith for production monitoring
4. **Source credibility check** -- Noted DeepEval's own comparison articles have obvious bias; cross-referenced with independent sources

### What the prompt missed or was weak on
1. **No hands-on trial instruction** -- Evaluation frameworks are best compared by running them on the same test suite, but prompt doesn't push for practical validation
2. **No "integration complexity" assessment** -- How hard is it to add each to an existing CI/CD pipeline? Prompt doesn't push for setup effort comparison
3. **No custom metric creation comparison** -- Production teams need custom metrics; prompt doesn't push for extensibility analysis
4. **No data privacy assessment** -- Evaluation sends prompts/responses to external services; prompt doesn't flag privacy implications
5. **No "evolution path" analysis** -- Teams outgrow tools; prompt doesn't push for "what do you migrate to after X?"

### Research Quality Score: 8/10
- Sources found: 6 relevant including independent comparison
- Alternatives compared: 4 main + Braintrust and TruLens as emerging
- Actionable recommendation: Yes -- lifecycle approach with tool progression
- Key insight: "Most teams evolve their stack over time" -- no single tool covers the full evaluation lifecycle

## Handoff Output (as agent would produce)

```
## Research Completed
### Summary: No single AI evaluation tool covers the full lifecycle. RAGAS excels at RAG-specific metrics. DeepEval offers broadest metric coverage (60+) with pytest integration. Promptfoo leads in security/red-teaming. LangSmith is best for LangChain-native teams. Most teams layer tools over time.
### Approach Recommended: Start with RAGAS for RAG evaluation, add DeepEval for comprehensive testing in CI/CD, use LangSmith only if already on LangChain stack.
### Alternatives Considered:
- DeepEval: 60+ metrics, pytest-native, broadest coverage. No built-in dashboard.
- RAGAS: Best RAG-specific metrics, built-in synthetic data gen. Narrow scope beyond RAG.
- Promptfoo: YAML-driven, security/red-teaming focus, Node.js native. Local-only results.
- LangSmith: LangChain-native tracing + eval. Per-seat pricing friction.
- Braintrust: CI/CD quality gates with merge blocking. $249/mo Pro tier.
### Sources:
- https://www.braintrust.dev/articles/deepeval-alternatives-2026
- https://deepeval.com/blog/tags/comparisons
- https://www.gocodeo.com/post/top-5-ai-evaluation-frameworks-in-2025-from-ragas-to-deepeval-and-beyond
- https://www.getmaxim.ai/articles/the-5-best-rag-evaluation-tools-you-should-know-in-2026/
### Delegation Hints: Next: @quality-engineer should set up RAGAS evaluation pipeline for the project's RAG components, then add DeepEval for broader testing.
### Risks/Unknowns: Evaluation tools themselves use LLMs (LLM-as-judge), adding cost and non-determinism. Framework lock-in is real -- metric definitions may not port between tools.
### Insights for Playbook:
INSIGHT: No single evaluation tool covers the full AI lifecycle -- plan for tool layering (RAGAS -> DeepEval -> LangSmith).
INSIGHT: DeepEval offers pytest integration -- treat LLM evaluation like unit tests in CI/CD.
INSIGHT: Promptfoo is the only framework focused on LLM security/red-teaming -- essential for production safety.
INSIGHT: LLM-as-judge metrics add cost and non-determinism to the evaluation process itself.
```

## Prompt Gaps Identified
| Gap | Severity | Fix |
|-----|----------|-----|
| No hands-on trial instruction | High | Add: "For tool/framework comparisons, run a minimal evaluation with top 2 candidates" |
| No integration complexity assessment | Medium | Add: "Assess integration effort: setup time, CI/CD compatibility, existing toolchain fit" |
| No extensibility analysis | Medium | Add: "Evaluate custom extension/plugin capabilities for production customization needs" |
| No data privacy assessment | High | Add: "For tools that process sensitive data, assess privacy implications and data residency" |
| No evolution path analysis | Medium | Add: "Map the tool progression path -- what do teams graduate to at each scale level?" |
