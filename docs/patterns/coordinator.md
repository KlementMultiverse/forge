# Coordinator Pattern

The PM Orchestrator follows the coordinator pattern: synthesize before delegating.

## How It Works

```
User request arrives
    ↓
PM READS and UNDERSTANDS (never delegates understanding)
    ↓
PM SYNTHESIZES findings into specific task descriptions
    ↓
PM DELEGATES to specialist agents with:
  - Exact task description (not "figure it out")
  - Relevant context (spec sections, code files)
  - Expected output format
  - Success criteria
    ↓
Agent executes in FRESH context (can't see main conversation)
    ↓
PM RECEIVES result and integrates
```

## Rules

1. **Synthesize before delegating** — PM must prove understanding before spawning workers
2. **Fresh context per worker** — agents get clean context, not polluted main session
3. **Research: parallel** — independent research tasks can run simultaneously
4. **Implementation: sequential per file** — avoid write conflicts
5. **Verification: fresh worker** — use clean eyes, avoid anchoring on implementation
6. **Max retries: 3** — bounded, not infinite
