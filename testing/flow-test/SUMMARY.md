# Flow Test Summary — Stage-by-Stage SDLC Evaluation

## Project Used: "Bookmark manager with tagging and AI-powered link summaries"

## Stages Tested

### Stage 0: PLAN ✅
- PM produced implementation plan table with 6 phases
- **Gap found**: No SPEC.md creation step when starting from scratch
- **Fix**: PM orchestrator's Phase 0 GENESIS handles this (/generate-spec), but clinic-portal CLAUDE.md skips it

### Stage 1: SPECIFY ✅ (80% ready for Stage 2)
- Produced 10 user stories, 8 acceptance criteria, 17 GitHub issues
- **Gaps found**: No API response schema examples, no pagination spec, no performance targets
- **Fix needed**: /specify template should mandate API Response Examples + Performance Targets sections

### Stage 2: ARCHITECT ✅ (75% implementation-ready)
- 10-section design doc, 8 design decisions, 30 test scenarios, exact API contracts
- **Gaps found**: Async Lambda flow incomplete (no callback endpoint), no settings.py skeleton, no error response standard, no Redis cache key patterns
- **Fix needed**: /design-doc template needs mandatory settings skeleton + error schema + async flow completeness check

### Stage 3: IMPLEMENT — Evaluation Only (55-90% depending on task)
- Phase 1 (Foundation) evaluated step by step
- **BLOCKING gaps**: TDD blocked without response schemas, SYNC blocked without [REQ-xxx] tags
- **Critical contradiction**: CSRF handling — CLAUDE.md says per-auth-class, design doc says NinjaAPI(csrf=True)
- **Ambiguity**: Register endpoint — single combined signup or two-step flow?

## Prompt Fixes Applied (5 total)

| Fix | Agent/Command | What Changed |
|---|---|---|
| 1 | @django-ninja-agent | Added CSRF verification step — check installed version's API before assuming |
| 2 | @backend-architect | Added API Contract Completeness checklist (schemas, errors, pagination, auth flow) |
| 3 | @system-architect | Added Flow Ambiguity Detection — no either/or, exact endpoint sequences required |
| 4 | @reviewer | Added Contradiction Detection — check design doc vs CLAUDE.md, block on conflicts |
| 5 | @pm-orchestrator | Added Traceability Enforcement — verify [REQ-xxx] tags at every stage gate |

## Key Insight
The BIGGEST weakness in the flow is the **handoff between stages**. Each stage produces good output in isolation, but the information that the NEXT stage needs is often missing or ambiguous. Specifically:
- Stage 1 → Stage 2: Missing API response schemas, pagination spec
- Stage 2 → Stage 3: Missing Pydantic Schema classes, error format standard, traceability tags
- The PM orchestrator doesn't verify completeness at stage boundaries

## Recommendation
Add a **handoff checklist** to each /gate command that verifies the OUTPUT of the current stage has everything the NEXT stage's INPUT requires. This is different from CodeRabbit review — it's about information completeness, not code quality.
