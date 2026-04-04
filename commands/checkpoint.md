# /checkpoint — Self-Improving Execution Feedback Loop

Every agent or command execution produces a checkpoint file. The checkpoint captures input, output, evaluation, and any prompt mutations needed. This makes the automation layer self-improving — every run makes future runs better.

This is NOT project-specific. It works for any project. Project-specific context comes from CLAUDE.md, not from this command.

## Input
$ARGUMENTS — two parts separated by `|`:
  Part 1: agent/command name (e.g., "django-ninja-agent" or "specify")
  Part 2: brief task description (e.g., "create auth endpoints per specs/auth.md")

Example: `django-ninja-agent | create auth endpoints per specs/auth.md`

## When to Run

<system-reminder>
Run /checkpoint AFTER every significant agent or command execution.
This is not optional. Every output gets checkpointed.
The checkpoint file is the learning record — it's how prompts improve over time.
</system-reminder>

After ANY of these produce output:
- Any custom agent execution (@agent-*)
- /specify, /design-doc, /plan-tasks
- /sc:implement, /sc:test, /sc:design
- /gate (after CodeRabbit review)
- /retro

## Phase 1: Capture

Create a checkpoint file at `docs/checkpoints/{NN}-{agent-name}-{timestamp}.md`:

```markdown
# Checkpoint: {agent/command name}
**Date:** {YYYY-MM-DD HH:MM}
**Task:** {brief task description from $ARGUMENTS}
**Project:** {from CLAUDE.md first line}

## Input
- **CLAUDE.md rules applied:** {which rule numbers were relevant}
- **Spec/file read:** {which spec or file was the input}
- **Context loaded:** {what context7 docs were fetched, if any}

## Output Summary
- **Files created/modified:** {list}
- **Key decisions made:** {list}
- **Tests run:** {pass/fail count, or "not run"}

## Evaluation (binary — PASS/FAIL each)

### Universal Checks (apply to ALL agents/commands in ANY project)
1. Did it read CLAUDE.md before acting? {PASS/FAIL}
2. Did it state intent before executing? {PASS/FAIL}
3. Did it stay within its declared scope? {PASS/FAIL}
4. Is the output actionable (specific files, code, commands — not vague)? {PASS/FAIL}
5. Does the output match the handoff protocol? {PASS/FAIL}
6. Were errors/edge cases addressed? {PASS/FAIL}
7. Did it follow the project's framework rules (from CLAUDE.md)? {PASS/FAIL}
8. Did it run tests or validation after changes? {PASS/FAIL}

### Backend Logic Checks (apply when code is generated)
9. Input validation on every endpoint? {PASS/FAIL/N/A}
10. Auth checks where required? {PASS/FAIL/N/A}
11. External API calls have timeout + try/except? {PASS/FAIL/N/A}
12. Credentials from env vars, never hardcoded? {PASS/FAIL/N/A}
13. Error responses are structured (status code + message)? {PASS/FAIL/N/A}
14. Business logic matches spec exactly? {PASS/FAIL/N/A}

### Score
{PASS count} / {total applicable} = {percentage}%

## Issues Found
{For each FAIL, describe:}
- **Issue:** {what went wrong}
- **Root cause:** {why — was the prompt unclear? missing instruction? wrong example?}
- **Prompt fix needed:** {exact change to the agent/command .md file}
- **File to edit:** {path to the agent or command file}

## Prompt Mutations Applied
{If issues were found, what was changed in the agent/command prompt:}
- **File:** {path}
- **Line:** {approximate location}
- **Before:** {old text}
- **After:** {new text}
- **Why:** {which eval criterion this fixes}

## Verdict
{ALL PASS | ISSUES FOUND AND FIXED | ISSUES FOUND — MANUAL REVIEW NEEDED}
```

## Phase 2: Evaluate

Read the output from the agent/command execution. Score every applicable criterion as PASS or FAIL.

<system-reminder>
Be HONEST in evaluation. Do not mark PASS if the output is borderline.
A PASS means "this would work correctly in production."
A FAIL means "this would cause a bug, drift, or missing behavior."
</system-reminder>

For each FAIL:
1. Identify the ROOT CAUSE — is it the agent prompt? the command instructions? CLAUDE.md missing a rule?
2. Determine the FIX — what exact change to which file would prevent this in future runs?
3. The fix must be GENERIC (works for any project), not project-specific

## Phase 3: Mutate (if issues found)

<system-reminder>
Mutation rules (same as autoresearch):
- STRENGTHEN wording: "should" → "MUST", "consider" → "ALWAYS"
- ADD examples when format was wrong
- ADD instructions when content was missing
- ADD <system-reminder> when rules were ignored
- NEVER delete whole sections
- NEVER make project-specific changes to global agents/commands
- ONE mutation per issue — surgical, not rewrites
</system-reminder>

For each issue:
1. Edit the agent/command file (the global one at ~/.claude/agents/ or ~/.claude/commands/)
2. Apply the minimal mutation that fixes the issue
3. Log the mutation in the checkpoint file (Before/After)

## Phase 4: Verify

After mutations are applied:
1. Would the same input now produce output that passes the failed criterion? (mental re-simulation)
2. Could the mutation cause regressions on other criteria? (check for conflicts)
3. If yes to regression risk → revert and try a different mutation

## How This Makes the Video Work

```
Day 1 (building):
  Run the full flow → checkpoints capture every issue → prompts get improved
  Run again → fewer issues → more improvements
  After N runs → all prompts are battle-tested

Day 2 (recording):
  Delete all generated CODE (app files, migrations, DB)
  KEEP all automation (agents, commands, CLAUDE.md, specs, checkpoints)
  Re-run the flow on camera → prompts already know what works
  The output is clean because the prompts learned from Day 1's mistakes
```

## Checkpoint Index

Maintain `docs/checkpoints/INDEX.md` with one line per checkpoint:

```markdown
# Checkpoint Index

| # | Date | Agent/Command | Task | Score | Issues | Fixed? |
|---|------|--------------|------|-------|--------|--------|
| 01 | 2026-03-30 | django-tenants-agent | create tenant models | 100% | 0 | — |
| 02 | 2026-03-30 | django-ninja-agent | create auth endpoints | 88% | 1 | ✅ |
```

This index shows the learning trajectory — scores should trend upward over time.
