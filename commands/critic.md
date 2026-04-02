# /critic — Autonomous Frontend Critic (Playwright)

Playwright-powered autonomous testing agent that maps the ENTIRE frontend, tests every flow in depth and breadth, auto-creates GitHub Issues for failures, and triggers the fix cycle with full spec↔test↔code sync.

## Input
$ARGUMENTS — base URL (e.g., "http://localhost:8000") or "all" for all pages

## Playwright Execution
Uses `/sc:test --type e2e` which activates the Playwright MCP server (built into SuperClaude).
The @playwright-critic agent writes the tests, `/sc:test` runs them via Playwright MCP.

## Execution

<system-reminder>
This is NOT a simple test runner. This is an AUTONOMOUS CRITIC that:
1. Maps every page, button, form, link, event in the frontend
2. Tests every path (depth-first AND breadth-first)
3. Auto-creates GitHub Issues for EVERY failure
4. Each issue triggers the internal fix cycle (NOT full /forge — just Phase 3)
5. Spec, test, code ALL update in sync for every fix
6. Runs in parallel — all files know when another file changes

The critic NEVER stops at "test failed." It creates the issue, triggers the fix, verifies the fix, and moves on.
</system-reminder>

### Step 1: MAP — Build the Frontend Graph

Playwright crawls every page and builds a complete map:

```
FRONTEND GRAPH
├── / (landing)
│   ├── [BUTTON] "Sign Up" → /register
│   ├── [BUTTON] "Login" → /login
│   └── [LINK] "Learn More" → #features
├── /login
│   ├── [FORM] email + password
│   ├── [BUTTON] "Login" → POST /api/auth/login → /dashboard
│   └── [LINK] "Register" → /register
├── /dashboard
│   ├── [CARD] "Workflows" → /workflows
│   ├── [CARD] "Documents" → /documents
│   ├── [NAV] "Staff" → /staff (admin only)
│   └── [STAT] task counts, recent actions
├── /workflows
│   ├── [BUTTON] "New Workflow" → dialog
│   ├── [LIST] workflow cards → /workflows/{id}
│   └── /workflows/{id}
│       ├── [LIST] tasks with status badges
│       ├── [BUTTON] "Transition" → PATCH /api/tasks/{id}/transition
│       ├── [BUTTON] "Assign" → PATCH /api/tasks/{id}/assign
│       └── [BUTTON] "AI Generate" → POST /api/tasks/generate
...continues for EVERY page
```

**Depth mapping:** For each page, map:
- All interactive elements (buttons, links, forms, dialogs)
- All states (empty, loading, populated, error)
- All user roles (admin sees X, staff sees Y, unauthenticated sees Z)
- All API calls triggered by each interaction
- All navigation paths (where does each click lead?)

**Breadth mapping:** For each element, map:
- Happy path (correct input → expected result)
- Error path (wrong input → error message)
- Empty path (no data → empty state)
- Auth path (logged out → redirect to login)
- Permission path (wrong role → access denied)

### Step 2: TEST — Execute Every Path

For each node in the graph, Playwright tests:

```
DEPTH TEST (vertical — follow one path to its end):
  Landing → Login → Dashboard → Workflows → Create → Tasks → Transition → AuditLog
  Landing → Register → Clinic Created → Dashboard → Documents → Upload → Summarize

BREADTH TEST (horizontal — test all options at each level):
  Dashboard: click Workflows ✓, click Documents ✓, click Staff ✓, click Search ✓, click Chat ✓
  Workflows: create ✓, edit ✓, delete ✓, transition all states ✓

EDGE TESTS (what breaks):
  Login with wrong password → error message displayed?
  Upload 0-byte file → validation error?
  XSS in form field → sanitized?
  Access admin page as staff → blocked?
  Click button twice rapidly → no duplicate?
  Very long text input → overflow handled?
  Empty data state → helpful message shown?
  Slow API response → loading indicator shown?
```

### Step 3: REPORT — Score Each Page

For every page, rate:

```
PAGE SCORE CARD: /workflows
├── Elements found: 12
├── Elements tested: 12 (100%)
├── Depth paths tested: 4/4
├── Breadth paths tested: 8/8
├── Edge cases tested: 6/6
├── Failures: 2
│   ├── [FAIL] "Transition button visible to staff user" — should be admin-only
│   └── [FAIL] "Empty workflow list shows 'Loading...' forever" — should show 'No workflows yet'
├── Score: 10/12 (83%)
└── Issues to create: 2
```

### Step 4: CREATE ISSUES — Auto-file for Every Failure

For each failure, automatically create a GitHub Issue:

```bash
gh issue create \
  --title "[Critic] {page}: {failure description}" \
  --body "$(cat <<'ISSUE'
## Found by /critic (Playwright autonomous testing)

**Page:** {url}
**Element:** {selector}
**Expected:** {what should happen}
**Actual:** {what actually happens}
**Screenshot:** {path to screenshot}

## Affected Requirements
- [REQ-xxx] {linked requirement}

## Fix Needed
- [ ] Update SPEC.md if requirement is missing
- [ ] Update test to cover this case
- [ ] Fix code
- [ ] Verify fix with Playwright re-test

## Traceability
- Spec: [REQ-xxx]
- Test: tests/{file}::{function}
- Code: {file}:{line}
ISSUE
)" \
  --label "critic,frontend,bug"
```

### Step 5: FIX CYCLE — Internal Loop (NOT full /forge)

<system-reminder>
The fix cycle is Phase 3 only — NOT the full /forge flow.
But ALL sync rules still apply:
- Spec updated if requirement was missing
- Test updated to cover the failure
- Code fixed
- Traceability verified
- Per-agent judge reviews the fix
- /learn if new insight discovered
</system-reminder>

For each critic issue (in parallel where independent):

```
Issue created by /critic
  │
  ├─► Check: does [REQ-xxx] exist for this behavior?
  │   NO → add requirement to SPEC.md
  │   YES → continue
  │
  ├─► Check: does a test exist for this case?
  │   NO → write Playwright test [REQ-xxx]
  │   YES → update existing test
  │
  ├─► Fix the code
  │   Domain agent implements the fix (TDD)
  │   Per-agent judge reviews (rate 1-5)
  │
  ├─► Sync check
  │   spec↔test↔code all reference same [REQ-xxx]
  │   traceability: 100%, 0 orphans, 0 drift
  │
  ├─► Re-run Playwright test for this specific failure
  │   PASS → close issue → /learn
  │   FAIL → reiterate (max 3) → escalate if stuck
  │
  └─► All files that changed → notify connected files
      (spec changed → tests know, code changed → spec knows)
```

### Step 6: VERIFY — Re-run Full Critic

After all issues are fixed:
1. Re-run the full /critic scan
2. Compare: new failures found?
   - YES → repeat from Step 4 (new issues → fix cycle)
   - NO → all frontend flows verified → DONE

## The Internal Sync Cycle

```
FILE A changes
  │
  ├─► hooks/PostToolUse detects change
  ├─► traceability.sh runs: which [REQ-xxx] are in this file?
  ├─► Find all OTHER files with same [REQ-xxx]
  ├─► Flag them: "dependent file changed — verify you're still in sync"
  │
  ├─► If spec changed → tests may need update → code may need update
  ├─► If test changed → verify code still passes → verify spec covers it
  ├─► If code changed → verify test still passes → verify spec covers it
  │
  └─► All changes happen in PARALLEL where independent
      Sequential only when one file depends on another's output
```

## Output

```markdown
# Critic Report: [project]

## Frontend Graph
- Pages mapped: [N]
- Elements found: [N]
- Paths tested: [N] (depth) + [N] (breadth) + [N] (edge)

## Results
- Total tests: [N]
- Passed: [N]
- Failed: [N]
- Issues created: [N]
- Issues auto-fixed: [N]
- Issues escalated: [N]

## Page Scores
| Page | Elements | Tested | Passed | Score |
|------|----------|--------|--------|-------|

## Sync Status
- Spec updated: [N] new [REQ-xxx] added
- Tests updated: [N] new test functions
- Code fixed: [N] files
- Traceability: [coverage]%
```

## When To Run
- Phase 4 (Validate) — after all implementation
- Phase 3 — after frontend phases
- Phase 6 (Iterate) — after any frontend fix
- On demand — `/critic` anytime to audit the frontend
