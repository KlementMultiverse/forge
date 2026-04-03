# REAL TEST: @refactoring-expert on clinic-portal

## Input
"Analyze apps/documents/api.py for refactoring opportunities"

## Real Findings: 6 issues

| # | Severity | Finding | Lines |
|---|---|---|---|
| 1 | HIGH | `_summarize_with_claude` is 130-line monolith mixing 4 concerns (S3 download, content routing, HTTP call, sanitization) — duplicates services.py | 24-153 |
| 2 | MEDIUM | Document lookup + tenant validation duplicated 3x with inconsistent tenant checks | 351-357, 379-382, 441-444 |
| 3 | MEDIUM | `summarize_document` endpoint mixes 6 concerns in 55 lines + double strip_tags() | 368-422 |
| 4 | LOW | Inconsistent error detail exposure (leaks vs swallows) | 405 vs 454 |
| 5 | LOW | Inline imports scattered throughout | 32-33, 140, 144, 301-302 |
| 6 | LOW | Magic numbers without named constants | 840, 86400, 10000 |

## Concrete Refactoring Proposals
1. Move _summarize_with_claude to services.py, split into 3 functions (~25 lines each)
2. Create _get_document_or_error() helper with consistent tenant validation
3. Extract summarize_document_service() to keep API layer thin

## Score: EXCELLENT — specific line numbers, concrete proposals, measured impact
