# /retro — Retrospective (BEFORE PR)

Generate a retrospective using Steve's AI-First SDLC template. MUST be written BEFORE creating the PR — Steve's requirement. Updates CLAUDE.md with lessons learned.

## Input
$ARGUMENTS — feature name (e.g., "clinic-portal")

## Phase 0: Context Loading (MANDATORY)

<system-reminder>
The retrospective MUST be written BEFORE the PR is created.
This is Steve's SDLC requirement — not optional.
</system-reminder>

1. Read CLAUDE.md → understand the project
2. Read `git log --oneline` for the feature branch → understand what was built
3. Read GitHub Issues: `gh issue list --state all` → understand what was planned vs completed
4. Read any audit reports from `/audit-patterns` → understand quality status

## Phase 1: Gather Data

Spawn `@forge-pm` with:
  TASK: Analyze the feature branch work — what was planned, what was built, what issues arose
  CONTEXT: Git log + GitHub Issues + audit reports
  EXPECTED OUTPUT: Summary of work done, issues encountered, deviations from plan

Use `/sc:reflect` to validate task completion and capture session insights.

## Phase 2: Fill Retrospective Template

<system-reminder>
Every "What Could Improve" item MUST have a root cause and a concrete improvement action.
No vague entries like "could be better" — specify WHAT, WHY, and HOW TO FIX.
</system-reminder>

```markdown
# Retrospective: [Feature Name]

**Branch:** `feature/[name]`
**Date:** [YYYY-MM-DD]
**Duration:** [actual time from first commit to now]

---

## Summary

[2-3 sentences: what was delivered, success level, key takeaway]

## What Went Well

- **[Success 1]**: [Why it worked — be specific]
- **[Success 2]**: [Why it worked]
- **[Success 3]**: [Why it worked]

## What Could Improve

- **[Issue 1]**:
  - What happened: [Specific description]
  - Root cause: [Why this happened]
  - Improvement: [Concrete action to prevent next time]

- **[Issue 2]**:
  - What happened: [Specific description]
  - Root cause: [Why this happened]
  - Improvement: [Concrete action to prevent next time]

## Lessons Learned

1. **[Learning 1]**: [Insight and how to apply it going forward]
2. **[Learning 2]**: [Insight and how to apply it going forward]

## Changes Made

### Files Modified
- `path/to/file.py` — [what changed]

### Files Created
- `path/to/new.py` — [purpose]

### Files Deleted/Moved
- `path/to/old.py` → [destination or "deleted"]

## Metrics

- GitHub Issues created: [N]
- GitHub Issues completed: [N]
- Pattern audit pass rate: [X]%
- Test coverage: [X]%
- CodeRabbit suggestions addressed: [N]

## Action Items

- [ ] [Action 1] — Owner: [Name], Due: [Date]
- [ ] [Action 2] — Owner: [Name], Due: [Date]
```

## Phase 3: Update CLAUDE.md

Spawn `@learning-guide` with:
  TASK: Extract lessons from the retrospective that should become permanent rules in CLAUDE.md
  CONTEXT: The retrospective + current CLAUDE.md
  EXPECTED OUTPUT: Specific lines to add to CLAUDE.md's rules section

Add lessons to CLAUDE.md (Week 4 truth.md: "Every time Claude makes a mistake, add to CLAUDE.md").

## Phase 4: Save & Handoff

1. Save to `docs/retrospectives/[NN]-[feature-name].md`
2. Return handoff:

```
## Handoff: retro → gate (PR creation)
### Task Completed: Retrospective written, CLAUDE.md updated with lessons
### Files Changed: docs/retrospectives/[NN]-[feature-name].md, CLAUDE.md
### Test Results: [N] GitHub Issues completed out of [M] total. Pattern audit: [X]% pass rate.
### Context for Next Agent: Retrospective is ready. Proceed to /gate for PR creation.
### Blockers: None — retrospective is complete
```
