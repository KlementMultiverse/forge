# Forge Meta-Protocol — How Forge Itself Changes

This protocol governs ALL changes to forge — whether triggered by a human, an agent during a flow, or an automated process. No exceptions.

**Core principle:** The same rules forge enforces on projects, forge enforces on itself.

---

## 1. New Component Creation

When ANY new component is created (agent, command, script, template, rule, hook):

```
BEFORE CREATING:
  1. GitHub issue exists for this change
  2. --impact checked on related files
  3. Protocol for this component type read (component-creation.md)

CREATION (TDD):
  4. Write test FIRST (RED — test fails)
  5. Create component (GREEN — test passes)
  6. Run full test suite (no regressions)
  7. Run forge-test-guard.sh (component shows as tested)

SYNC:
  8. Run forge-lint.py (validates structure)
  9. Run forge-registry.py (updates dependency graph)
  10. Run forge-readme-sync.sh (updates counts)
  11. If hook-dependent: wire into hooks.json + write integration test

REVIEW:
  12. Commit with conventional format: type(scope): desc #issue
  13. PR (one issue per PR)
  14. Tag @coderabbitai → wait → address ALL comments
  15. Loop until explicit [approve]
  16. Only then merge
```

**This applies even when @agent-factory creates a new agent during Phase 3.**
The flow pauses, the protocol runs, then the flow resumes.

---

## 2. Existing Code Modification

When ANY existing file is modified:

```
BEFORE EDITING:
  1. Run: forge-registry.py --impact <file>
     → What other files are affected?
  2. Run: forge-ownership.sh who <file>
     → Who owns this code?
  3. Run: forge-enforce.sh check-suspect
     → Any unverified suspect REQs?
  4. If file has [REQ-xxx] tags:
     → Note which REQs are served
     → These must still work after your change

DURING EDITING:
  5. PreToolUse Edit hook fires automatically:
     → Shows IMPACT warning for REQ-linked files
     → Shows line removal warning if >10 lines deleted
  6. Never remove a [REQ-xxx] tag without updating SPEC.md
     → pre-commit hook will block this

AFTER EDITING:
  7. PostToolUse Write/Edit hook fires:
     → Ruff lint auto-runs on .py files
     → File size warning if >300 lines
     → FORGE TRACE reminder if trace block exists
  8. Run: forge-triangle.sh check
     → Triangle still synced? (SPEC ↔ TEST ↔ CODE)
  9. Run full test suite
     → No regressions
  10. Update FORGE TRACE block:
      → forge-trace-update.sh add <file> <REQ> <agent> <PR> <desc>

REVIEW:
  11. Same as creation: commit → PR → CR → [approve] → merge
```

**Key rule:** Enhancements only. If a change would break an existing REQ, it needs:
- Discussion with the REQ owner (forge-ownership.sh who)
- Triangle re-sync (forge-triangle.sh check)
- All affected tests must pass
- CR must explicitly approve the breaking change

---

## 3. Architectural Changes

When forge's own structure changes (scripts/, commands/, hooks.json, templates/, rules/):

```
PLANNING:
  1. Create GitHub issue with full proposal
  2. Tag @coderabbitai on issue for architecture review
  3. Wait for CR feedback — address ALL recommendations
  4. Only proceed after CR confirms approach

IMPLEMENTATION:
  5. Follow component creation or modification protocol (above)
  6. Run --impact on EVERY changed file
  7. Check global short-circuit:
     → install.sh, hooks.json, rules/*.md changes affect ALL projects
     → Document: "All projects need reinstall after this change"

SYNC:
  8. Run forge-readme-sync.sh --fix (update counts)
  9. Run forge-registry.py (regenerate dependency graph)
  10. Run forge-lint.py (validate all components)
  11. Update docs/architecture.md if structure changed
  12. Update docs/evolution-log.md with decision rationale

REVIEW:
  13. PR → CR review → address comments → loop
  14. Explicit [approve] required
  15. Merge
  16. Run install.sh after merge (if global short-circuit)
```

---

## 4. Mechanical Enforcement (Hooks)

These hooks enforce the protocol automatically:

| When | Hook | What It Checks |
|------|------|---------------|
| Session start | SessionStart | gh CLI, auth, remote, CLAUDE.md size |
| Before /forge | UserPromptSubmit | Project type, state sync |
| Before editing | PreToolUse Edit | REQ impact, line removal, ownership |
| Before bash | PreToolUse Bash | Destructive command blocking |
| After writing | PostToolUse Write/Edit | Lint, file size, FORGE TRACE |
| After agent | PostToolUse Agent | Activity log, state update |
| After skill | PostToolUse Skill | Activity log, state update |
| Before commit | pre-commit hook | REQ removal blocking, test-guard |
| On commit | commit-msg hook | Issue reference, conventional format, scope |
| At gate | /gate command | Suspect REQs, review guard, triangle, CR approval |

---

## 5. What Stops the Old Requirements from Breaking?

```
Layer 1: PreToolUse Edit
  → "This file serves REQ-AUTH-001, REQ-AUTH-002"
  → Agent sees the warning, knows what to protect

Layer 2: pre-commit hook
  → Blocks if [REQ-xxx] tag removed from code
  → Forces developer to update SPEC if removing a REQ

Layer 3: Suspect link tracking
  → When REQ-linked code changes, REQ becomes SUSPECT
  → Suspect REQs block gates until triangle check passes

Layer 4: Triangle check at gate
  → SPEC ↔ TEST ↔ CODE must all have same REQ tags
  → Gate BLOCKS if triangle broken

Layer 5: CodeRabbit review
  → CR identifies edge cases we missed
  → Every CR comment becomes a test
  → Loop until [approve]

Layer 6: forge-test-guard
  → Every script must have a test
  → Changed script without test update → warned
```

---

## 6. Emergency Override

When the protocol is blocking legitimate work:

```
1. Document WHY the override is needed in the issue
2. Use forge-phase-gate.sh clear for gate override
3. Use git commit --no-verify for hook override (LAST RESORT)
4. Log the override in docs/forge-timeline.md
5. Create follow-up issue to fix whatever was skipped
6. Never leave an override unresolved
```

---

## Quick Reference

```bash
# Before changing anything:
python3 scripts/forge-registry.py --impact <file>
bash scripts/forge-ownership.sh who <file>
bash scripts/forge-enforce.sh check-suspect

# After changing:
bash scripts/forge-triangle.sh check
bash scripts/forge-test-guard.sh
bash scripts/forge-readme-sync.sh

# Before merging:
# CR must say [approve]
# Full test suite must pass
# No suspect REQs
```
