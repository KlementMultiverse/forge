**Phase 0: Genesis**

STEP 1 — /discover
  Execute: `skill: "discover", args: "$ARGUMENTS"`
  Verify: `ls docs/discovery-report.md` → file exists, >500 bytes
  Trace: save to docs/forge-trace/001-discover/
  If missing → step failed → retry

STEP 2 — /requirements
  Execute: `skill: "requirements", args: "docs/discovery-report.md"`
  Verify: `grep -c "REQ-" docs/requirements.md` → at least 15 REQs
  Trace: save to docs/forge-trace/002-requirements/
  If <15 REQs → step incomplete → retry with "need more requirements"

STEP 3 — /feasibility
  Execute: `skill: "feasibility", args: "docs/requirements.md"`
  Verify: `ls docs/feasibility.md` → file exists
  ASK USER: "Recommended: [stack]. Confirm? (yes/change)"
  Trace: save to docs/forge-trace/003-feasibility/

STEP 4 — /generate-spec
  Execute: `skill: "generate-spec"`
  Verify: `grep -c "REQ-" SPEC.md` → at least 15 REQs in SPEC
  Verify: SPEC.md has ## Models, ## API Endpoints, ## Tech Stack sections
  Trace: save to docs/forge-trace/004-generate-spec/
  If SPEC incomplete → retry

STEP 5 — /challenge
  Execute: `skill: "challenge", args: "SPEC.md"`
  Verify: output contains PROCEED or REFINE or RETHINK
  If RETHINK → STOP, ask user
  If REFINE → update SPEC → re-run /challenge (max 2)
  Trace: save to docs/forge-trace/005-challenge/

STEP 6 — /bootstrap
  Execute: `skill: "bootstrap"`
  Verify: `ls manage.py pyproject.toml Dockerfile docker-compose.yml config/settings.py` → all exist
  Trace: save to docs/forge-trace/006-bootstrap/
  If any missing → step failed → retry

STEP 7 — /checkpoint
  Execute: `skill: "checkpoint", args: "phase-0 | Genesis complete"`
  Trace: save to docs/forge-trace/007-checkpoint-p0/

STEP 8 — /gate phase-0
  Execute: `skill: "gate", args: "phase-0"`
  Verify: gate output says PASS
  If BLOCKED → fix issues → re-run /gate
  Trace: save to docs/forge-trace/008-gate-p0/

**Phase 1: Specify**

STEP 9 — /specify
  Execute: `skill: "specify", args: "SPEC.md"`
  Verify: `ls docs/proposals/01-*.md` → proposal exists
  Verify: proposal has ## Acceptance Criteria with Given/When/Then
  Trace: save to docs/forge-trace/009-specify/

STEP 10 — /checkpoint
  Execute: `skill: "checkpoint", args: "specify | proposal created"`
  Trace: save to docs/forge-trace/010-checkpoint-s1/

STEP 11 — /gate stage-1
  Execute: `skill: "gate", args: "stage-1"`
  Verify: gate PASS
  Trace: save to docs/forge-trace/011-gate-s1/

**Phase 2: Architect**

STEP 12 — /plan-review
  Execute: `skill: "plan-review", args: "docs/proposals/01-*.md"`
  Verify: review output exists with feedback
  Trace: save to docs/forge-trace/012-plan-review/

STEP 13 — @api-architect (API contracts)
  Execute: spawn Agent with subagent_type="general-purpose"
    prompt: "You are @api-architect. Read docs/proposals/01-*.md and SPEC.md. Design API contracts for every endpoint: method, path, request JSON, response JSON, error codes, Pydantic schemas."
  Verify: output has endpoint tables with JSON shapes
  Trace: save to docs/forge-trace/013-api-contracts/

STEP 14 — /design-doc
  Execute: `skill: "design-doc", args: "docs/proposals/01-*.md"`
  Verify: `ls docs/design-doc.md` → exists, >5000 bytes
  Verify: has all 10 sections (## 1. through ## 10.)
  Verify: has "Will implement" decisions (at least 8)
  Verify: has Pydantic Schema classes
  Verify: has test scenarios (at least 15)
  Trace: save to docs/forge-trace/014-design-doc/
  If any verify fails → retry with specific feedback

STEP 15 — /plan-tasks
  Execute: `skill: "plan-tasks", args: "docs/design-doc.md"`
  Verify: `ls docs/issues/*.md | wc -l` → at least 10 issue files
  Verify: each issue has [REQ-xxx] reference
  Trace: save to docs/forge-trace/015-plan-tasks/

STEP 16 — /sc:estimate
  Execute: `skill: "sc:estimate", args: "docs/design-doc.md"`
  Verify: effort estimates per phase exist
  Trace: save to docs/forge-trace/016-estimate/

STEP 17 — /sc:workflow
  Execute: `skill: "sc:workflow", args: "docs/design-doc.md"`
  Verify: dependency ordering validated
  Trace: save to docs/forge-trace/017-workflow/

STEP 18 — /checkpoint
  Execute: `skill: "checkpoint", args: "architect | design doc + tasks created"`
  Trace: save to docs/forge-trace/018-checkpoint-s2/

STEP 19 — /gate stage-2
  Execute: `skill: "gate", args: "stage-2"`
  Verify: gate PASS
  Trace: save to docs/forge-trace/019-gate-s2/

