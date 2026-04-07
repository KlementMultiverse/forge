**STEP S9: REVIEW all generated files** → @reviewer agent (MANDATORY — DO NOT SKIP)

HANDOFF METRIC (S9):
  MUST VERIFY:
    - ALL S3-S8 handoff metrics pass (run forge-handoff-check.sh for each)
    - Every rating >= 4
    - Discovery notes 14 dimensions ALL represented across CLAUDE.md + SPEC.md
    - Anti-scope: no EXCLUDED item appears in any [REQ-xxx]
  ESCALATE: any rating < 4 → fix → re-review (max 2)

Execute: spawn Agent with subagent_type="reviewer"
  prompt: |
    Review all generated files for this new project:
    1. CLAUDE.md — at least 20 lines, under 100? Real rules? MUST/NEVER format? Code snippets?
    2. SPEC.md — at least 20 [REQ-xxx]? Models have field types? API endpoints listed?
    3. FORGE.md — has QUEUED entry?
    4. .claude/rules/ — SDLC flow complete? Agent routing filled?
    5. Scaffold — settings.py valid? Dependencies listed? Dockerfile works?
    6. .claude/settings.json — valid JSON? Has all 9 hook groups (SessionStart, Stop, UserPromptSubmit, PreToolUse x2, PostToolUse x4)?
    7. .forge/playbook/ — strategies.md, mistakes.md, archived.md exist?
    8. docs/forge-timeline.md — exists with project name?
    9. Discovery Notes — docs/forge-trace/A02_phase-a_step-s2_discovery-notes.md exists?
       All 14 FINAL DIMENSIONS filled? Every inference has proof citation?
    10. SPEC Traceability — does SPEC.md Requirements Traceability table have 4 columns (REQ | description | proof | status)?
        Are there [REQ-COMPLIANCE-xxx] if compliance was confirmed? [REQ-SUCCESS-xxx]?
    11. CLAUDE.md Security — if HIPAA confirmed, does "PHI" appear in rules?
        If GDPR, does "consent" or "erasure" appear? If PCI, does "tokenisation" appear?
    12. Anti-scope — are any items from EXCLUDED list accidentally present as [REQ-xxx]?

    Rate each 1-5. Report any issues.

Verify: all ratings >= 4
If any < 4 → fix → re-review
Trace: save to docs/forge-trace/S9-review/

**STEP S10: COMMIT + DONE** (MANDATORY — DO NOT SKIP)

```bash
# Add specific files — NEVER git add -A (could include .env or credentials)
git add CLAUDE.md SPEC.md FORGE.md .claude/ .forge/ docs/ scripts/ \
  pyproject.toml Dockerfile docker-compose.yml .dockerignore .gitignore \
  .env.example config/ apps/ manage.py conftest.py 2>/dev/null || true
git commit -m "init: scaffold project with forge"
```

Output to user:
```
Setup complete!

Created:
  CLAUDE.md           — {N} lines, {N} architecture rules
  SPEC.md             — {N} [REQ-xxx] requirements
  FORGE.md            — 1 QUEUED item ready
  .claude/rules/      — SDLC flow + agent routing
  .claude/settings.json — hooks for lint + safety + flow detection
  Scaffold            — {list of files}

Next: exit Claude Code, then run `forge` again in this folder.
Session 2 will load CLAUDE.md and start building.
```

**FAILURE RECOVERY:** If Phase A fails mid-way:
- Run `bash ~/.claude/scripts/forge-infra-check.sh --reset` to clear state and restart fresh
- Or fix the issue and run `/forge` again — S1 will detect partial setup and resume

---

**STEP S5-BROWNFIELD: REVERSE-ENGINEER** (when code exists, no CLAUDE.md)

<system-reminder>
This project has code but was NOT built with Forge. Do NOT create requirements from scratch.
The requirements ALREADY EXIST in the code. You must DISCOVER them first.
NEVER ask "what are you building?" — the code TELLS you what was built.
</system-reminder>

Execute: spawn Agent with subagent_type="repo-index"
  prompt: "Index {project folder}. Report: language, framework, file count, models found, endpoints found, tests found."
Verify: index report exists

Execute: spawn Agent with subagent_type="requirements-analyst"
  prompt: "Reverse-engineer requirements from existing code. Read models → data requirements. Read API → functional requirements. Read tests → verified behaviors. Output [REQ-xxx] tags."
Verify: at least 10 [REQ-xxx] from existing code

Execute: spawn Agent with subagent_type="system-architect"
  prompt: "Generate CLAUDE.md from existing codebase. Read pyproject.toml/package.json for stack. Read config for settings. Extract patterns as rules."
Verify: CLAUDE.md has real stack, real rules

If repo-index detects multiple frameworks (e.g., Django backend + React frontend):
  → PM asks: "I found both [X] and [Y]. Which should I focus on?"
  → User picks → agent-routing.md targets that framework

Then → STEP S5 (FORGE.md) → S6 → S7 (brownfield: skip scaffold but check for missing Dockerfile/docker-compose — add only missing infra files) → S8 → S9 → S10
