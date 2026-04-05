# Forge Evolution Log

Every decision, discovery, loose end, and improvement — tracked here.
Nothing gets lost. Updated every session.

---

## Goals

1. **Self-containing** — forge works out-of-the-box, no manual setup beyond install
2. **Flexible** — handles any tech stack, any project size, any governance level
3. **Scalable** — from solo MVP to enterprise multi-team
4. **No loose ends** — every phase tested, every edge case handled, system works even when things go wrong
5. **Eventually an assistant** — but first, get the foundation rock-solid

## Assumptions (to validate)

- [ ] `/forge "idea"` can run all 57 steps autonomously without human intervention
- [ ] `forge-state.json` enables reliable session resume at any step
- [ ] Agent routing works for any tech stack (not just Django/Python)
- [ ] Gates actually block — not just warn
- [ ] Hooks fire mechanically, independent of LLM memory
- [ ] Context handoff between PM and agents is clean and sufficient
- [ ] The system recovers gracefully from failures mid-phase
- [ ] Playbook self-improvement actually improves output quality over builds
- [ ] Triangle sync (spec ↔ test ↔ code) catches real drift
- [ ] Works on a fresh machine with just `./install.sh`

## Architecture Decisions

| # | Date | Decision | Why | Status |
|---|------|----------|-----|--------|
| 1 | 2026-04-04 | Improve forge in ~/projects/forge/, test in separate dirs | Keep framework and test projects isolated | Active |
| 2 | 2026-04-04 | Track ALL decisions in this doc | Nothing gets lost between sessions | Active |
| 3 | 2026-04-04 | Field guide (automation-field-guide.md) captures reusable lessons | Consolidated knowledge, not scattered across 50 files | Active |
| 4 | 2026-04-05 | Hooks are project-level only, not global | Forge hooks should only run in forge projects, not interfere with other repos | Active |
| 5 | 2026-04-05 | Single hooks file: templates/hooks.json (8 hooks) | One source of truth, no orphaned files | Active |
| 6 | 2026-04-05 | install.sh redesign: no more `init` subcommand | UX: one command installs, optional dir arg preps project. /forge Phase A creates everything | Active |
| 7 | 2026-04-05 | Phase A Step S8 creates all project infrastructure | Moved from install.sh init to /forge — single entry point for project setup | Active |
| 8 | 2026-04-05 | install.sh copies ALL scripts to ~/.claude/scripts/ | Hooks depend on forge-auto-state.sh, forge-phase-gate.sh, forge-state-sync.sh | Active |
| 9 | 2026-04-05 | install.sh copies templates to ~/.claude/templates/ | Phase A reads templates from there (not forge repo) | Active |

## Loose Ends (things to investigate/fix)

| # | Found | Description | Status | Resolved |
|---|-------|-------------|--------|----------|
| 1 | 2026-04-04 | Duplicate doc dirs (docs/retros/ + docs/retrospectives/) in install.sh init | Fixed | 2026-04-05 — install.sh init removed, Phase A creates only docs/retrospectives/ |
| 2 | 2026-04-05 | hooks split: templates/hooks.json (3 hooks) vs hooks/hooks.json (8 hooks, orphaned) | Fixed | 2026-04-05 — merged into single templates/hooks.json with all 8 hooks |
| 3 | 2026-04-05 | Global install skips settings.json if exists — never merges hooks | Fixed | 2026-04-05 — global install no longer touches settings.json; hooks are project-level only |
| 4 | 2026-04-05 | SPEC.template.md uses [] placeholders, agent-routing uses {{}} — inconsistent | Open | Low priority — doesn't cause poisoning since SPEC.md not auto-loaded |

## Improvements Made

| # | Date | What changed | Files touched | Impact |
|---|------|-------------|---------------|--------|
| 1 | 2026-04-04 | Fix context poisoning: template CLAUDE.md reduced to 3-line marker | templates/CLAUDE.template.md | Eliminates fake instructions from LLM context |
| 2 | 2026-04-04 | Fix context poisoning: sdlc-flow.md placeholder replaced with comment | templates/rules/sdlc-flow.md | No more {{SDLC_FLOW_CONTENT}} in LLM context |
| 3 | 2026-04-04 | Fix context poisoning: agent-routing.md placeholder replaced with comment | templates/rules/agent-routing.md | No more {{AGENT_MATRIX_ROWS}} in LLM context |
| 4 | 2026-04-05 | Merged hooks: 8 hooks in one file, deleted orphaned hooks/ dir | templates/hooks.json, hooks/hooks.json (deleted) | Projects get auto-continue, state tracking, activity logging |
| 5 | 2026-04-05 | Redesigned install.sh: removed init subcommand | install.sh | Single command UX: ./install.sh [optional-dir] |
| 6 | 2026-04-05 | install.sh now copies scripts + templates globally | install.sh | Hooks can find forge-auto-state.sh, Phase A can find templates |
| 7 | 2026-04-05 | Phase A Step S8 expanded: creates .forge/, playbook, docs, timeline, hooks | commands/forge-phases/phase-a-setup.md | /forge is now the single entry point for project creation |

## Phase-by-Phase Review Status

| Phase | Reviewed | Issues Found | Fixed | Notes |
|-------|----------|-------------|-------|-------|
| 0 Genesis | No | — | — | |
| 1 Specify | No | — | — | |
| 2 Architect | No | — | — | |
| 3 Implement | No | — | — | |
| 4 Validate | No | — | — | |
| 5 Review+Learn | No | — | — | |
| 6 Iterate | No | — | — | |

## Session Log

### Session 1 — 2026-04-04
- Cleaned up test projects (clinical_assistant, clinical-qa, forge-flow-test, forge-hook-test, forge-test-repos)
- Created automation-field-guide.md (consolidated lessons from all docs)
- Created this evolution-log.md
- **Next:** Start reviewing forge phase-by-phase, beginning with install.sh and Phase 0
- Tested `install.sh` (global install: 55 agents, 37 commands, 7 rules — works)
- Tested `install.sh init` (project scaffold — works, minor issues)
- **Found context poisoning:** template CLAUDE.md had 33 lines of {{placeholders}} that Claude Code loads as real instructions before /forge ever runs. Fixed: reduced to 3-line marker with `{{FORGE_PLACEHOLDER}}` in HTML comment (detection still works, zero poisoning)
- Same fix for sdlc-flow.md and agent-routing.md templates
- **Insight for guide:** Templates that get auto-loaded by the LLM must never contain fake instructions — even if they'll be replaced later. Use HTML comments for placeholders.

### Session 2 — 2026-04-05
- **Discovered:** Claude Code strips block-level HTML comments before sending to LLM (confirmed from source: `stripHtmlComments()` in `claudemd.ts`)
- **Fixed context poisoning properly:** Kept all {{PLACEHOLDERS}} inside HTML comment blocks. LLM sees `# New Project` only. Agents reading via Read tool see full template with placeholders.
- **Key insight (Part 0 of guide):** Two Pipes — auto-load strips comments, Read tool doesn't. Same LLM, different entry points.
- **Discovered hooks split:** templates/hooks.json (3 hooks, installed) vs hooks/hooks.json (8 hooks, orphaned). Forge was running without auto-continue, state tracking, or activity logging.
- **Merged hooks:** Single templates/hooks.json with all 8 hooks. Deleted hooks/ directory.
- **Redesigned install.sh:** Removed `init` subcommand. `./install.sh` = global install. `./install.sh <dir>` = global + mkdir + git init. No more template scaffolding — /forge Phase A does it all.
- **Added scripts + templates to global install:** Hooks depend on scripts at ~/.claude/scripts/. Phase A reads templates from ~/.claude/templates/.
- **Updated Phase A Step S8:** Now creates .forge/, playbook, docs, timeline, hooks — everything install.sh init used to do.
- **New user flow:** `git clone forge → ./install.sh → cd my-app → /forge "idea"` — 3 steps, not 4.
- **Next:** Test /forge end-to-end in forge-test-2026-04-05/
