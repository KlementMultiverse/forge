# Contract-Driven Agentic Execution (CDAE)

The 5-layer architecture that makes rules fire at the exact moment they matter — not globally, read once, then forgotten.

## The 5 Layers

```
Layer 1: CONTRACTS (define invariants)
         ↓ "what must not break"
Layer 2: HOOKS (enforce at runtime)
         ↓ reads contracts, intercepts actions
Layer 3: SPECIALIST ROUTING (orchestrate)
         ↓ PM decomposes, routes to domain agents
Layer 4: JUDGE (evaluate in fresh context)
         ↓ per-agent reviewer, unbiased by implementation
Layer 5: GATES (macro process checkpoints)
         ↓ /gate blocks until CodeRabbit approves
```

## Why This Works

> "Rules are most effective when they fire locally — at the exact moment they matter — not globally."

- Layer 1 alone (contracts in docs) = 82.5% accuracy (models drift)
- Layer 1+2 (contracts + hooks) = 100% accuracy + 66% fewer tokens than SOPs
- Layer 1+2+3+4+5 = full enforcement across multi-agent workflows

## How Forge Implements Each Layer

### Layer 1: Contracts
- `rules/universal.md` — universal rules with governance levels
- `rules/{stack}.md` — stack-specific rules
- `playbook/strategies.md` — learned strategies with counters
- `docs/constitution.md` — 10 articles, single source of truth

### Layer 2: Hooks (Runtime Enforcement)
- `hooks/hooks.json` — PreToolUse blocks destructive ops, detects secrets, enforces TDD
- PostToolUse auto-formats, checks debt, reminds sync
- SessionStart loads contracts automatically

### Layer 3: Specialist Routing
- PM orchestrator synthesizes before delegating
- Agent selection by domain (agents/stacks/{stack}/)
- @agent-factory creates agents on demand
- Handoff protocol ensures reliable communication

### Layer 4: Judge (Fresh Context Evaluation)
- Per-agent domain judge (agents/universal/reviewer.md)
- Rates output 1-5 against task requirements
- Writes mini-retrospective for next attempt
- Unbiased: judge doesn't see implementation context

### Layer 5: Gates (Process Checkpoints)
- `/gate` at every stage boundary
- CodeRabbit reviews PR → 0 suggestions required
- `/checkpoint` evaluates agent output quality
- `/audit-patterns` runs 170+ pattern checks

## The Key Insight

Each layer addresses a different failure mode:
- Contracts fail: models forget rules mid-session → Hooks enforce at point of action
- Hooks fail: only catch tool calls, not reasoning → Judges evaluate output quality
- Judges fail: biased by shared context → Fresh context evaluation
- Gates fail: only check at boundaries → Hooks + judges check continuously
- Together: multi-layered defense — no single point of failure
