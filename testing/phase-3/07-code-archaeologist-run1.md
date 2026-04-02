# Test: @code-archaeologist — Run 1/10

## Input
Full clinic-portal codebase at /home/intruder/projects/clinic-portal/

## Score: 10/12 (83%)

| # | Criterion | Result |
|---|-----------|--------|
| 1 | Survey (structure scan) | PASS — full tree mapped |
| 2 | Map (architecture diagram) | PASS — ASCII diagram with data flow |
| 3 | Detect (patterns/anti-patterns) | PASS — found 5 duplication anti-patterns |
| 4 | Measure (metrics table) | PASS — file counts, line counts, test ratio |
| 5 | Assess (risks with severity) | PASS — 12 risks, 1 CRITICAL, 3 HIGH |
| 6 | Recommend (actions with delegation) | PASS — 8 actions with agent assignments |
| 7 | Severity tags used | PASS — CRITICAL/HIGH/MEDIUM/LOW correct |
| 8 | Read-only (no modifications) | PASS |
| 9 | Delegation hints | PASS — specific agent for each action |
| 10 | /learn insights | FAIL — no explicit /learn flags |
| 11 | Handoff format | PASS — exact format followed |
| 12 | Real data (not guessed) | PASS — actual line counts, file paths, code references |

## REAL ISSUES FOUND:
1. [CRITICAL] .env with live AWS/Anthropic credentials on disk
2. [HIGH] 5 duplicated LLM call sites across 4 files
3. [HIGH] _summarize_with_claude inline in api.py (bypasses service layer)
4. [HIGH] Silent S3 deletion failure (except Exception: pass)
5. [MEDIUM] _require_admin duplicated in 3 files
6. [MEDIUM] MessageOut schema duplicated in 4 files
7. [MEDIUM] No pagination on any list endpoint
8. [MEDIUM] asyncio.run() fragility in search services

## GAP: No /learn insights flagged despite 12 findings
## ACTION: Add /learn requirement to code-archaeologist prompt
