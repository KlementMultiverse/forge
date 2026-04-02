# /qa-report — Bug Report (No Fixes)

Pure bug reporting without code changes. Find and document issues — don't fix them. Creates GitHub Issues for each bug found.

## Input
$ARGUMENTS — scope (e.g., "frontend", "api", "auth", "all")

## Execution

<system-reminder>
This command ONLY reports bugs. It does NOT fix them.
Fixes come through the normal Forge Cell flow (issue → implement → review → gate).
</system-reminder>

### What To Check

**Frontend (via Playwright):**
- Every page loads without errors
- All buttons/links work
- Forms validate correctly
- Error messages show properly
- Empty states display helpful messages
- Loading states appear during async ops
- Mobile responsive (320px, 768px, 1280px)
- Keyboard navigation works
- No console errors

**API:**
- Every endpoint returns correct status codes
- Validation errors return helpful messages
- Auth failures return 401/403 (not 500)
- Rate limiting works
- CORS headers correct

**Security:**
- XSS: script tags sanitized in all inputs
- CSRF: tokens present on all forms
- Auth: unauthenticated users can't access protected pages
- Permissions: staff can't do admin actions

**Data:**
- Empty database: app doesn't crash
- Large data: pagination works
- Concurrent access: no race conditions

### For Each Bug Found

Auto-create GitHub Issue:
```bash
gh issue create \
  --title "[QA] [severity] [page/endpoint]: [description]" \
  --body "## Bug Report (from /qa-report)

**Severity:** [CRITICAL/HIGH/MEDIUM/LOW]
**Location:** [URL or endpoint]
**Steps to Reproduce:**
1. [step]
2. [step]
**Expected:** [what should happen]
**Actual:** [what actually happens]
**Screenshot:** [if applicable]
**Related:** [REQ-xxx] if known

## Fix Requirements
- [ ] Spec updated if requirement missing
- [ ] Test added to prevent regression
- [ ] Code fixed
- [ ] Verified with re-test" \
  --label "qa,bug,[severity]"
```

## Output

```markdown
## QA Report: [scope] — [date]

### Summary
- Pages tested: [N]
- Endpoints tested: [N]
- Bugs found: [N]
- Issues created: [N]

### By Severity
- CRITICAL: [N]
- HIGH: [N]
- MEDIUM: [N]
- LOW: [N]

### Bug List
| # | Severity | Location | Description | Issue |
|---|----------|----------|-------------|-------|
```

## When To Run
- Phase 4: as part of validation
- Phase 6: after fixes to verify no regressions
- On demand: before any demo or release
