# Autoresearch: @chatbot-builder

## Research Sources
- LangGraph memory overview: https://docs.langchain.com/oss/python/concepts/memory
- LangGraph + Mem0 integration: https://www.digitalocean.com/community/tutorials/langgraph-mem0-integration-long-term-ai-memory
- Mem0 vs LangMem comparison 2026: https://dev.to/anajuliabit/mem0-vs-zep-vs-langmem-vs-memoclaw-ai-agent-memory-comparison-2026-1l1k
- LangMem conceptual guide: https://langchain-ai.github.io/langmem/concepts/conceptual_guide/

## Run Results (5 Mental Simulations)

### Run 1: "Build customer support chatbot with tool use and escalation"
**Result: PASS**
- Prompt covers tool use with JSON schema definitions, execution handlers, error recovery
- Covers escalation patterns via LangGraph state machine routing
- Adequate guidance

### Run 2: "Implement 3-tier memory (sliding window + summary + long-term)"
**Result: PASS with gaps**
- Prompt correctly describes tiered memory: sliding window, summarization, vector store (Mem0)
- GAP: No mention of LangMem as alternative to Mem0 — LangMem is now the native LangGraph memory solution and better integrated for LangGraph shops
- GAP: No mention of Mem0's graph memory feature (entity extraction + relationship modeling) which is significantly better for temporal/relational questions
- GAP: No mention of Mem0's memory compression engine (up to 80% prompt token reduction)
- GAP: No guidance on WHEN to use Mem0 vs LangMem (Mem0 for managed/graph memory, LangMem for LangGraph-native/self-hosted)

### Run 3: "Add input/output guardrails for medical chatbot"
**Result: PASS with minor gap**
- Prompt covers input validation (injection detection, PII scrubbing) and output validation
- Correctly delegates heavy safety to @ai-safety-agent
- GAP: No mention of medical-specific guardrails (medication dosage validation, emergency detection → immediate escalation)

### Run 4: "Create conversation management with LangGraph state machine"
**Result: PASS with gaps**
- Prompt covers LangGraph for complex flows with branching, looping, human-in-the-loop
- GAP: No mention of LangGraph's new `interrupt()` function (simpler API than interrupt_before/interrupt_after) — the prompt only references the older pattern
- GAP: No mention of `Command(resume=value)` for passing data back after interrupts
- GAP: No mention of multiple interrupt support (resuming parallel interrupts with mapped IDs)

### Run 5: "Build multi-tenant chatbot (different knowledge bases per tenant)"
**Result: PASS with minor gap**
- Prompt covers session handling and Redis for session state
- GAP: No explicit guidance on tenant-scoped memory isolation — each tenant should have isolated long-term memory namespace
- GAP: No mention of tenant-scoped thread_id patterns for LangGraph checkpointing

## Gaps Found (to fix in prompt)

1. **HIGH**: Missing LangMem as alternative to Mem0 with comparison guidance (when to use which)
2. **HIGH**: Missing LangGraph `interrupt()` function + `Command(resume=value)` — the new simpler API replacing interrupt_before/interrupt_after
3. **MEDIUM**: Missing Mem0 graph memory and compression capabilities
4. **MEDIUM**: Missing tenant-scoped memory isolation patterns
5. **MEDIUM**: Missing multiple interrupt resume support (parallel interrupt handling)
6. **LOW**: Missing domain-specific guardrail guidance (medical, financial, etc.)
