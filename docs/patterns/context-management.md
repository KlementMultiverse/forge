# Context Management Pattern

Keep context clean and effective. Dirty context = bad code.

## The 4 Failure Modes

1. **Poisoning** — wrong information dominates context → bad decisions
2. **Distraction** — too much irrelevant detail → important things missed
3. **Confusion** — contradictory information → inconsistent output
4. **Clash** — context contradicts instructions → unpredictable behavior

## Rules

- **Sweet spot:** 40-60% of context window utilized
- **Rule of two:** after 2 failed corrections → /clear + better prompt
- **Fresh context per agent:** each spawned agent gets clean window
- **Research → Plan → Implement:** reset context between phases
- **Middle ignored:** beginning and end of context weighted most — put critical info there

## Layered Compression

When context fills up, compress in stages (cheapest first):
1. **Snip** — prune old exploration turns (free, just removes)
2. **Microcompact** — cache summaries of past tool outputs
3. **Auto-compact** — LLM summarizes old turns (costs tokens)
4. **Context collapse** — fold exploration into structured summaries

Only escalate if still over budget after cheaper stages.

## Memory as Verification

Before acting on a remembered rule:
1. Check: does the file/function/pattern still exist in code?
2. If memory conflicts with current code → trust code
3. Update or delete stale memory

"The memory says X exists" ≠ "X exists now"
