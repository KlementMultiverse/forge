# Forge

Autonomous software development framework built on Claude Code. One command builds production-grade applications through a 57-step pipeline with mechanical enforcement, agent separation, and self-improving playbooks.

```bash
./install.sh
# then in any project:
/forge "build a clinic management portal"
```

---

## Install

```bash
# 1. Install forge (once)
git clone https://github.com/KlementMultiverse/forge.git
cd forge
./install.sh

# 2. Start a new project
mkdir ~/projects/my-app
cd ~/projects/my-app
git init
claude
# type /forge at the prompt
```

What gets installed (to `~/.claude/`, shared by all projects):

| Component | Count | Location | Purpose |
|-----------|-------|----------|---------|
| Agents | 53 | ~/.claude/agents/ | Specialist AI agents (backend, security, reviewer, etc.) |
| Commands | 45 | ~/.claude/commands/ | Slash commands (/forge, /discover, /gate, sc:*, etc.) |
| Rules | 8 | ~/.claude/rules/ | Global rules (security, python, docker, PM behaviors, etc.) |
| Scripts | 31 | ~/.claude/scripts/ | Enforcement, traceability, ownership, testing |
| Templates | 22 | ~/.claude/templates/ | Project scaffolding (CLAUDE.md, SPEC.md, hooks, etc.) |
| Tests | 438 | tests/ | BATS + pytest test suite (100% script coverage) |
| Shell fn | 1 | ~/.bashrc / ~/.zshrc | `forge` terminal command |

---

## How It Works

### The Main Loop

```
Session starts
    |
    v
SessionStart hook (once per session)
  - Checks gh CLI installed + authenticated
  - Checks GitHub/GitLab remote configured
  - Checks CLAUDE.md < 40K chars
    |
    v
You type /forge
    |
    v
UserPromptSubmit hook (gated on /forge)
  - Detects project type (GREENFIELD / BROWNFIELD / EXISTING / RESUME)
  - Syncs forge-state.json
    |
    v
forge.md routes to correct phase file
  - forge-state.json exists  -> RESUME from current step
  - No CLAUDE.md             -> phase-a-setup.md (new project)
  - Steps 1-19               -> phase-0-2-plan.md (plan)
  - Steps 20-39              -> phase-3-implement.md (build)
  - Steps 40-56              -> phase-4-5-validate.md (verify)
  - Special cases (2-8)      -> cases.md
    |
    v
Phase file executes steps sequentially
  - Each step: skill (/discover) or agent (@backend-architect)
  - PostToolUse hook auto-updates forge-state.json
  - Trace saved per step (input.md + output.md + meta.md)
    |
    v
At phase boundary -> /gate
  - Observer approval required
  - CodeRabbit approval required (MANDATORY)
  - Suspect REQs must be cleared
  - Review guard must pass
  - Circuit breaker prevents endless polling
    |
    v
Continue to next phase automatically
```

### Phase A: Setup (New Projects Only)

PM asks 7 questions one at a time, then spawns agents:

```
@system-architect     -> CLAUDE.md (project rules, <100 lines)
@requirements-analyst -> SPEC.md (requirements with [REQ-xxx] tags)
PM                    -> FORGE.md (work queue)
@system-architect     -> .claude/rules/ (agent routing, SDLC flow)
@devops-architect     -> scaffold (Dockerfile, settings, pyproject.toml)
PM                    -> hooks, playbook, docs structure
@reviewer             -> review all files (rate >= 4)
```

### Phase 0: Genesis (Steps 1-8)

| Step | Command | Output |
|------|---------|--------|
| 1 | /discover | Domain research report |
| 2 | /requirements | 15+ requirements extracted |
| 3 | /feasibility | Tech stack validated |
| 4 | /generate-spec | Full SPEC.md with [REQ-xxx] |
| 5 | /challenge | Stress-test spec (PROCEED/REFINE/RETHINK) |
| 6 | /bootstrap | Project scaffold (manage.py, Docker, etc.) |
| 7 | /checkpoint | Self-review |
| 8 | /gate phase-0 | Observer + CodeRabbit approval |

### Phase 1: Specify (Steps 9-11)

| Step | Command | Output |
|------|---------|--------|
| 9 | /specify | Detailed proposal with Given/When/Then |
| 10 | /checkpoint | Self-review |
| 11 | /gate stage-1 | Approval |

### Phase 2: Architect (Steps 12-19)

| Step | Command | Output |
|------|---------|--------|
| 12 | /plan-review | Product + architecture review |
| 13 | @api-architect | API contracts (method, path, JSON shapes) |
| 14 | /design-doc | 10-section design document |
| 15 | /plan-tasks | GitHub issues from design doc |
| 16 | /sc:estimate | Effort estimates |
| 17 | /sc:workflow | Dependency ordering |
| 18 | /checkpoint | Self-review |
| 19 | /gate stage-2 | Approval |

### Phase 3: Implement (Steps 20-39)

Per-issue TDD with strict agent separation:

```
For EACH issue (in dependency order):

  N0: @backend-architect    -> task design doc
  N1: @context-loader       -> fetch library docs (context7 MCP)
  N2: @requirements-analyst -> add [REQ-xxx] to SPEC.md
  N3: @quality-engineer     -> write tests from SPEC (must FAIL)
  N4: @domain-agent         -> write code (must make tests PASS)
  N5: (automatic)           -> ruff lint (PostToolUse hook)
  N6: traceability.sh       -> 100% REQ coverage
  N7: @security-engineer    -> security review
  N8: @reviewer             -> rate 1-5 (must be >= 4)
  N9: git commit            -> one commit per issue

Rules:
  - TEST agent reads SPEC only (never code)
  - CODE agent reads SPEC + tests + design doc
  - PM NEVER writes app code
  - Each issue = one commit
```

Then: /review (step 37) -> /checkpoint (38) -> /gate stage-3 (39)

### Phase 4: Validate (Steps 40-46)

| Step | Command | What |
|------|---------|------|
| 40 | /sc:analyze | Code quality analysis |
| 41 | /audit-patterns | Pattern compliance (>90%) |
| 42 | /sc:test | Full test suite + coverage |
| 43 | traceability.sh | 100% REQ coverage check |
| 44 | /security-scan | OWASP top 10 audit |
| 45 | /design-audit | UI/UX + e2e tests |
| 46 | /gate stage-4 | Approval |

### Phase 5: Review + Learn (Steps 47-56)

| Step | Command | What |
|------|---------|------|
| 47 | /sc:cleanup | Remove dead code |
| 48 | /sc:improve | Apply improvements |
| 49 | /retro | Retrospective -> lessons to CLAUDE.md |
| 50 | /sc:reflect | Validate completion |
| 51 | /sc:document | Generate docs + DEPLOY.md |
| 52 | @playbook-curator | Update playbook counters |
| 53 | /prune + /evolve | Remove bad rules, cluster good ones |
| 54 | /autoresearch | Improve agent prompts |
| 55 | /sc:save | Persist session |
| 56 | /gate stage-5 | Final gate -> MERGE PR |

### Phase 6: Iterate (Step 57)

Check FORGE.md for queued items. Loop or done.

---

## Hooks (Mechanical Enforcement)

9 hook groups across 5 events. Hooks are 100% reliable (not prompt-based).

| Hook | Event | What It Does |
|------|-------|-------------|
| 1 | SessionStart | gh CLI check + auth check + remote check + CLAUDE.md char warning (once per session) |
| 2 | Stop | Gate check + auto-continue between steps |
| 3 | UserPromptSubmit | State sync + project detection (gated on /forge only) |
| 4 | PreToolUse (Bash) | Blocks: rm -rf, git push --force, reset --hard, clean -f |
| 5 | PreToolUse (Edit) | Warns when removing >10 lines + shows IMPACT for REQ-linked files |
| 6 | PostToolUse (Write/Edit) | Runs ruff lint + warns if file >300 lines + FORGE TRACE reminder |
| 7 | PostToolUse (Agent) | Logs activity + updates forge-state.json |
| 8 | PostToolUse (Skill) | Logs activity + updates forge-state.json |
| 9 | PostToolUse (Bash) | Logs command to activity log |

Plus two git hooks:
- `commit-msg` — blocks commits without issue references (#N) and enforces conventional commit format with scope
- `pre-commit` — REQ impact analysis + forge-test-guard (detects untested script changes)

---

## State Tracking

```
docs/forge-state.json          <- current step, phase, gates, violations
docs/suspect-reqs.json         <- REQs flagged as suspect (cleared on triangle pass)
docs/forge-timeline.md         <- every action logged (audit trail)
docs/forge-trace/{NNN}-{step}/ <- full input/output per step (3 files each)
docs/.builder-activity.log     <- one-line log of every tool use
apps/{app}/OWNERS              <- per-directory code ownership (agent, REQs, reviewer)
```

### forge-state.json

```json
{
  "version": "1.1.0",
  "project": "my-app",
  "current_phase": 2,
  "current_step": 14,
  "event_seq": 42,
  "session_id": "7ed6e623",
  "status": "IN_PROGRESS",
  "phases": {
    "0": { "status": "DONE", "gate_passed": true },
    "1": { "status": "DONE", "gate_passed": true },
    "2": { "status": "IN_PROGRESS", "gate_passed": false }
  },
  "retry_state": { "consecutive_failures": 0 },
  "gate_circuit": { "state": "CLOSED", "poll_count": 0 }
}
```

---

## Error Handling

### Error Types

| Type | Severity | Action |
|------|----------|--------|
| TEST_FAILED | HIGH | Investigate root cause first |
| LINT_FAILED | MEDIUM | Auto-fix then retry |
| GATE_BLOCKED | HIGH | Wait with circuit breaker |
| AGENT_FAILED | HIGH | Retry with better prompt (max 3) |
| DOCKER_UNHEALTHY | HIGH | Restart then retry |
| AUTH_EXPIRED | CRITICAL | Refresh credentials |
| RETRY_EXHAUSTED | CRITICAL | Stop and escalate |

### Retry Policy

Exponential backoff: 5s, 10s, 20s, 40s, 60s (capped). After 3 consecutive failures, escalates to RETRY_EXHAUSTED and stops.

### Circuit Breaker (Gate Polling)

```
CLOSED (polling) -> 5 polls, no change -> OPEN (5-min cooldown)
OPEN -> cooldown expires -> HALF-OPEN (single poll)
HALF-OPEN -> still blocked -> OPEN again
3 cooldown cycles -> ESCALATE (manual override needed)
```

---

## Key Scripts

```bash
# State management
forge-enforce.sh init <project>         # Initialize forge-state.json
forge-enforce.sh check-state            # Show current state
forge-enforce.sh check-continuation     # What's the next step?
forge-enforce.sh update-step <N> DONE   # Mark step complete
forge-enforce.sh update-gate <N>        # Mark gate passed
forge-enforce.sh full-audit             # Run all checks

# Error handling
forge-enforce.sh classify-error <ctx>   # Classify error type
forge-enforce.sh retry-track <N> fail   # Track failure with backoff

# Quality
forge-enforce.sh check-gate <phase>     # Gate passed?
forge-enforce.sh check-trace <step>     # Trace complete? (3 files)
forge-enforce.sh check-agent <file>     # Agent separation check
forge-enforce.sh check-docker           # Docker healthy?
forge-enforce.sh check-suspect          # Unverified suspect REQs?

# Traceability
forge-registry.py                       # Full registry (deps, phases, flows, changelog)
forge-registry.py --impact <file>       # What breaks if I change this file?
forge-registry.py --changelog           # Changelog from conventional commits
forge-registry.py --changelog --breaking # Breaking changes only
forge-ownership.sh check               # Show all code ownership
forge-ownership.sh who <file>          # Who owns this file?
forge-trace-update.sh show <file>      # Show in-file change history

# Validation
forge-lint.py                           # Lint all forge components
forge-lint.py --update-registry         # Update checksums
```

---

## Project Structure

```
forge/
  agents/
    universal/          <- 33 stack-agnostic agents
    stacks/             <- 17 stack-specific agents (django, genai, langchain, azure, gcp)
  commands/
    forge.md            <- main entry point (/forge)
    forge-phases/       <- 6 phase execution files (+ cases.md for special flows)
    *.md                <- skill commands (/discover, /gate, /review, sc:*, etc.)
  rules/                <- global rules (security, python, docker, etc.)
  scripts/              <- enforcement + traceability + testing scripts
  templates/            <- project templates (CLAUDE.md, SPEC.md, hooks, etc.)
  tests/
    bash/unit/          <- BATS unit tests (one per script)
    bash/integration/   <- BATS integration tests (hooks, flows)
    python/unit/        <- pytest tests
    test_helper/        <- shared fixtures + BATS helpers
    Makefile            <- test-fast, test-slow, test-all
  docs/
    automation-field-guide.md  <- 880+ lines: everything about building on Claude Code
    protocols/                 <- formal protocols (error handling, component creation)
    architecture.md            <- system map
    dependency-graph.md        <- auto-generated Mermaid dependency diagram
    evolution-log.md           <- decision history
  forge-core.json       <- component registry (checksums, protocols)
  forge-registry.json   <- full traceability (deps, phases, 9 flows, changelog, ownership)
  install.sh            <- one-command installer
```

---

## Observer Mode

Two terminals, two Claude Code sessions:

```bash
# Terminal 1: Builder (runs /forge)
cd ~/projects/my-app && claude

# Terminal 2: Observer (monitors in real-time)
forge observe my-app
```

Observer reviews artifacts as they're created. Gate checks require observer approval.

---

## Two Pipes (Core Concept)

Claude Code reads files through two different pipes:

**Pipe 1 (Auto-load):** CLAUDE.md and .claude/rules/*.md are automatically loaded. Frontmatter and block HTML comments are STRIPPED before the LLM sees them.

**Pipe 2 (Read tool):** When an agent explicitly reads a file, it gets the RAW content including comments and placeholders.

This is why templates use `{{PLACEHOLDERS}}` inside HTML comments — invisible to auto-load (no context poisoning), but visible to agents who read them explicitly.

---

## Requirements

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)
- Git + GitHub or GitLab (`gh` CLI for issues and PRs)
- Python 3.10+ (for enforcement scripts)
- Required: [CodeRabbit](https://coderabbit.ai) — used for PR review, architecture decisions, design review, issue review, edge case identification. Gates block without CR approval.
- Optional: context7 MCP server (for library docs)

---

## Documentation

| Document | What |
|----------|------|
| [Field Guide](docs/automation-field-guide.md) | 880+ lines: patterns, anti-patterns, Claude Code internals |
| [Error Protocol](docs/protocols/error-handling.md) | Error types, retry policy, circuit breaker, escalation |
| [Architecture](docs/architecture.md) | System map, dependency graph, component connections |
| [Dependency Graph](docs/dependency-graph.md) | Auto-generated Mermaid diagram of all component relationships |
| [Evolution Log](docs/evolution-log.md) | Every decision tracked with rationale |
| [Component Protocols](docs/protocols/component-creation.md) | Step-by-step for creating scripts, commands, agents, hooks, tests |

---

## License

Private. Contact KlementMultiverse for access.
