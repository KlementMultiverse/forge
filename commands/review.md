---
context: fork
---
# /review — Inline Code Review (Before PR)

Staff-engineer-level code review that runs BEFORE creating a PR. Catches issues that CodeRabbit misses — architecture violations, security gaps, incomplete implementations.

## Input
$ARGUMENTS — optional scope (e.g., "apps/workflows/" or "last commit")

## Execution

<system-reminder>
This is NOT a linting check. black + ruff already handle formatting.
This is a SENIOR ENGINEER review focused on:
- Completeness (does it fully implement the requirement?)
- Security (can this be exploited?)
- Architecture (does it follow the rules?)
- Edge cases (what happens when things go wrong?)
</system-reminder>

### Review Checklist

**Completeness:**
- [ ] All [REQ-xxx] referenced in the issue are implemented
- [ ] Tests exist for every new function/endpoint
- [ ] Error paths are handled (not just happy path)
- [ ] API contracts match design doc Section 4

**Security:**
- [ ] No hardcoded credentials
- [ ] Input validation on all endpoints
- [ ] Auth checks on protected routes
- [ ] LLM output sanitized before storage
- [ ] No SQL injection vectors
- [ ] No XSS vectors in templates

**Architecture:**
- [ ] Follows rules/ governance files
- [ ] Files under 300 lines
- [ ] No TODO/FIXME/HACK comments
- [ ] Imports are correct (no banned libraries)
- [ ] Consistent with existing patterns in codebase

**Edge Cases:**
- [ ] What if the database is down?
- [ ] What if the external API times out?
- [ ] What if the user sends empty/null input?
- [ ] What if the user is unauthorized?

### Mode: Fix-First
When issues are found:
1. If auto-fixable (import order, missing return type) → fix immediately
2. If needs design decision → flag for user
3. Each fix gets its own atomic commit

## Output

```markdown
# Code Review: [scope]

## Verdict: [CLEAN / ISSUES FOUND / BLOCKED]

## Issues
- [SEVERITY] [file:line] [description] [auto-fixed? yes/no]

## Stats
- Files reviewed: [N]
- Issues found: [N]
- Auto-fixed: [N]
- Needs attention: [N]
```
