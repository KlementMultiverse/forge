# Run 06: Multi-agent frameworks -- LangGraph vs CrewAI vs AutoGen for code generation

## Research Topic
"Multi-agent frameworks -- LangGraph vs CrewAI vs AutoGen for code generation"

## Research Performed
- WebSearch: "LangGraph vs CrewAI vs AutoGen multi-agent framework code generation 2025 2026"

## Prompt Evaluation

### What the prompt guided well
1. **Alternative comparison** -- Three frameworks clearly differentiated by paradigm (graph-based, role-based, conversational)
2. **Current best practices** -- Captured LangGraph v1.0 milestone and its position as default LangChain runtime
3. **Conceptual Deepening** -- Overview (paradigms) -> Details (state management) -> Examples (use cases) -> Edge cases (code generation specifically)
4. **Trend check** -- Noted LangGraph reaching v1.0 in late 2025, indicating maturation

### What the prompt missed or was weak on
1. **No hands-on evaluation instruction** -- For code generation, the agent should try each framework with a sample task, not just read about them
2. **No "developer experience" assessment** -- How easy is it to debug? What's the error message quality? How good is the documentation?
3. **No production readiness checklist** -- Prompt doesn't push for: observability, error recovery, state persistence, cost control
4. **No agent communication overhead analysis** -- Multi-agent frameworks have inter-agent communication costs (tokens, latency) that prompt ignores
5. **No "when NOT to use multi-agent" analysis** -- Single-agent with tools might outperform multi-agent for many tasks

### Research Quality Score: 7/10
- Sources found: 6 relevant
- Alternatives compared: 3 main + OpenAgents as emerging option
- Actionable recommendation: Yes but generic -- "AutoGen for code generation" needs more depth
- Weakness: Relied heavily on comparison articles rather than primary docs or benchmarks

## Handoff Output (as agent would produce)

```
## Research Completed
### Summary: LangGraph (graph-based state machines), CrewAI (role-based teams), and AutoGen (conversational agents) represent three paradigms. For code generation specifically, AutoGen's iterative refinement via conversation excels. LangGraph v1.0 offers most production-ready state management. CrewAI is easiest to set up for business workflows.
### Approach Recommended: AutoGen for code generation tasks (iterative refinement via conversation). LangGraph for production workflows needing durable execution and error recovery.
### Alternatives Considered:
- LangGraph: Graph-based, durable execution, v1.0 production-ready. Steep learning curve, LangChain dependency.
- CrewAI: Role-based teams, fastest setup, intuitive. Less flexible for complex branching.
- AutoGen: Conversational, best for iterative refinement and code generation. Flexible but less structured.
- OpenAgents: Emerging open-source alternative, simpler API surface.
### Sources:
- https://openagents.org/blog/posts/2026-02-23-open-source-ai-agent-frameworks-compared
- https://www.datacamp.com/tutorial/crewai-vs-langgraph-vs-autogen
- https://latenode.com/blog/platform-comparisons-alternatives/automation-platform-comparisons/langgraph-vs-autogen-vs-crewai-complete-ai-agent-framework-comparison-architecture-analysis-2025
### Delegation Hints: Next: @system-architect should prototype the code generation workflow with AutoGen to validate iterative refinement fits the use case.
### Risks/Unknowns: Multi-agent token consumption can be 3-10x single-agent. LangGraph's LangChain dependency may limit portability. Framework APIs change rapidly.
### Insights for Playbook:
INSIGHT: For code generation, AutoGen's conversational refinement pattern (write -> review -> fix) maps naturally to the code review cycle.
INSIGHT: LangGraph v1.0 (late 2025) is the first multi-agent framework with production-grade durable execution and state persistence.
INSIGHT: CrewAI is 3x faster to set up than LangGraph but hits limitations with complex branching workflows.
```

## Prompt Gaps Identified
| Gap | Severity | Fix |
|-----|----------|-----|
| No hands-on evaluation instruction | High | Add: "For framework comparisons, prototype a simple task with top 2 options if feasible" |
| No developer experience assessment | Medium | Add: "Evaluate DX: debugging ease, error messages, documentation quality, community support" |
| No production readiness checklist | High | Add: "For infrastructure/framework topics, assess: observability, error recovery, state persistence, cost control" |
| No communication overhead analysis | Medium | Add: "For multi-agent/distributed systems, quantify inter-component communication costs" |
| No single-agent baseline | Medium | Add: "Always compare against the simpler alternative (e.g., single agent vs multi-agent)" |
