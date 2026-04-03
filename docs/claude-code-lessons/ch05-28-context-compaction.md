# Context Compaction Architecture

## Cost-Ladder Approach (4 Strategies)

1. **Microcompact** — Zero API calls; prunes tool-result content in-memory
2. **Session Memory Compact** — Pre-built memory file; avoids summarization call
3. **Full LLM Compact** — Forked sub-agent; 9-section structured summary
4. **Reactive Compact** — Emergency handler for 413 errors

## Token Pressure Thresholds

Normal (>20k remaining), Warning (<=20k), Error (<=20k red), Auto-Compact (<=13k), Blocking (<=3k).

## Microcompact

Keeps last 5 tool results; clears older ones. Token estimation: character heuristics padded by 4/3; images fixed at 2,000 tokens.

## Session Memory Compaction

Avoids API call using continuously-updated memory files. Tool-pair invariant preservation prevents orphaning tool_use/tool_result pairs.

## Full LLM Compaction: 9 Sections

Primary Request, Key Concepts, Files/Code, Errors/Fixes, Problem Solving, All User Messages (verbatim), Pending Tasks, Current Work, Optional Next Step.

Analysis scratchpad in `<analysis>` tags stripped before injection.

## Post-Compact Cleanup

Invalidates: microcompact state, context collapse, user context cache, classifier approvals, system prompt sections.

**Intentional non-clears**: `sentSkillNames` preserved (~4k tokens reinjection cost).

File restoration: Re-injects up to 5 previously-read files (50k token budget).

## Circuit Breaker

`MAX_CONSECUTIVE_AUTOCOMPACT_FAILURES = 3`. Prevented ~250k wasted API calls/day.
