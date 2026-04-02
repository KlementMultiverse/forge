# /investigate — Root Cause Before Fix

Mandatory root-cause analysis before ANY fix. Refuses to patch without understanding WHY.

## Input
$ARGUMENTS — description of the error or failing test

## Execution

<system-reminder>
NEVER skip this step. NEVER fix without investigating first.
"Got an error, let me retry" is PROHIBITED.
"Got an error, let me understand WHY" is REQUIRED.
</system-reminder>

Spawn `@root-cause-analyst` with:
  TASK: Investigate this failure. Do NOT fix it yet.
  1. Read the error message/failing test carefully
  2. Identify the ROOT CAUSE (not the symptom)
  3. Research: check library docs (context7), check rules/, check SPEC.md
  4. Form hypothesis: "The cause is [X] because [evidence Y]"
  5. Verify hypothesis: read the actual code/config that causes the issue
  6. Report: cause, evidence, recommended fix approach

## Output

```markdown
## Investigation: [error description]

### Root Cause
[What is actually wrong and WHY]

### Evidence
[What code/config/test proves this is the cause]

### Recommended Fix
[What to change, which files, what approach]

### Prevention
[What rule/test/check would prevent this in the future]
```

The fix is then implemented by the domain agent, NOT by the investigator.
The prevention note becomes a /learn entry.
