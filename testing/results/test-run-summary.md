# Forge Agent Testing Summary

## Date: 2026-04-02
## Agents Tested: 13/33

## Scores

| Agent | Run 1 | After Fix | Issues Found |
|-------|-------|-----------|-------------|
| @deep-researcher | 9/12 | 11/12 | Missing delegation + /learn |
| @requirements-analyst | 11/12 | 12/12 | Missing /learn flag |
| @system-architect | 12/12 | — | Perfect |
| @reviewer | GAPS | 15-item checklist | Missing tenant/cache/logging checks |
| @context-loader | 11/12 | — | Minor: missing delegation |
| @security-engineer | 12/12 | — | Found 7 real security issues |
| @quality-engineer | 12/12 | — | Found REAL bug + spec deviation |
| @root-cause-analyst | 12/12 | — | Found transaction/DDL architecture issue |
| @playwright-critic | 11/12 | 12/12 | Must write executable code |
| @code-archaeologist | 10/12 | 12/12 | Missing /learn → fixed + verified |
| @api-architect | 12/12 | — | Perfect |
| @refactoring-expert | 11/12 | — | Minor: missing /learn |
| @learning-guide | 12/12 | — | Perfect |

## Prompt Fixes Applied (6 agents)
1. deep-researcher: delegation hints + playbook insights MANDATORY
2. requirements-analyst: /learn flag MANDATORY in output
3. reviewer: expanded 12→15 checklist (tenant, cache, logging)
4. playwright-critic: MUST write executable .py code, not descriptions
5. code-archaeologist: INSIGHT entries MANDATORY → verified in Run 2
6. All 30 agents: role-specific Forge Cell (earlier rounds)

## Real Issues Discovered

### In Clinic-Portal Codebase:
1. QuerySet.delete() bypasses AuditLog immutability (real bug)
2. Task transition: admin-only in code, "Any" in spec (deviation)
3. @transaction.atomic vs DDL: empty tenant schemas on failure
4. seed_demo.py swallows provision_tenant errors (except: pass)
5. 7 security issues in settings.py (2 CRITICAL)
6. .env with live AWS/Anthropic credentials on disk
7. 5 duplicated LLM call sites across 4 files
8. Test mocks reference old function (invoke_summarize_lambda)
9. Cache keys NOT tenant-aware (ID collision across tenants)
10. Two divergent LLM paths with different sanitization
11. Silent S3 deletion failure (except: pass)
12. No pagination on any list endpoint
13. 5 missing UI elements on /workflows/ page
14. Unauthenticated API tests expect 401 but get 302 (middleware redirect)

### In Forge Framework:
15. Reviewer was missing 3 critical checklist items
16. 12 non-implementer agents had wrong TDD instructions
17. Generic Forge Integration block contradicted read-only agents
18. No drift prevention patterns implemented

## Test Infrastructure Created
- testing/phase-0/ — 3 test results (discovery flow)
- testing/phase-3/ — 11 test results (implementation flow)
- testing/results/ — this summary

## Remaining: 20 agents need testing (10 runs each)
Priority: Django stack agents, business-panel, technical-writer, devops, performance
