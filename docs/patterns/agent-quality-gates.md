# Agent Quality Gates — 5 Production Patterns

From research (Anthropic engineering, promptfoo, Scale AI). These 5 patterns are commonly missing from agent prompts and cause production failures.

## 1. Confidence Routing

Every agent output MUST include a confidence indicator:

```
CONFIDENCE: HIGH (>90%) — proceed automatically
CONFIDENCE: MEDIUM (60-90%) — present alternatives, let PM decide
CONFIDENCE: LOW (<60%) — STOP, ask user, do NOT proceed on assumption
```

**Why:** Without confidence routing, all agent outputs appear equally reliable. A hallucinated answer looks identical to a well-researched one.

**Where in Forge:** Every agent's handoff protocol should include a Confidence field.

## 2. Self-Correction Loop

Before finalizing output, every agent MUST review against its own rules:

```
SELF-CHECK:
□ Did I follow the Forge Cell steps?
□ Does my output match the handoff format?
□ Did I cite sources / [REQ-xxx] tags?
□ Are my anti-patterns violated? (check each NEVER rule)
□ Would my judge accept this? (rate myself 1-5)
```

**Why:** Agents that generate without reviewing produce 30% more errors. Self-correction catches the obvious ones before the judge.

## 3. Negative Instructions Placement

Place NEVER rules near the END of the prompt — models weight end-of-prompt instructions more heavily than middle.

```
# BAD: NEVER rules buried in the middle of a long prompt
# GOOD: Anti-patterns section is the LAST section before closing
```

**Why:** Context window attention is U-shaped — beginning and end get most attention. Middle gets ignored. Put critical guardrails at the edges.

## 4. Tool Failure Handling

Every agent MUST specify what happens when tools fail:

```
TOOL FAILURE PROTOCOL:
- context7 fails → use WebFetch on official docs URL
- Bash command fails → classify error, try different approach
- Web search returns nothing → broaden query, try synonyms
- All tools fail → report honestly: "Could not complete — [reason]"
- NEVER fabricate results when tools fail
```

**Why:** Tool calling fails 3-15% of the time in production. Without explicit failure handling, agents hallucinate results instead of admitting failure.

## 5. Chaos Resilience

Agent prompts MUST handle adversarial/edge inputs:

```
EDGE CASES TO HANDLE:
- Empty input → return error: "No input provided"
- Very long input → truncate or summarize before processing
- Conflicting instructions → ask for clarification, don't guess
- Malformed data → validate before processing
- Missing context (no SPEC.md, no CLAUDE.md) → report what's missing
```

**Why:** Happy-path testing hides fragility. Production inputs are messy, incomplete, and sometimes adversarial.

## Integration

These 5 patterns should be embedded in every agent's Forge Integration block. They complement the existing Forge Cell (which handles execution flow) with quality assurance (which handles output reliability).
