# Test: @langgraph-agent -- Run 1/10

## Input
"Build a customer onboarding workflow with human-approval gates and persistent checkpoints"

## Score: 17/17 (100%)

1. Single responsibility: PASS -- Focused on LangGraph workflow construction: state graph definition, node implementation, human-in-the-loop gates, and checkpoint persistence
2. Forge Cell: PASS -- Implementer cell specializing in LangGraph stateful workflow construction
3. context7: PASS -- Fetches langgraph, langgraph-checkpoint, and langchain-core docs for current StateGraph API, checkpoint backends, and interrupt patterns
4. Web search: PASS -- Searches for latest LangGraph human-in-the-loop patterns, checkpoint backend options, and state management best practices
5. Self-executing: PASS -- Runs workflow with test inputs, validates checkpoint persistence across restarts, and tests human-approval gate behavior via Bash
6. Handoff: PASS -- Returns graph definition, state schema, checkpoint config, node implementations, test execution trace, and integration guide to orchestrator
7. [REQ-xxx]: PASS -- Tags with [REQ-LGR-001] state graph, [REQ-LGR-002] human-approval gates, [REQ-LGR-003] checkpoint persistence, [REQ-LGR-004] error recovery
8. Per-agent judge: PASS -- Validates workflow pauses at approval gates, checkpoints survive process restart, state transitions follow defined graph edges
9. Specific rules: PASS -- Enforces typed state schema with Pydantic, interrupt_before for human gates (not polling), PostgreSQL checkpoint backend for durability, idempotent node execution, and explicit edge conditions with no implicit fallthrough
10. Failure escalation: PASS -- Escalates if checkpoint backend unreachable, human approval timeout exceeded, or node execution fails after retries
11. /learn: PASS -- Records effective state schema patterns for onboarding workflows, checkpoint serialization gotchas, and human gate timeout configurations
12. Anti-patterns: PASS -- 5 items: no polling-based human approval, no in-memory checkpoints in production, no untyped state dictionaries, no missing error edges in graph, no nodes with side effects that are not idempotent
16. Confidence routing: PASS -- High for standard linear workflows with gates, medium for branching workflows with conditional edges, low for dynamic graph modification at runtime
17. Self-correction loop: PASS -- Re-designs state schema if checkpoint deserialization fails; adds missing error edges if test execution reveals unhandled exceptions
18. Negative instructions: PASS -- Never use in-memory checkpoints for production workflows, never skip interrupt_before for human approval, never allow untyped state mutations
19. Tool failure handling: PASS -- Falls back to SQLite checkpoint if PostgreSQL unavailable in dev; retries node execution on transient errors; preserves state on node failure for debugging
20. Chaos resilience: PASS -- Handles checkpoint backend crash mid-write, process restart during node execution, concurrent workflow instances with shared state, approval gate timeout, and corrupted checkpoint recovery

## Key Strengths
- Uses LangGraph's interrupt_before mechanism for human approval gates, which properly pauses execution rather than wasteful polling
- Enforces typed Pydantic state schemas that catch invalid state transitions at compile time rather than runtime
- Implements idempotent nodes so checkpoint-based recovery after crashes does not produce duplicate side effects

## Verdict: PERFECT (100%)
