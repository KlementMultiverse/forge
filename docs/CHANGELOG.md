# Forge Changelog

## 2026-04-04 — Major Release: Stack Registry, Enforcement, Observer

### Problems Found (from forge-ops build)
1. Builder ignored 77% of state update instructions (forge.md too long)
2. Builder stopped between phases asking "should I continue?"
3. Observer flagged violations for wrong phase (not phase-aware)
4. Observer never ran reviewer (instructions too passive)
5. No CodeRabbit integration (no git remote)
6. forge-state.json always stale (never updated)
7. Tests dumped into one 1947-line file
8. Docker scaffold missing volume mounts
9. Global rules loaded for wrong tech stacks
10. Hardcoded GitHub paths broke non-clinical-assistant projects
11. File I/O bugs in state sync
12. Phase mapping duplicated in 4 scripts

### Solutions Implemented

#### Architecture Changes
- **Decomposed forge.md**: 1420 → 120 lines. Phase files loaded on demand.
- **Auto-state hooks**: PostToolUse hooks auto-update forge-state.json (no manual calls needed)
- **Stack registry**: Per-tech-stack rules, agents, scaffold, learnings at ~/.claude/stacks/
- **Observer review protocol**: Script-driven (forge-observer-check.sh), not instruction-driven
- **Phase gate**: Explicit approval required from observer + CodeRabbit between phases

#### Scripts Created
| Script | Purpose |
|--------|---------|
| forge-auto-state.sh | Maps skill/agent names to step numbers, auto-updates state |
| forge-phase-gate.sh | Checks observer approval + CodeRabbit before phase transition |
| forge-observer-check.sh | Detects new files needing review each cycle |
| forge-observer-approve.sh | Explicit phase approval (check → approve → reject) |
| forge-state-sync.sh | Fixes stale state from git/file artifacts |
| forge-phase-map.sh | Single source of truth for step→phase mapping |
| forge-deps.sh | Checks required tools (python3, git, jq) on startup |
| forge-stack.sh | Create/list/manage tech stack registries |
| forge-handshake.sh | Builder↔observer file-based communication |

#### Hooks Added
| Hook | Event | Purpose |
|------|-------|---------|
| Stop | Every pause | Phase gate check + auto-continue + observer feedback |
| PostToolUse(Skill) | After /skill | Auto-state update + activity log |
| PostToolUse(Agent) | After agent | Auto-state update + activity log |
| PostToolUse(Write/Edit) | After file change | Activity log + ruff lint + 300-line warning |
| PostToolUse(Bash) | After command | Activity log |
| PreToolUse(Edit) | Before edit | Warns when removing 10+ lines |
| PreToolUse(Bash) | Before command | Blocks destructive ops (rm -rf, force push) |
| UserPromptSubmit | Every prompt | State sync + case detection |

#### Rules Changes
- django.md, python.md, docker.md: Added `paths:` frontmatter (only load for matching projects)
- docker.md: NEW — volume mounts, dev vs prod, .dockerignore rules
- Phase 3 prompt: Tests go in domain-specific files (tests_models.py, not tests.py)

#### Bug Fixes
- forge-fsm.sh: Hardcoded `KlementMultiverse/clinical-assistant` → dynamic repo detection
- forge-state-sync.sh: File I/O crash → proper `with` context managers
- forge-observer-check.sh: Broken `find -o` precedence → parentheses grouping
- forge-phase-map.sh: Phase mapping deduplicated from 4 scripts → 1 shared file
- forge-deps.sh: Silent tool failures → explicit error messages
- .bashrc: Observer prompt syntax errors from unescaped quotes
- forge.md: REQ pattern `REQ-\d+` → `REQ-[A-Z]+-[0-9]+` for domain-prefixed IDs

### Metrics
- forge-ops build: 138 tests, 98% coverage, 51 REQs traced, 14 commits
- State tracking: 22.8% → 100% coverage (auto via hooks)
- forge.md: 1420 → 120 lines (12x reduction)
- Scripts: 14 total, all tested
- Stack learnings: 7 Django entries from 2 builds
