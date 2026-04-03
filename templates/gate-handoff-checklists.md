# Gate Handoff Checklists

Each stage must pass its handoff checklist BEFORE /gate allows progression.

## Gate: Stage 1 -> Stage 2 (SPECIFY -> ARCHITECT)
The proposal MUST contain:
- [ ] User stories with [REQ-xxx] tags
- [ ] Acceptance criteria in Given/When/Then format (minimum 5)
- [ ] [NEEDS CLARIFICATION] items with default assumptions
- [ ] Implementation phases with dependency order
- [ ] Risk table with probability x impact x mitigation
- [ ] API endpoint list (method, path, auth, purpose)
- [ ] Model list with key fields

## Gate: Stage 2 -> Stage 3 (ARCHITECT -> IMPLEMENT)
The design doc MUST pass the completeness checklist above. Additionally:
- [ ] Pydantic Schema classes defined for ALL endpoints
- [ ] Error response format is ONE standard shape
- [ ] Every async flow has both trigger and callback specified
- [ ] settings.py skeleton is copy-paste ready
- [ ] Dockerfile is copy-paste ready
- [ ] [REQ-xxx] tags flow from proposal through design doc

## Gate: Stage 3 -> Stage 4 (IMPLEMENT -> VALIDATE)
- [ ] All GitHub issues from /plan-tasks are closed
- [ ] All tests pass: `uv run python manage.py test`
- [ ] Lint clean: `black --check . && ruff check .`
- [ ] Every [REQ-xxx] has: test + code + design doc reference
- [ ] No orphan code (code without [REQ-xxx])
- [ ] AuditLog covers all mutations (if applicable)

## Gate: Stage 4 -> Stage 5 (VALIDATE -> REVIEW)
- [ ] /audit-patterns full > 90%
- [ ] /sc:test --coverage meets target
- [ ] Security scan clean (no CRITICAL/HIGH)
- [ ] Traceability: 100% coverage, 0 orphans, 0 drift

## Gate: Stage 5 -> Done (REVIEW -> MERGE)
- [ ] Retrospective written (docs/retrospectives/)
- [ ] CLAUDE.md updated with lessons learned
- [ ] Playbook updated (strategies + mistakes)
- [ ] PR created with CodeRabbit review
- [ ] CodeRabbit: 0 suggestions remaining
