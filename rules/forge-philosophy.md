# Forge Philosophy — Deterministic Flow, Non-Deterministic Growth

## The Core Principle

The FLOW is deterministic: every step has a defined input, agent, artifact, and verification.
The GROWTH is non-deterministic: new agents, new steps, new groups emerge from each build.
But growth ALWAYS goes through the flow — propose → review → gate → merge.

## How It Works

```
DETERMINISTIC (fixed, reliable):
  - Phase sequence: 0→1→2→3→4→5→6
  - Gate before each phase transition
  - /review before /gate (hard block)
  - Triangle must sync (spec↔test↔code)
  - Artifact must exist to mark DONE
  - Per-issue commits, not monolithic

NON-DETERMINISTIC (grows with each build):
  - New agents created when @agent-factory detects a gap
  - New agent groups emerge when new domains appear
  - forge-manifest.json edited to add/remove/change steps
  - Playbook grows from /retro lessons
  - Prompts improve from /autoresearch
  - New tech suggested by @system-architect
  - New hooks added when violations are discovered
```

## The Growth Cycle

```
BUILD → finds a gap (missing agent, missing check, slow step)
  ↓
RETRO → captures the gap as a lesson
  ↓
PROPOSE → @agent-factory or @system-architect proposes fix
  ↓
REVIEW → /review or /challenge validates the proposal
  ↓
MERGE → fix enters forge-manifest.json or forge.md or new agent
  ↓
NEXT BUILD → gap is closed, new gaps may appear
  ↓
REPEAT → forge gets better every build
```

## Rules for Growth

1. **Everything in the flow**: no changes outside the gate/review cycle
2. **Manifest is the source of truth**: add steps, change agents, skip steps — all in forge-manifest.json
3. **Agents can propose, never decide**: proposals go through /review + consensus
4. **Universal first**: every new capability must work on any project, not just the current one
5. **Template-based**: new agents follow agent template, new steps follow manifest schema
6. **Measured**: execution rate, triangle sync, gate pass rate — numbers don't lie
7. **Immutable history**: violations are logged, never deleted — learn from them
