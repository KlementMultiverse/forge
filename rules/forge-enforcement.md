# Forge Enforcement — Global Rules (ALL Projects)

<system-reminder>
These rules apply to ANY project using /forge or /build-project.
They are NON-NEGOTIABLE. Violating any rule is a BLOCKING error.
</system-reminder>

## Enforcement Scripts (Global)

All scripts are at `~/.claude/scripts/` and auto-detect project root:

```bash
# State tracking
~/.claude/scripts/forge-enforce.sh init <project>       # New project
~/.claude/scripts/forge-enforce.sh check-state           # Current state
~/.claude/scripts/forge-enforce.sh check-continuation    # Next step (ALL phases 0-6)
~/.claude/scripts/forge-enforce.sh update-step <N> DONE  # Mark step done
~/.claude/scripts/forge-enforce.sh update-gate <N>       # Mark gate passed

# Quality checks
~/.claude/scripts/forge-enforce.sh check-gate <phase>    # Gate passed?
~/.claude/scripts/forge-enforce.sh check-trace <step>    # Trace complete?
~/.claude/scripts/forge-enforce.sh check-agent <file>    # Agent separation?
~/.claude/scripts/forge-enforce.sh check-docker          # Docker healthy?
~/.claude/scripts/forge-enforce.sh full-audit            # All checks

# Docker awareness
~/.claude/scripts/docker-state.sh                        # Capture state
~/.claude/scripts/docker-state.sh --check                # Health check
~/.claude/scripts/docker-state.sh --cleanup              # Remove orphans
```

## The 10 Hard Rules

### 1. STATE FILE — every forge project MUST have `docs/forge-state.json`
On `/forge` for new project → run `forge-enforce.sh init`
On every step → run `forge-enforce.sh update-step`
On session start → run `forge-enforce.sh check-state`

### 2. GATES CANNOT BE SKIPPED
Before Phase N → `forge-enforce.sh check-gate <N-1>` MUST pass.
If not → run `/gate phase-<N-1>` first. NEVER proceed without gate.

### 3. CHECKPOINTS CANNOT BE SKIPPED
After every phase's last step (before gate) → run `/checkpoint`.

### 4. AGENT SEPARATION IS MANDATORY
PM NEVER writes app code. Always spawn specialist agents.
`forge-enforce.sh check-agent <file>` blocks violations.

### 5. TRACES MUST BE COMPLETE (3 files per step)
Every step → `docs/forge-trace/{NNN}-{step}/input.md + output.md + meta.md`
`forge-enforce.sh check-trace <step>` verifies.

### 6. DOCKER STATE BEFORE INFRA WORK
Before any Docker changes → `docker-state.sh`
If healthy → skip recreation. Include state in agent prompts.

### 7. AUTO-CONTINUATION IS MANDATORY
NEVER stop to ask "should I continue?" — always continue.
NEVER ask which agent to use — consult agent-routing.md.
ONLY stop for: gate BLOCKED, /challenge RETHINK, missing credentials, 3 failed retries.

### 8. TDD IS MANDATORY IN PHASE 3
Tests first (FAIL) → Code (PASS) → Full suite (no regressions).

### 9. PER-ISSUE COMMITS
Each issue = one commit. NEVER batch multiple issues.

### 10. ALL 6 PHASES MUST COMPLETE
The forge flow has 57 steps across 7 phases (0-6).
`forge-enforce.sh check-continuation` shows ALL remaining steps.
NEVER consider a project "done" until Phase 5 gate passes.

### 11. /review BEFORE /gate, /review BEFORE PR
Architectural flow: `code → /review → fix → commit → /gate → PR`
NEVER create PR or run gate without inline review first.
Two levels: per-issue @reviewer (rate >=4) + phase-level `/review` (0 critical/high).

## Phase Map (for reference)

| Phase | Steps | Gate | Purpose |
|-------|-------|------|---------|
| 0 Genesis | 1-8 | /gate phase-0 | discover → requirements → feasibility → spec → challenge → bootstrap |
| 1 Specify | 9-11 | /gate stage-1 | /specify → checkpoint → gate |
| 2 Architect | 12-19 | /gate stage-2 | plan-review → api-architect → design-doc → plan-tasks → estimate → workflow |
| 3 Implement | 20-39 | /gate stage-3 | Per-issue: design → context → spec → test(FAIL) → code(PASS) → lint → sync → security → review → commit |
| 4 Validate | 40-46 | /gate stage-4 | analyze → audit → test+coverage → traceability → security → design-audit + e2e |
| 5 Review+Learn | 47-56 | /gate stage-5 | cleanup → improve → retro → reflect → document → playbook → prune → autoresearch → save → MERGE |
| 6 Iterate | 57 | — | Check queue → loop or done |
