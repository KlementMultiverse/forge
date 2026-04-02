# Test: @playwright-critic (Run 1/10)

## Input
/workflows/ page HTML with workflow list, create button, view tasks button

## Score: 11/12 (92%)

## Key Findings:
1. DEPTH PATHS: 5 complete journeys mapped (login→workflow→task→transition→audit)
2. BREADTH PATHS: 7 elements tested on single page
3. EDGE CASES: 10 edge cases identified (XSS, empty state, rapid click, slow network)
4. AUTH PATHS: 6 scenarios (unauth, staff, admin, cross-tenant, session expiry)
5. TESTABILITY RATING: 6/10 — identified 10 missing UI elements

## REAL ISSUES FOUND (would create GitHub Issues):
- W2: No edit/delete UI for workflows (SPEC says PUT/DELETE exist)
- W3: No empty state markup (user sees blank)
- W6: "New Workflow" button visible to staff (should be admin-only)
- W9: No ARIA labels on buttons (accessibility gap)
- W4: No loading spinner during async fetch

## Missing from agent output:
- Didn't generate actual Playwright test code (only described tests)
- Should produce executable test file, not just descriptions

## Action: Agent prompt should require EXECUTABLE test code, not just test descriptions
