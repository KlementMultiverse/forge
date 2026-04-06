# Forge Architecture Reference

How all the pieces connect. Read this before changing anything.

---

## System Map

```
FORGE REPO (~/projects/forge/)
│
├── agents/                    ── agent definitions
│   ├── universal/             ── stack-agnostic agents (32 files)
│   └── stacks/                ── stack-specific agents
│       ├── django/
│       ├── azure/
│       ├── gcp/
│       ├── genai/
│       └── langchain/
│
├── commands/                  ── skill/command definitions (37 files)
│   └── forge-phases/          ── phase execution files
│       ├── phase-a-setup.md   ── new project setup (Session 1)
│       ├── phase-0-2-plan.md  ── genesis → specify → architect
│       ├── phase-3-implement.md ── per-issue TDD implementation
│       ├── phase-4-5-validate.md ── validate + review + learn
│       ├── cases.md           ── special case routing
│       └── tracking.md        ── timeline tracking rules
│
├── rules/                     ── global rule files (7 files)
│
├── scripts/                   ── bash/python automation (20 files)
│
├── templates/                 ── project templates + hooks
│   ├── hooks.json             ── THE hooks file (8 hooks, project-level)
│   ├── CLAUDE.template.md     ── CLAUDE.md skeleton (placeholders in comments)
│   ├── SPEC.template.md       ── SPEC.md skeleton
│   ├── rules/
│   │   ├── sdlc-flow.md       ── SDLC stages template
│   │   └── agent-routing.md   ── agent matrix template
│   └── [other templates]
│
├── docs/                      ── forge's own documentation
│   ├── architecture.md        ── THIS FILE
│   ├── evolution-log.md       ── all decisions + session history
│   └── automation-field-guide.md ── reusable lessons ("the guide")
│
└── install.sh                 ── installer (copies to ~/.claude/)
```

## Installation Flow

```
./install.sh                       ./install.sh ~/projects/my-app
     │                                  │
     ▼                                  ▼
copies to ~/.claude/:              checks if forge installed
  agents/*.md                      if not → runs install_global()
  commands/*.md                    then:
  commands/forge-phases/*.md         mkdir ~/projects/my-app
  rules/*.md                        git init
  scripts/*                         prints "cd there, run /forge"
  templates/*
```

**Extensibility:** All copies use glob patterns (`*.md`, `*.sh`). Adding a new agent/command/rule/script file automatically gets picked up on next `./install.sh`. No code changes needed.

**Exception:** Templates subdirectories must be explicitly handled. If you add `templates/new-subdir/`, update install.sh to copy it.

## Where Things Live After Install

```
~/.claude/                         (GLOBAL — shared across all projects)
├── agents/           ← agent definitions (loaded by Agent tool)
├── commands/         ← skill definitions (loaded as /slash commands)
│   └── forge-phases/ ← phase execution files (read by /forge)
├── rules/            ← global rules (auto-loaded in all projects via Pipe 1)
│   ├── pm-behaviors.md    ← PM orchestrator behaviors (self-correction, anti-patterns, handoff)
│   ├── forge-enforcement.md ← hard rules for forge flow
│   ├── security.md        ← security rules
│   ├── universal.md       ← universal rules with governance levels
│   ├── python.md, django.md, docker.md, forge-philosophy.md
├── scripts/          ← automation scripts (called by hooks)
└── templates/        ← project templates (read by Phase A)

Architecture separation (who vs what):
  rules/pm-behaviors.md           → WHO: PM behaviors (auto-loaded, ~100 lines)
  agents/universal/pm-orchestrator.md → REFERENCE: routing tables, detailed patterns
  commands/forge-phases/*.md      → WHAT: task steps for each phase

~/projects/my-app/                 (PROJECT — created by /forge Phase A)
├── CLAUDE.md         ← project instructions (auto-loaded, Pipe 1)
├── SPEC.md           ← requirements with [REQ-xxx] tags
├── FORGE.md          ← work queue
├── .claude/
│   ├── rules/        ← project-specific rules (auto-loaded, Pipe 1)
│   │   ├── sdlc-flow.md
│   │   └── agent-routing.md
│   └── settings.json ← hooks (auto-loaded, runs mechanically)
├── .forge/
│   ├── playbook/     ← self-improving knowledge base
│   │   ├── strategies.md
│   │   ├── mistakes.md
│   │   └── archived.md
│   ├── rules/        ← project-only rules
│   └── checkpoints/  ← ephemeral (gitignored)
├── docs/
│   ├── forge-state.json    ← step tracking (created during build)
│   ├── forge-timeline.md   ← audit trail
│   ├── forge-trace/        ← per-step input/output/meta
│   ├── .builder-activity.log ← hook activity log
│   ├── proposals/
│   ├── retrospectives/
│   ├── checkpoints/
│   └── issues/
└── scripts/
    ├── traceability.sh
    └── sync-report.sh
```

## Dependency Map

When you change something, here's what else you need to check:

### If you ADD a new hook:

```
1. Edit: templates/hooks.json              ← add the hook
2. Check: does hook reference a script?
   YES → verify script exists in scripts/
         verify install.sh glob picks it up (*.sh or *.py)
3. Check: does hook produce output the LLM reads?
   YES → document the output format in this file
4. Re-run: ./install.sh                    ← update global copy
5. Re-init: for existing projects, manually copy .claude/settings.json
```

### If you ADD a new agent:

```
1. Create: agents/universal/my-agent.md    ← or agents/stacks/{stack}/
2. Re-run: ./install.sh                    ← glob auto-picks it up
3. Update: templates/rules/agent-routing.md ← add to examples
4. Update: commands/forge-phases/phase-a-setup.md Step S6 ← add to routing mappings
```

### If you ADD a new command/skill:

```
1. Create: commands/my-command.md
2. Re-run: ./install.sh                    ← glob auto-picks it up
3. If it's a forge phase step:
   → Update the relevant phase file in commands/forge-phases/
   → Update scripts/forge-auto-state.sh with skill→step mapping
```

### If you ADD a new script:

```
1. Create: scripts/my-script.sh
2. Re-run: ./install.sh                    ← glob auto-picks it up
3. If hooks call it → already referenced by path ~/.claude/scripts/
4. If Phase A calls it → update phase-a-setup.md
```

### If you ADD a new template:

```
1. Create: templates/my-template.md
2. Re-run: ./install.sh                    ← glob auto-picks it up
3. Update: Phase A or relevant command to USE the template
```

### If you ADD a new rule:

```
1. Create: rules/my-rule.md               ← global (all projects)
   OR: templates/rules/my-rule.md         ← per-project (copied by Phase A)
2. If global: re-run ./install.sh
3. If per-project: update Phase A Step S6 to copy it
```

### If you CHANGE install.sh:

```
1. Test: ./install.sh (global only)
2. Test: ./install.sh ~/projects/test-dir (with dir)
3. Verify: all globs still match (ls ~/.claude/agents/*.md etc.)
4. Verify: scripts are executable (chmod +x)
```

### If you CHANGE Phase A:

```
1. Test: create empty dir, run /forge
2. Verify: all files created (.claude/, .forge/, docs/, scripts/)
3. Verify: hooks.json is valid JSON with 8 hooks
4. Verify: no context poisoning (check CLAUDE.md for raw placeholders)
```

## Hook Reference

All 8 hooks in templates/hooks.json:

| # | Event | Matcher | Purpose | Calls Script? | Produces Output? |
|---|-------|---------|---------|---------------|-----------------|
| 1 | Stop | (all) | Phase gate check + auto-continue | `forge-phase-gate.sh` | `[FORGE] GATE CLEAR/WAIT/BLOCKED/AUTO-CONTINUE` |
| 2 | UserPromptSubmit | (all) | Detect project type + sync state | `forge-state-sync.sh` | `[FORGE] CASE1/CASE2/.../CASE7` + `[FORGE-SYNC] N REQs` |
| 3 | PreToolUse | Bash | Block destructive commands | — | `[FORGE] BLOCKED` + exit 2 |
| 4 | PreToolUse | Edit | Warn on large deletions (>10 lines) | — | `[FORGE] WARNING: Removing N lines` |
| 5 | PostToolUse | Write\|Edit | Ruff lint + 300-line check + log | — | `[FORGE] FILE TOO LONG` (if >300) |
| 6 | PostToolUse | Agent | Log agent + update forge state | `forge-auto-state.sh` | Activity log entry |
| 7 | PostToolUse | Skill | Log skill + update forge state | `forge-auto-state.sh` | Activity log entry |
| 8 | PostToolUse | Bash | Log command | — | Activity log entry |

**To add a new hook:** Edit templates/hooks.json, update this table, re-run install.sh.

## Script Reference

Scripts called by hooks (must exist at `~/.claude/scripts/`):

| Script | Called by | Purpose |
|--------|----------|---------|
| `forge-auto-state.sh` | PostToolUse (Agent, Skill) | Maps agent/skill names to step numbers, updates forge-state.json |
| `forge-phase-gate.sh` | Stop hook | Checks observer + CodeRabbit approval at phase boundaries |
| `forge-state-sync.sh` | UserPromptSubmit | Detects actual progress from artifacts, fixes stale state |

Scripts used by commands (not hooks):

| Script | Used by | Purpose |
|--------|---------|---------|
| `forge-enforce.sh` | /forge, /gate, rules | State management (init, check, update steps/gates) |
| `forge-stack.sh` | Phase A Step S2 | List/create stack registries |
| `forge-triangle.sh` | /audit-patterns | Spec ↔ test ↔ code sync check |
| `traceability.sh` | /gate, Phase 4 | REQ traceability matrix |
| `sync-report.sh` | /gate | Full sync report |
| `docker-state.sh` | Phase 3 | Docker health check before infra work |

## Template Reference

Templates read by Phase A (must exist at `~/.claude/templates/`):

| Template | Used in | Purpose |
|----------|---------|---------|
| `hooks.json` | Phase A Step S8 | Copied to project .claude/settings.json |
| `CLAUDE.template.md` | Phase A Step S3 | Structure reference for @system-architect (in HTML comments) |
| `SPEC.template.md` | Phase A Step S4 | Structure reference for @requirements-analyst |
| `rules/sdlc-flow.md` | Phase A Step S6 | SDLC stages template |
| `rules/agent-routing.md` | Phase A Step S6 | Agent matrix template |

## Auto-Loaded Files (Pipe 1 — context sensitive)

These files are automatically injected into LLM context. Changes here directly affect model behavior:

| File | Scope | When loaded |
|------|-------|-------------|
| `~/.claude/CLAUDE.md` | Global | Always (all projects) |
| `~/.claude/rules/*.md` | Global | Always (all projects) |
| `PROJECT/CLAUDE.md` | Project | Always (in that project) |
| `PROJECT/.claude/rules/*.md` | Project | Path-matched (frontmatter `paths:` field) |

**Rule:** Never put raw {{placeholders}} or fake instructions in these files. Use HTML comments.

## Files NOT Auto-Loaded (Pipe 2 — explicit read only)

| File | How accessed |
|------|-------------|
| `SPEC.md` | Agent reads via Read tool |
| `FORGE.md` | Agent reads via Read tool |
| `.forge/playbook/*` | Agent reads via Read tool |
| `docs/*` | Agent reads via Read tool |
| `templates/*` | Agent reads via Read tool |
| `scripts/*` | Executed via Bash tool |

---

*Update this document when adding new components. It's the map — if it's wrong, people get lost.*
