### CASE 2: EXISTING PROJECT, NO CODE (has CLAUDE.md but no apps/)

1. Read CLAUDE.md
2. Check content quality:
   - Has `{{` placeholders or `[PROJECT NAME]` -> run Phase A discovery conversation (CASE 1)
   - Has real content -> continue
3. Read SPEC.md
   - Exists with [REQ-xxx] tags -> CONTINUE to Phase B (skip Phase A)
   - Missing or empty -> run `/generate-spec` first, then Phase B
4. Log to timeline:
   ```
   ## [TIMESTAMP] CASE 2: Existing project, resuming SDLC
   **Flow:** NEW_PROJECT (resumed)
   **Agent:** PM
   **Input:** existing CLAUDE.md + SPEC.md
   **Output:** resuming from [phase]
   **Status:** IN_PROGRESS
   ```
5. Execute Phase B from wherever it left off
   - Check docs/forge-timeline.md for last completed step
   - Resume from the next step

---

### CASE 3: EXISTING PROJECT WITH CODE -- New Feature

1. Read CLAUDE.md -> understand project rules, stack, architecture
2. Read SPEC.md -> understand existing [REQ-xxx] tags and requirements
3. Ask: "What feature do you want to add?" (if not in $ARGUMENTS)
   - Listen to the answer
   - Web search the feature domain for best practices
4. Present understanding:
   ```
   "I'll add [feature] which needs:
   - Models: [list]
   - Endpoints: [list]
   - Tests: [list]
   It connects to existing [X]. Sound right?"
   ```
5. On confirm:
   - Run `/specify` -> new [REQ-xxx] tags appended to SPEC.md
   - Run `/design-doc`
   - Run `/plan-tasks` -> GitHub Issues
   - Implement per issue (Forge Cell, 7 steps each)
   - Run `/gate` after each phase
   - Run `/retro` when feature complete
6. Log EVERY step to timeline:
   ```
   ## [TIMESTAMP] New Feature: [name]
   **Flow:** NEW_FEATURE
   **Agent:** [agent used]
   **Input:** [what was given]
   **Output:** [file] -> [link]
   **Duration:** [time]
   **Status:** [DONE|BLOCKED|NEEDS_REVIEW]
   **REQs:** [REQ-xxx addressed]
   ```

---

### CASE 4: EXISTING PROJECT WITH CODE -- Bug Fix

1. Read CLAUDE.md -> understand project rules, stack
2. Ask: "Describe the bug" (if not in $ARGUMENTS)
3. Ask: "Where does it happen? (file, endpoint, page)" (if not obvious)
4. Run `/investigate` -> @root-cause-analyst traces the code path:
   - Read relevant files
   - Grep for related patterns
   - Trace execution flow
   - Identify ROOT CAUSE (not just symptom)
5. Present root cause:
   ```
   "The issue is [X] in [file:line] because [Y].
   I'll fix it by [Z]. Sound right?"
   ```
6. On confirm:
   - Write task design doc
   - TDD fix: test reproduces bug (FAIL) -> fix code -> test PASSES -> ALL tests pass
   - Quality: black + ruff
   - Sync check: add/update [REQ-xxx] in SPEC.md if requirement was missing
   - Commit: `fix(domain): description [REQ-xxx]`
   - Run `/learn` if bug reveals non-obvious pattern
7. Log to timeline:
   ```
   ## [TIMESTAMP] Bug Fix: [description]
   **Flow:** BUG_FIX
   **Agent:** @root-cause-analyst -> [domain agent]
   **Input:** "[bug description]"
   **Output:** [files modified] -> [links]
   **Duration:** [time]
   **Status:** DONE
   **REQs:** [REQ-xxx]
   ```

---

### CASE 5: EXISTING PROJECT WITH CODE -- Improvement

1. Read CLAUDE.md -> understand project context
2. Ask: "What do you want to improve?" (if not in $ARGUMENTS)
3. Spawn appropriate agent:
   - Refactor -> @refactoring-expert analyzes target code
   - Performance -> @performance-engineer profiles and measures
   - Cleanup -> @code-archaeologist finds dead code, tech debt
4. Present analysis and plan:
   ```
   "Current state: [analysis]
   Proposed changes: [list]
   Expected improvement: [metrics]
   Risk: [assessment]
   Sound right?"
   ```
5. On confirm:
   - Run ALL existing tests (establish baseline)
   - Make changes (one at a time for refactors)
   - Run ALL tests after each change (no regressions)
   - For performance: measure before AND after with exact numbers
   - Commit: `refactor|perf|chore(domain): description`
   - Run `/learn` if improvement reveals pattern
6. Log to timeline:
   ```
   ## [TIMESTAMP] Improvement: [description]
   **Flow:** IMPROVEMENT
   **Agent:** [@agent-name]
   **Input:** "[improvement request]"
   **Output:** [files modified] -> [links]
   **Duration:** [time]
   **Status:** DONE
   **REQs:** [REQ-xxx if applicable]
   ```

---

### CASE 7: BROWNFIELD — Existing code but no CLAUDE.md

Routes to CASE 1, Phase A, STEP S1 → STEP S5-BROWNFIELD.

The brownfield flow is embedded in CASE 1's Phase A. When STEP S1 (ASSESS) detects
"Code exists, no CLAUDE.md", it jumps to STEP S5-BROWNFIELD which:

1. @repo-index agent indexes the codebase (language, framework, models, endpoints, tests)
2. @requirements-analyst agent reverse-engineers [REQ-xxx] from existing code
3. @system-architect agent generates CLAUDE.md from actual patterns
4. Then continues: S5 (FORGE.md) → S6 (rules) → S7 (skip scaffold) → S8 (hooks) → S9 (review) → S10 (commit)

After setup completes, present to user:
```
I've analyzed your project:
- Tech: [stack]
- Models: [count] ([list])
- Endpoints: [count]
- Tests: [count]
- Requirements: [count] reverse-engineered

What would you like to do next?
(a) Add a new feature
(b) Fix a bug
(c) Improve something
```
Route to CASE 3/4/5 based on answer

---

### CASE 6: Can't determine

1. Ask:
   ```
   "I see an existing project. What would you like to do?
   (a) Add a new feature
   (b) Fix a bug
   (c) Improve/refactor something
   (d) Ask a question about the code"
   ```
2. Route to appropriate case:
   - (a) -> CASE 3
   - (b) -> CASE 4
   - (c) -> CASE 5
   - (d) -> Read CLAUDE.md, read relevant code, explain using real project code (no code changes)
3. Log to timeline

---

### CASE 8: VIOLATION REMEDIATION (auto-fix — NO user interaction)

<system-reminder>
CASE 8 IS FULLY AUTONOMOUS. Do NOT ask the user anything.
Read violations from forge-state.json. Fix each one. Update state. Continue.
This case runs when: forge-state.json exists AND violations array is non-empty.
PRIORITY ORDER: gates > review > Phase 5 steps > traces > checkpoints.
</system-reminder>

**STEP R1: Read violations and categorize**

```bash
bash scripts/forge-enforce.sh check-state
bash scripts/forge-enforce.sh check-continuation
bash scripts/forge-review-guard.sh status
```

Categorize violations by type:
- GATE_SKIPPED → run retroactive gates (verify only, don't redo work)
- REVIEW_SKIPPED → run /review now
- PHASE5_BATCH_SKIPPED → re-run skipped Phase 5 skills properly
- CHECKPOINT_SKIPPED → run /checkpoint for the phase
- TRACE_INCOMPLETE → backfill missing input.md/output.md
- AGENT_SEPARATION → log as historical (can't undo, note for future)
- TDD_SKIPPED → log as historical (can't undo, note for future)

**STEP R2: Fix gate violations (highest priority)**

For each phase with gate_passed = false AND status = DONE:
1. Run verification: tests pass + lint clean + traceability + Docker healthy + no secrets
2. If ALL pass → `bash scripts/forge-enforce.sh update-gate <phase>`
3. If ANY fail → fix the issue → re-verify → mark gate
4. Continue to next ungated phase

**STEP R3: Fix review violations**

If REVIEW_SKIPPED in violations:
1. Run `/review` (the skill) — this triggers PostToolUse hook that marks phase as reviewed
2. Fix any issues found
3. Commit fixes
4. Review guard marker is now set → gate and PR unblocked

**STEP R4: Fix Phase 5 batch-skip violations**

If PHASE5_BATCH_SKIPPED in violations:
For each step that was batch-marked without execution:
- Step 47: Run `skill: "sc:cleanup"` → verify no regressions
- Step 48: Run `skill: "sc:improve"` → verify tests still pass
- Step 49: Run `skill: "retro"` → verify retrospective file created
- Step 50: Run `skill: "sc:reflect"` → verify reflection report
- Step 51: Run `skill: "sc:document"` + @deploy-guide-agent → verify docs/DEPLOY.md
- Step 52: Run @playbook-curator → verify playbook updated
- Step 53: Run `skill: "prune"` + `skill: "evolve"`
- Step 54: Run `skill: "autoresearch"`
- Step 55: Run `skill: "sc:save"`

Each step: execute → verify output → update forge-state.json → trace.

**STEP R5: Fix checkpoint violations**

For each skipped checkpoint:
Run `skill: "checkpoint", args: "phase-<N> | retroactive checkpoint"`

**STEP R6: Fix trace violations**

For each step with trace_complete = false:
Backfill input.md and output.md from git history and forge-timeline.md.

**STEP R7: Handle CodeRabbit reviews on existing PRs**

```bash
# Check if any open PRs have CodeRabbit reviews
PR_NUM=$(gh pr list --state open --json number -q '.[0].number' 2>/dev/null)
if [ -n "$PR_NUM" ]; then
  REVIEWS=$(gh api repos/{owner}/{repo}/pulls/$PR_NUM/reviews \
    --jq '[.[] | select(.user.login | contains("coderabbit"))] | length' 2>/dev/null)
  COMMENTS=$(gh api repos/{owner}/{repo}/pulls/$PR_NUM/comments \
    --jq '[.[] | select(.user.login | contains("coderabbit"))] | length' 2>/dev/null)
fi
```

If CodeRabbit has reviewed (REVIEWS > 0):
1. Read ALL CodeRabbit comments
2. For each comment:
   - Read the file + line
   - Understand the suggestion
   - Apply fix using correct specialist agent (from agent-routing.md)
   - Run tests → verify no regression
3. Commit: `fix: address CodeRabbit review [iteration N]`
4. Push
5. Wait for re-review (poll 30s x 10)
6. Repeat until APPROVED or 5 iterations

If CodeRabbit state = APPROVED:
- Mark PR as ready
- Log to timeline

If no CodeRabbit after 5 min:
- Fall back to local verification checklist
- Log: "CodeRabbit unavailable"

**STEP R8: Clear resolved violations from state**

```python
# Remove violations that have been fixed
for v in violations:
    if v resolved: remove from list
state["violations"] = remaining_violations
state["status"] = "CLEAN" if no violations else "VIOLATIONS_REMAINING"
```

**STEP R9: Final verification**

```bash
bash scripts/forge-enforce.sh full-audit
```

If AUDIT PASSED → log "All violations resolved" → check FORGE.md for queued items → if none, report done.
If AUDIT FAILED → loop back to R1 (max 3 iterations) → if still failing, report remaining issues to user.

---

