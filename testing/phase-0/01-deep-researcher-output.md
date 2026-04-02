# Test: @deep-researcher — /discover

## Input
"I want to build a clinic management portal for medical practices"

## Evaluation (12 criteria)

| # | Criterion | Result | Notes |
|---|-----------|--------|-------|
| 1 | Actually searched (not training data) | PASS | 15+ real sources cited with URLs |
| 2 | Sources real and cited | PASS | Verified Market Research, Becker's, MGMA, G2 — all real |
| 3 | Target users SPECIFIC | PASS | 4 specific user types with context (owner-operators, office managers, clinical staff, multi-location groups) |
| 4 | Current solutions NAMED | PASS | Tebra, Athenahealth, Practice Fusion, Jane App, ClinicMind — with pricing |
| 5 | Insights NON-OBVIOUS | PASS | "Real competitor is spreadsheets" + "Multi-tenancy is strategic moat" + "Excluding EHR is a feature" |
| 6 | Handoff format used | PASS | Followed discovery report format exactly |
| 7 | Market data included | PASS | $12.7B market, 9.8% CAGR, $150B no-show cost |
| 8 | Delegation hints | FAIL | No "next agent to call" suggestion |
| 9 | [REQ-xxx] tags | FAIL | No requirement tags (not expected at this stage — discovery is pre-spec) |
| 10 | Context poisoning check | PASS | No contradictions, no confusion between sections |
| 11 | Actionable for next stage | PASS | Clear problem + users + opportunity = ready for /requirements |
| 12 | /learn insights flagged | FAIL | No /learn suggestions despite 6 non-obvious insights |

## Score: 9/12 (75%)

## Issues to Fix in Agent Prompt
1. Missing delegation hints ("Next: @requirements-analyst for [REQ-xxx] extraction")
2. Missing /learn flag for non-obvious insights
3. [REQ-xxx] not applicable at this stage — but should note "Requirements will be tagged in next step"

## Agent Prompt Improvement Needed
- Add: "End your report with: Delegation: @requirements-analyst should extract [REQ-xxx] from these findings"
- Add: "Flag any non-obvious insight for /learn: 'INSIGHT FOR PLAYBOOK: [text]'"
