# /audit-patterns — Pattern Audit

Run the pattern-auditor-agent to scan the project against all learned patterns (170+ checks from Weeks 1-4 + context engineering article).

## Input
$ARGUMENTS — "full" (all phases) or "quick" (safety + LLM + specs only). Default: "full"

## Execution

<system-reminder>
The pattern auditor is the quality backbone of the entire SDLC.
It runs BEFORE and AFTER every important step.
It does NOT write code — it only reports what is present and what is missing.

STATE AWARENESS: If docs/forge-state.json exists, read it first.
- If a phase is marked DONE → its work exists, just VERIFY it
- If steps are marked SKIPPED → note as violation but don't block on historical skips
- Report current state alongside audit results
- Update forge-state.json after audit completes
</system-reminder>

### If $ARGUMENTS = "quick":
Spawn `@pattern-auditor-agent` with:
  TASK: Run quick audit — Phases 4 (Safety), 6 (LLM Integration), 15 (Spec-Driven Dev) only
  CONTEXT: Project root directory
  EXPECTED OUTPUT: Audit report with pass/fail for checked phases

### If $ARGUMENTS = "full" (or no argument):
Spawn `@pattern-auditor-agent` with:
  TASK: Run full audit — ALL phases (2 through 23)
  CONTEXT: Project root directory
  EXPECTED OUTPUT: Full audit report with pass/fail for all 170+ checks

Then spawn `@quality-engineer` with:
  TASK: Review the audit report. Prioritize the failures by impact. Recommend fix order.
  CONTEXT: The audit report
  EXPECTED OUTPUT: Prioritized fix list (top 5 most critical)

Then spawn `@self-review` with:
  TASK: Validate the audit findings. Check for false positives. Confirm real issues.
  CONTEXT: The audit report + the actual code files flagged
  EXPECTED OUTPUT: Confirmed findings (remove false positives)

## Output

<system-reminder>
After displaying the report, always return a structured handoff
so the PM agent knows whether to proceed or loop back for fixes.
</system-reminder>

Display the final audit report. Highlight:
1. Pass rate: [X/Y] ([%])
2. Top 5 priority fixes with exact file + location + code to add
3. Any false positives identified by self-review (excluded from count)

## Handoff

```
## Handoff: audit-patterns → [fix agent or next stage]
### Task Completed: Pattern audit ran ([full/quick])
### Files Changed: None (read-only audit)
### Test Results: [X/Y] pass rate ([%])
### Context for Next Agent: [If >90%: "Proceed to next stage." | If <90%: "Fix the top 5 failures first."]
### Blockers: [List any critical failures that block progress, or "None"]
```
