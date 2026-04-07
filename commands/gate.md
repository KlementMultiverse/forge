# /gate — Quality Gate (Blocks Until Verification Passes)

The critical automation that blocks progress until quality checks pass. No stage proceeds without passing the gate.

## Input
$ARGUMENTS — stage name (e.g., "phase-0", "stage-1", "stage-3", "stage-4")

## Step 0: Read Forge State (MANDATORY)

Before doing ANYTHING, check what's already done:

```bash
# Read current state — know where we are
bash scripts/forge-enforce.sh check-state 2>/dev/null || bash ~/.claude/scripts/forge-enforce.sh check-state 2>/dev/null

# Check what the gate needs to verify
bash scripts/forge-enforce.sh check-continuation 2>/dev/null || bash ~/.claude/scripts/forge-enforce.sh check-continuation 2>/dev/null
```

Read `docs/forge-state.json` if it exists. The state tells you:
- Which phases are DONE (don't re-do their work)
- Which gates already passed (skip them)
- What violations exist (report but don't block on historical ones)

**KEY RULE:** If a phase's code is already DONE and tests pass, the gate only needs to VERIFY — not redo. Run checks, confirm they pass, mark gate as passed.

## Execution

<system-reminder>
This gate BLOCKS progress. Do NOT proceed to the next stage until verification passes.

GATE VERIFICATION CHECKLIST (run in order, stop on first failure):
1. All tests pass: `docker compose exec -T web uv run python manage.py test` (if Docker)
2. Lint clean: `ruff check . && black --check .` (inside Docker if applicable)
3. TRIANGLE SYNC: `bash scripts/forge-triangle.sh check` → sync rate >= 90%
   If < 90%: for each broken REQ → create issue → fix → re-check
   GATE BLOCKS until triangle passes. This is NON-NEGOTIABLE.
4. SUSPECT REQs: `bash scripts/forge-enforce.sh check-suspect` → must pass (no unverified suspects)
   If suspects exist → run triangle check to clear them → re-check
5. REVIEW GUARD: `bash scripts/forge-review-guard.sh check-for-gate` → must pass
   If not reviewed → run /review first → mark-reviewed → re-check
6. Artifact verification: `bash scripts/forge-verify.sh verify-all` → no FAKE DONEs
7. Docker healthy: `bash scripts/docker-state.sh --check` (if Docker project)
8. No hardcoded secrets: `grep -r "sk-\|AKIA\|ghp_" apps/ --include="*.py"` → empty
9. Files under 300 lines: `find apps/ -name "*.py" | xargs wc -l | awk '$1 > 300'` → empty

10. CodeRabbit approval: run `/cr approve` → exit code 0 means APPROVED
    Exit 1 = not approved (CHANGES_REQUESTED or PENDING)
    If exit 1 → check `/cr status` for details:
      CHANGES_REQUESTED → fix findings → `/cr resolve` → `/cr review` → re-check
      PENDING → wait 60s → re-check (max 3 polls)
    GATE BLOCKS without CR approval (exit 0). This is NON-NEGOTIABLE.

If ALL 10 checks pass → gate PASSES. Update state:
```bash
bash scripts/forge-enforce.sh update-gate {phase_number}
bash scripts/forge-enforce.sh update-step {gate_step_number} DONE
```

NEVER skip verification. NEVER assume passing without running checks.
</system-reminder>

### Step 1: Run Pattern Audit

Run `/audit-patterns quick` (for mid-stage gates) or `/audit-patterns full` (for end-of-stage gates).

- If pass rate < threshold → STOP. Report failures. Do NOT proceed.
- If pass rate ≥ threshold → continue to Step 2.

### Step 2: Commit & Push

Use `/sc:git --smart-commit` to:
1. `git add` relevant files (NOT `git add .` — be specific)
2. Generate conventional commit message from changes
3. `git commit`
4. `git push -u origin` current branch

### Step 3: Create PR

```bash
gh pr create \
  --title "[Stage N] $ARGUMENTS" \
  --body "$(cat <<'EOF'
## Summary
[Auto-generated from commit messages]

## Linked Documents
- Proposal: [link to relevant proposal in docs/proposals/]
- Design Doc: docs/design-doc.md
- Retrospective: [link to relevant retrospective in docs/retrospectives/, if exists]

## Pattern Audit
- Pass rate: [X]%
- Critical failures: [N]

## Checklist
- [ ] Pattern audit passed
- [ ] CodeRabbit reviewed
- [ ] Zero suggestions remaining

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

### Step 4: CodeRabbit Autonomous Fix Loop (MISSION CRITICAL)

<system-reminder>
ARTEMIS-GRADE AUTONOMOUS BEHAVIOR:
This is a CLOSED LOOP. The system fixes CodeRabbit issues autonomously.
No human involved. The loop runs until APPROVED or max iterations hit.

The loop does NOT restart the phase. It only fixes the specific issues
CodeRabbit found, re-commits, re-pushes, and waits for re-review.
Same PR, same branch — just fix-commit-push-wait cycles.
</system-reminder>

```
AUTONOMOUS FIX LOOP (max 5 iterations):

  iteration = 0
  WHILE iteration < 5:

    1. GET PR number:
       gh pr list --state open --head $(git branch --show-current) --json number -q '.[0].number'

    2. WAIT for CodeRabbit (poll every 30s, max 10 polls = 5 min):
       WHILE no review found AND polls < 10:
         sleep 30
         REVIEW_STATE = gh api repos/{owner}/{repo}/pulls/{pr}/reviews \
           --jq '[.[] | select(.user.login | contains("coderabbit"))] | last | .state'
         IF REVIEW_STATE is not empty: BREAK

       IF no review after 10 polls:
         Log: "GATE BLOCKED — CodeRabbit review unavailable"
         STOP — retry later or escalate to user
         BREAK

    3. CHECK review state:
       IF REVIEW_STATE = "APPROVED":
         Log: "GATE PASSED — CodeRabbit APPROVED"
         BREAK → proceed to next phase

       IF REVIEW_STATE = "COMMENTED" or "CHANGES_REQUESTED":
         iteration += 1
         Log: "CodeRabbit iteration {iteration}/5 — fixing suggestions"

    4. READ CodeRabbit suggestions:
       COMMENTS = gh api repos/{owner}/{repo}/pulls/{pr}/comments \
         --jq '[.[] | select(.user.login | contains("coderabbit"))] | .[] | {path: .path, line: .line, body: .body}'

    5. FIX each suggestion AUTONOMOUSLY:
       For each comment:
         - Read the file at the line mentioned
         - Understand the suggestion
         - Apply the fix (spawn appropriate agent from agent-routing.md)
         - Run tests to verify no regression

    6. COMMIT + PUSH:
       git add -A
       git commit -m "fix: address CodeRabbit review iteration {iteration} [REQ-xxx]"
       git push

    7. LOOP BACK to step 2 (wait for re-review)

  END WHILE

  IF iteration >= 5:
    Log: "GATE BLOCKED — 5 CodeRabbit fix iterations exhausted"
    Log: "Remaining suggestions: [list]"
    STOP — escalate to user
```

### Step 5: Evaluate Final Result

```bash
# Final check
REVIEW=$(gh api repos/{owner}/{repo}/pulls/{pr}/reviews \
  --jq '[.[] | select(.user.login | contains("coderabbit"))] | last | .state')
COMMENTS=$(gh api repos/{owner}/{repo}/pulls/{pr}/comments \
  --jq '[.[] | select(.user.login | contains("coderabbit")) | select(.position != null)] | length')
```

**If APPROVED AND comments = 0:**
```
GATE PASSED: $ARGUMENTS
- Verification: ALL checks green
- CodeRabbit: APPROVED (iteration {N})
- PR: #{number}
- Status: PROCEED to next phase

Update state:
  bash scripts/forge-enforce.sh update-gate {phase}
  bash scripts/forge-enforce.sh update-step {step} DONE
```

**If NOT approved after 5 iterations:**
```
GATE BLOCKED: $ARGUMENTS
- CodeRabbit: NOT APPROVED after 5 fix iterations
- Remaining: {N} unresolved suggestions
- Action: User must review remaining issues manually

Remaining suggestions:
[list each with file + line + description]
```

STOP. Do NOT proceed.

## Flow Clarification — Does NOT Restart Phase

The CodeRabbit fix loop is **NOT a phase restart**. It:
- Stays on the SAME PR, SAME branch
- Only fixes the specific lines CodeRabbit flagged
- Does NOT re-run implementation steps (N0-N9)
- Does NOT create new GitHub issues
- Just: read comment → fix code → run tests → push → wait for re-review
- This is a MICRO-LOOP within the gate step, not a macro phase loop

## Handoff (only on PASS)

```
## Handoff: gate → [next phase]
### Task Completed: Gate $ARGUMENTS passed
### Verification: tests + lint + traceability + security + Docker
### CodeRabbit: APPROVED (iteration {N}/5)
### PR: #{number}
### Context for Next Agent: Gate passed. Proceed to next phase.
### Blockers: None — gate cleared
```
