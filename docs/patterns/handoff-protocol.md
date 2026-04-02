# Handoff Protocol — Standardized Agent Output Format

Every agent MUST return results in this exact format so the PM orchestrator can parse reliably.

## Mandatory Format

```markdown
## [Task Type] Completed

### Summary
[2-3 sentences: what was done, key decisions made]

### Components/Changes
- [File path]: [what changed and why]

### Requirements Covered
- [REQ-xxx]: [implemented / tested / both]

### Quality Status
- Tests: [pass count] / [total] passing
- Lint: [clean / N warnings]
- Rating: [1-5] (self-assessment before judge)

### Delegation Hints
- [Next logical step] → @[recommended agent]
- [Related work needed] → @[recommended agent]

### Risks/Blockers
- [Any issues discovered, blockers hit, or uncertainties]

### Files Created/Modified
- `path/to/file.py` — [purpose]
```

## Why This Format

1. **Summary** → PM knows what happened without reading code
2. **Components** → Traceability to exact files
3. **Requirements** → [REQ-xxx] sync verification
4. **Quality** → Quick pass/fail assessment
5. **Delegation** → Agent suggests who goes next (PM doesn't guess)
6. **Risks** → Nothing hidden, blockers surfaced early
7. **Files** → Exact scope of changes for /review and CodeRabbit

## Severity Tags (for reviews and issues)

When reporting issues, use severity tags:
- `[CRITICAL]` — Blocks production. Must fix before proceeding.
- `[HIGH]` — Should fix soon. Security or data integrity risk.
- `[MEDIUM]` — Technical debt. Fix before next release.
- `[LOW]` — Nice to have. Cosmetic or minor improvement.

## Rules

- NEVER skip the handoff format — PM orchestrator depends on it
- NEVER leave delegation hints empty — always suggest next step
- NEVER omit files list — it's the scope boundary for review
- Severity tags are mandatory when reporting issues
