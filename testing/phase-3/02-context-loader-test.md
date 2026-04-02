# Test: @context-loader-agent (Run 1/10)

## Input
"Fetch docs for Django Ninja session auth + CSRF + django-tenants middleware"

## Score: 11/12 (92%)

| # | Criterion | Result |
|---|-----------|--------|
| 1 | Called context7 MCP | PASS — 3 calls made |
| 2 | Real doc excerpts pasted | PASS — actual code examples from django-ninja docs |
| 3 | Version warnings noted | PASS — v1 CSRF breaking change identified |
| 4 | 5-field format used | PASS |
| 5 | CLAUDE.md rules cited | PASS — Rules 1, 3, 4, 16 cited with quotes |
| 6 | Failure log | PASS — "All queries succeeded" |
| 7 | Delegation hint | FAIL — no "Next: @agent should..." |

## Key Finding
Context-loader correctly identified the django-ninja v1 CSRF breaking change,
validating CLAUDE.md Rule 16. This is exactly the kind of version gotcha
that would cause bugs without context7.

## Action: Add delegation hint requirement
