## TIMELINE TRACKING (MANDATORY -- every step logged)

<system-reminder>
After EVERY significant action, append to docs/forge-timeline.md.
This file is the audit trail. It MUST exist. It MUST be accurate.
If it doesn't exist, CREATE it before the first log entry.
Format is strict -- follows the template below.
</system-reminder>

Every entry in docs/forge-timeline.md:

```markdown
## [TIMESTAMP] [STEP-NAME]

**Flow:** [NEW_PROJECT | BUG_FIX | NEW_FEATURE | IMPROVEMENT]
**Agent:** [@agent-name or /command-name]
**Input:** [what was given to the agent]
**Output:** [file created/modified] -> [link to file](relative-path)
**Duration:** [time taken]
**Status:** [DONE | BLOCKED | NEEDS_REVIEW | IN_PROGRESS]
**REQs:** [which REQ-xxx tags were addressed]

---
```

### Timeline Rules
1. Every entry MUST have all 7 fields (Flow, Agent, Input, Output, Duration, Status, REQs)
2. Output MUST include relative links to artifacts: `[filename](relative-path)`
3. Newest entries go at the TOP (below the header)
4. Status transitions: IN_PROGRESS -> DONE | BLOCKED | NEEDS_REVIEW
5. BLOCKED entries MUST include reason in Output field
6. Every /gate result logged with pass/fail and CodeRabbit suggestion count
7. Every agent handoff logged (who handed off to whom, what was passed)

### Timeline Validation (PostToolUse hook enforces)
When writing to docs/forge-timeline.md, the hook validates:
- Entry has `## ` header with timestamp
- Entry has all 7 `**Field:**` lines
- Status is one of: DONE, BLOCKED, NEEDS_REVIEW, IN_PROGRESS
- If validation fails, the hook warns and the entry must be corrected

---

## EXECUTION TRACE (MANDATORY — full input/output saved per step)

<system-reminder>
After EVERY agent execution or command run, save a full trace entry.
This is NOT the same as the timeline — the timeline is a summary.
The trace has the FULL input and output content.
</system-reminder>

### How to save a trace entry

After each step completes:

1. Create folder: `docs/forge-trace/{NNN}-{step-name}/`
   - NNN is zero-padded step number (001, 002, 003...)
   - step-name is the command or agent name (discover, requirements, etc.)

2. Write `input.md`:
   ```markdown
   # Input to {{agent-name}}

   **Source:** {{where this input came from — previous step output, user message, etc.}}

   {{full input content that was given to the agent}}
   ```

3. Write `output.md`:
   ```markdown
   # Output from {{agent-name}}

   **Files created:** {{list of files}}
   **REQs:** {{REQ-xxx tags created or addressed}}

   {{full output content from the agent}}
   ```

4. Write `meta.md`:
   ```markdown
   # Step {{NNN}}: {{step-name}}

   - **Agent:** {{agent-name}}
   - **Timestamp:** {{ISO timestamp}}
   - **Duration:** {{time taken}}
   - **Status:** {{DONE / BLOCKED / NEEDS_REVIEW}}
   - **Flow:** {{CASE1_GREENFIELD / CASE3_FEATURE / CASE4_BUGFIX / etc.}}
   - **Previous step:** [{{prev step}}](../{{prev-folder}}/meta.md)
   - **Next step:** [{{next step}}](../{{next-folder}}/meta.md)
   ```

5. Update `docs/forge-trace/INDEX.md` (append one line):
   ```markdown
   | {{NNN}} | {{step-name}} | {{agent}} | {{status}} | [input]({{NNN}}-{{step}}/input.md) | [output]({{NNN}}-{{step}}/output.md) | {{duration}} |
   ```

### Trace Index file format

The INDEX.md at `docs/forge-trace/INDEX.md`:

```markdown
# Forge Execution Trace — {{PROJECT_NAME}}

Every step of the build process with full input/output.
Click any link to see exactly what happened.

| # | Step | Agent | Status | Input | Output | Duration |
|---|------|-------|--------|-------|--------|----------|
```

---

## COMPLETION

When ALL phases are done, output:

```
Forge complete.
- Project: [name]
- Location: [path]
- Flow: [NEW_PROJECT | NEW_FEATURE | BUG_FIX | IMPROVEMENT]
- Tests: [count] passing
- Coverage: [%]
- Traceability: [%] REQ coverage
- Audit: [%] pattern pass rate
- Timeline: docs/forge-timeline.md ([N] entries)
- Duration: [total time]
```
