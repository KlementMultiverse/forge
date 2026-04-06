# /forge -- One Command to Build Everything

## Input
$ARGUMENTS -- optional. Can be:
- "Build a task tracker" (new project)
- "Add dark mode" (new feature)
- "Fix login bug" (bug fix)
- Empty (forge detects and asks)

## How It Works

When user types `/forge`, the following happens DETERMINISTICALLY:

### STEP 0: DETECT (hook-enforced, cannot be skipped)

The UserPromptSubmit hook already ran and injected one of:
- `[FORGE] CASE1_GREENFIELD` — no CLAUDE.md, no code
- `[FORGE] CASE1_GREENFIELD (placeholder)` — CLAUDE.md has {{placeholders}}
- `[FORGE] CASE2_SPEC_ONLY` — CLAUDE.md exists, no code
- `[FORGE] CASE7_BROWNFIELD` — code exists, no CLAUDE.md
- `[FORGE] EXISTING_PROJECT` — CLAUDE.md + code exist

Read the hook output. Then route to the correct case below.

### STEP 0.5: CHECK FORGE STATE (HIGHEST PRIORITY)

If `docs/forge-state.json` exists:
```bash
bash scripts/forge-enforce.sh check-state 2>/dev/null || bash ~/.claude/scripts/forge-enforce.sh check-state 2>/dev/null
bash scripts/forge-enforce.sh check-continuation 2>/dev/null || bash ~/.claude/scripts/forge-enforce.sh check-continuation 2>/dev/null
```

**VIOLATION REMEDIATION — AUTO-FIX:**
If forge-state.json has violations > 0 → Read `~/.claude/commands/forge-phases/cases.md` for CASE 8. Auto-fix. Do NOT ask user.

**RESUME — AUTO-CONTINUE:**
If forge-state.json shows current_step < 57 → RESUME from next step. Read the phase file for that step. Do NOT ask user.

### STEP 1: ROUTE

If FORGE.md exists → read it → find first QUEUED item → route by type.
If FORGE.md does NOT exist → route based on hook detection.

Detection logic:
```
0. Hook says CASE_RESUME (step N)          → RESUME from step N (HIGHEST PRIORITY — skips all below)
1. forge-state.json has violations?         → CASE 8 (auto-fix)
2. forge-state.json has incomplete steps?   → RESUME from next step
3. Hook says CASE1_GREENFIELD              → CASE 1 (new project)
4. Hook says CASE7_BROWNFIELD              → CASE 7 (reverse-engineer first)
5. Hook says CASE1_GREENFIELD (placeholder) → CASE 1 (template, treat as new)
6. Hook says CASE2_SPEC_ONLY              → CASE 2 (has CLAUDE.md, no code)
7. Hook says EXISTING_PROJECT:
   - $ARGUMENTS mentions "fix" / "bug"     → CASE 4 (bug fix)
   - $ARGUMENTS mentions "add" / "feature"  → CASE 3 (new feature)
   - $ARGUMENTS mentions "improve" / "refactor" → CASE 5 (improvement)
   - $ARGUMENTS empty or unclear            → CASE 6 (ask user)
```

---

## Phase Files (READ the one you need — do NOT read all of them)

Each phase is in a separate file. Read ONLY the file for your current phase:

| Current Step | Phase | Read This File |
|---|---|---|
| No CLAUDE.md | Setup | `~/.claude/commands/forge-phases/phase-a-setup.md` |
| Steps 1-19 | Plan (Genesis→Specify→Architect) | `~/.claude/commands/forge-phases/phase-0-2-plan.md` |
| Steps 20-39 | Implement | `~/.claude/commands/forge-phases/phase-3-implement.md` |
| Steps 40-56 | Validate + Review | `~/.claude/commands/forge-phases/phase-4-5-validate.md` |
| CASE 2-8 | Special cases | `~/.claude/commands/forge-phases/cases.md` |

**CRITICAL: Read ONE phase file at a time. When you finish a phase, read the NEXT one.**

---

## State Tracking (AUTOMATIC — handled by hooks)

You do NOT need to manually run `forge-enforce.sh update-step`. The PostToolUse hooks on Skill and Agent automatically call `~/.claude/scripts/forge-auto-state.sh` which maps skill/agent names to step numbers and updates forge-state.json.

Gates are also auto-updated when you run `/gate`.

If auto-state fails or you need manual override:
```bash
bash scripts/forge-enforce.sh update-step <N> DONE 2>/dev/null || bash ~/.claude/scripts/forge-enforce.sh update-step <N> DONE
```

---

## Observer Integration (AUTOMATIC — handled by hooks)

The observer reviews your artifacts in real-time. The Stop hook manages the feedback loop:

1. If `docs/.observer-reviewing` exists → Observer is reviewing. Wait. Run `sleep 30` then check again.
2. If `docs/.observer-reviews.log` has NEEDS_FIX → Fix those items first. Read the file for details.
3. If neither → Continue to next step immediately.

You do NOT need to check manually. The Stop hook prints instructions when you pause.

---

## Rules (ALWAYS apply)

1. NEVER stop between phases to ask "should I continue?" — always continue
2. NEVER ask which agent to use — read `.claude/rules/agent-routing.md`
3. ONLY stop for: gate BLOCKED, /challenge RETHINK, missing credentials, 3 failed retries
4. Per-issue commits in Phase 3: `feat(<app>): <description> [REQ-xxx]`
5. TDD in Phase 3: tests FIRST (fail) → code (pass) → full suite (no regression)
6. PM never writes app code — spawn specialist agents
7. Read `~/.claude/rules/` for stack-specific rules (django.md, python.md, docker.md, security.md)
8. Read `~/.claude/stacks/{stack}/learnings.md` for past build learnings

---

## Completion

When ALL phases done (step 57):
```
Forge complete.
- Project: [name]
- Tests: [count] passing
- Coverage: [%]
- Traceability: [%] REQ coverage
- Timeline: docs/forge-timeline.md
```
