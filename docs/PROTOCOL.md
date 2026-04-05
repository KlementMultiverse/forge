# Forge Protocol — How to Run a Build

## Prerequisites

```bash
# Required tools
python3 --version   # 3.10+
git --version       # any
jq --version        # any

# Optional (recommended)
gh --version        # GitHub CLI — for PRs + CodeRabbit
docker --version    # for containerized builds

# Install forge
git clone https://github.com/KlementMultiverse/forge.git ~/projects/forge
bash ~/projects/forge/install.sh
source ~/.bashrc
```

## Protocol 1: New Project Build

### Step 1: Start Builder
```bash
cd ~/projects/<project-name>   # or empty folder
forge                          # opens claude with --dangerously-skip-permissions
```
Then type: `/forge`

### Step 2: Start Observer (separate terminal)
```bash
source ~/.bashrc
forge observe                  # auto-detects project, opens claude with monitoring
```

### Step 3: What Happens Automatically

**Builder side:**
- Detects project state (new/existing/brownfield)
- Runs Phase A setup (CLAUDE.md, SPEC.md, scaffold)
- Runs Phases 0-5 (57 steps total)
- Auto-updates state via hooks (forge-auto-state.sh)
- Auto-continues between steps (Stop hook)
- WAITS at phase boundaries for observer + CodeRabbit approval

**Observer side:**
- Checks every 1 minute (via /loop 1m)
- Runs forge-observer-check.sh each cycle
- Detects new/changed key files
- Spawns reviewer agent to rate files 1-5
- Writes PHASE-N-APPROVED when all pass
- Builder unblocks and continues

**Hooks doing the work:**
- PostToolUse(Skill) → auto-state update + activity log
- PostToolUse(Agent) → auto-state update + activity log
- PostToolUse(Write/Edit) → lint + 300-line check + activity log
- PreToolUse(Edit) → warns on 10+ line deletions
- Stop → phase gate check → auto-continue or wait
- UserPromptSubmit → state sync + case detection

### Step 4: Phase Gate Protocol

At each phase boundary (steps 8, 11, 19, 39, 46, 56):

```
Builder finishes phase → Stop hook fires
  → forge-phase-gate.sh check
  → Checks observer: PHASE-N-APPROVED in reviews log?
  → Checks CodeRabbit: APPROVED on PR?
  ├─ Both approved → "GATE CLEAR — proceed"
  ├─ Observer reviewing → "WAIT — sleep 30"
  ├─ NEEDS_FIX → "BLOCKED — fix issues"
  └─ No PR → "WARNING — no CodeRabbit"
```

### Step 5: When Builder Stops

If builder stops unexpectedly:
```bash
cd ~/projects/<project-name> && forge
# /forge will detect state, resume from next step
```

### Step 6: When Build Completes

Builder outputs:
```
Forge complete.
- Tests: N passing
- Coverage: N%
- Traceability: N% REQ coverage
```

## Protocol 2: Adding a Stack

### Automatic (first use)
Pick an unknown stack during Q4 → forge auto-creates via forge-stack.sh

### Manual (pre-configure)
```bash
# Interactive — asks 10 questions
bash ~/.claude/scripts/forge-stack.sh create nextjs

# Auto — template files, refined on first build
bash ~/.claude/scripts/forge-stack.sh create golang --auto

# List all stacks
bash ~/.claude/scripts/forge-stack.sh list
```

### Stack Files
```
~/.claude/stacks/<name>/
├── rules.md       — stack-specific rules (copied to project)
├── agents.md      — agent routing template
├── scaffold.md    — scaffold instructions for @devops-architect
└── learnings.md   — accumulated from past builds (grows with /retro)
```

## Protocol 3: After Build — Retro & Learning

The build's /retro (Step 49) automatically:
1. Creates retrospective in docs/retrospectives/
2. Updates CLAUDE.md Lessons Learned
3. Appends stack-specific learnings to ~/.claude/stacks/<stack>/learnings.md

To manually add a learning:
```bash
bash ~/.claude/scripts/forge-stack.sh add-learning django "Always use select_related for FK queries"
```

## Protocol 4: Debugging Flow Issues

### Check current state
```bash
bash ~/.claude/scripts/forge-enforce.sh check-state
bash ~/.claude/scripts/forge-enforce.sh check-continuation
```

### Check observer status
```bash
bash ~/.claude/scripts/forge-phase-gate.sh status
cat docs/.observer-reviews.log | tail -10
```

### Fix stale state
```bash
bash ~/.claude/scripts/forge-state-sync.sh
```

### Check dependencies
```bash
source ~/.claude/scripts/forge-deps.sh && check_forge_deps
```

### Full audit
```bash
bash ~/.claude/scripts/forge-enforce.sh full-audit
```

## Protocol 5: Manual Testing Checklist

After changes to forge scripts, test each component:

```bash
# 1. Dependencies
source ~/.claude/scripts/forge-deps.sh && check_forge_deps

# 2. Phase mapping
source ~/.claude/scripts/forge-phase-map.sh
echo "Step 19 = Phase $(get_phase_for_step 19)"

# 3. State sync
bash ~/.claude/scripts/forge-state-sync.sh

# 4. Auto-state (skill mapping)
bash ~/.claude/scripts/forge-auto-state.sh "discover" "" ""
bash ~/.claude/scripts/forge-auto-state.sh "gate" "" "phase-0"
bash ~/.claude/scripts/forge-auto-state.sh "retro" "" ""

# 5. Observer check
bash ~/.claude/scripts/forge-observer-check.sh /path/to/project

# 6. Observer approval
bash ~/.claude/scripts/forge-observer-approve.sh check /path/to/project
bash ~/.claude/scripts/forge-observer-approve.sh approve /path/to/project

# 7. Phase gate
bash ~/.claude/scripts/forge-phase-gate.sh check
bash ~/.claude/scripts/forge-phase-gate.sh status

# 8. Stack management
bash ~/.claude/scripts/forge-stack.sh list
bash ~/.claude/scripts/forge-stack.sh create test-stack --auto
bash ~/.claude/scripts/forge-stack.sh show test-stack
rm -rf ~/.claude/stacks/test-stack  # cleanup
```

## File Map

```
~/.claude/
├── commands/
│   ├── forge.md                    (120 lines — router)
│   └── forge-phases/
│       ├── phase-a-setup.md        (Phase A — project setup)
│       ├── phase-0-2-plan.md       (Phases 0-2 — genesis/specify/architect)
│       ├── phase-3-implement.md    (Phase 3 — implementation)
│       ├── phase-4-5-validate.md   (Phases 4-5 — validate/review)
│       ├── cases.md                (Cases 2-8 — special flows)
│       └── tracking.md            (Timeline + trace format)
├── scripts/
│   ├── forge-enforce.sh            (state tracking, gates, full audit)
│   ├── forge-auto-state.sh         (hook: skill→step mapping)
│   ├── forge-phase-gate.sh         (observer + CodeRabbit approval)
│   ├── forge-observer-check.sh     (detect files needing review)
│   ├── forge-observer-approve.sh   (explicit phase approval)
│   ├── forge-state-sync.sh         (fix stale state from artifacts)
│   ├── forge-phase-map.sh          (shared step→phase mapping)
│   ├── forge-deps.sh               (tool dependency checker)
│   ├── forge-stack.sh              (stack registry manager)
│   ├── forge-fsm.sh                (deterministic state machine)
│   ├── forge-triangle.sh           (spec↔test↔code sync)
│   ├── forge-verify.sh             (artifact proof-of-execution)
│   ├── forge-grow.sh               (self-evolving growth engine)
│   ├── forge-review-guard.sh       (review before gate enforcement)
│   ├── forge-handshake.sh          (builder↔observer communication)
│   └── docker-state.sh             (Docker state capture)
├── stacks/
│   ├── django/                     (rules, agents, scaffold, learnings)
│   ├── fastapi/                    (rules, agents, scaffold, learnings)
│   └── README.md
├── observer/
│   └── review-criteria.md          (scoring rubric for reviewer)
├── rules/
│   ├── django.md                   (paths: manage.py, apps/**)
│   ├── python.md                   (paths: *.py)
│   ├── docker.md                   (paths: Dockerfile)
│   ├── security.md                 (paths: **)
│   ├── universal.md                (always loaded)
│   ├── forge-enforcement.md        (10 hard rules)
│   └── forge-philosophy.md         (deterministic flow + non-deterministic growth)
└── agents/
    ├── README.md                   (55 agents in 8 groups)
    ├── triangle-fixer.md
    ├── handoff-coordinator.md
    └── deploy-guide.md
```
