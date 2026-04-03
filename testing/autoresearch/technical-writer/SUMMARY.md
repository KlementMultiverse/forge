# Technical Writer Agent -- 10-Run Autoresearch Summary

## Overall Scores

| Run | Topic | Score | Key Gap |
|-----|-------|-------|---------|
| 01 | API reference (workflows) | 6/10 | No request/response examples, no auth prerequisites |
| 02 | Onboarding guide (saleor) | 5/10 | No prerequisites, no verification checkpoints |
| 03 | Deployment guide (fastapi) | 5/10 | No security hardening, no rollback procedure |
| 04 | Plugin guide (medusa) | 4/10 | No architecture overview, no minimal example |
| 05 | ADR (multitenancy) | 6/10 | No ADR template, no alternatives analysis |
| 06 | GraphQL guide (saleor) | 4/10 | No GraphQL-specific patterns |
| 07 | Auth flow docs (fastapi) | 5/10 | No sequence diagrams, no security considerations |
| 08 | Contribution guide (medusa) | 4/10 | No monorepo-specific patterns, no PR workflow |
| 09 | Troubleshooting guide (clinic) | 6/10 | No symptom->fix format, no diagnostics |
| 10 | Data model docs (saleor) | 4/10 | No ER diagrams, no field catalog |

**Average Score: 4.9/10** (significantly lower than deep-researcher)

## Root Cause Analysis

The technical-writer prompt has THREE fundamental weaknesses:

### 1. No Document-Type-Specific Templates (Critical)
The prompt has ONE generic structure for all documentation types. But API references, ADRs, troubleshooting guides, deployment guides, onboarding guides, and data model docs all have DIFFERENT formats and required sections. The prompt should provide templates per document type.

### 2. No External Project Handling (High)
6 out of 10 runs targeted projects not available locally. The prompt's "empty codebase" chaos resilience is insufficient -- it should instruct the agent to use web search + official docs to research external projects before writing documentation.

### 3. No Visual/Diagram Generation (High)
Data model docs, auth flows, architecture decisions, and deployment guides all benefit from diagrams. The prompt mentions no diagramming capability (Mermaid, PlantUML, ASCII art).

## Recurring Gaps (by frequency across runs)

### HIGH PRIORITY (appeared in 5+ runs)
1. **No document-type-specific templates** -- generic structure produces generic docs. (All 10 runs)
2. **No request/response examples for API docs** -- "working examples" is too vague. (Runs 1,6,7)
3. **No prerequisites/setup section instruction** -- guides start without context. (Runs 2,3,4,8)
4. **No security considerations instruction** -- critical for auth, deployment, API docs. (Runs 3,7,9)
5. **No diagram generation instruction** -- missing visual documentation. (Runs 5,7,10)
6. **No verification checkpoint instruction** -- steps without validation. (Runs 2,3)

### MEDIUM PRIORITY (appeared in 3-4 runs)
7. **No error/troubleshooting format** -- symptom->cause->fix pattern missing. (Runs 1,9)
8. **No architecture overview before details** -- jumps into specifics without context. (Runs 2,4,5)
9. **No cross-referencing instruction** -- docs don't link to related docs. (Runs 5,7)
10. **No external project research fallback** -- can't document projects without code. (Runs 2,3,4,6,8,10)

### LOW PRIORITY (appeared in 1-2 runs)
11. No time estimate instruction (Run 2)
12. No escalation path (Run 9)
13. No version compatibility (Run 4)
14. No CI/CD integration (Run 3)

## Prompt Strengths (what works well)
1. **Code reading instruction** -- RESEARCH step correctly guides reading actual code
2. **Audience analysis** -- "developer new to this project" default is appropriate
3. **CROSS-CHECK with SPEC.md** -- ensures requirement coverage
4. **Chaos Resilience section** -- handles edge cases (empty code, no comments)
5. **VERIFY step** -- instructs running code examples (though not enforced enough)

## Fixes Applied to Prompt
See the updated prompt file for all changes. Key additions:
1. Document-type-specific templates (API ref, ADR, deployment, troubleshooting, onboarding, data model)
2. Diagram generation instruction (Mermaid syntax)
3. Request/response example requirement
4. Security considerations instruction
5. External project research fallback
6. Verification checkpoint enforcement
7. Symptom->cause->fix troubleshooting format
