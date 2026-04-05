**Phase 3: IMPLEMENT (per issue — strict agent separation)**

<system-reminder>
ENFORCEMENT CHECKPOINT — BEFORE Phase 3:
1. Run: `bash scripts/forge-enforce.sh check-gate 2` — Phase 2 gate MUST be passed
2. Run: `bash scripts/forge-enforce.sh check-docker` — all services MUST be healthy
3. Run: `bash scripts/docker-state.sh` — capture Docker state for agent prompts
4. If any check fails → FIX FIRST → do NOT proceed

STRICT AGENT SEPARATION — MANDATORY AND ENFORCED:
- SPEC agent and CODE agent are DIFFERENT agents
- TEST agent and CODE agent are DIFFERENT agents
- TEST agent reads SPEC (not code) to write tests
- CODE agent reads SPEC + design doc + test expectations to write code
- REVIEW agent judges every output independently
- NO agent does more than ONE job per step
- PM NEVER writes to apps/**/*.py — Hook will warn on violation

AGENT ROUTING (from .claude/rules/agent-routing.md):
- apps/tenants/ → @django-tenants-agent
- apps/users/ → @django-ninja-agent
- apps/search/ → @backend-architect
- apps/documents/ → @s3-lambda-agent + @django-ninja-agent
- apps/conversations/ → @llm-integration-agent + @s3-lambda-agent
- apps/audit/ → @django-tenants-agent
- templates/ → /sc:implement
- tests → @quality-engineer (reads SPEC.md ONLY)

TDD CYCLE — MANDATORY:
1. @quality-engineer writes tests from SPEC.md → tests MUST FAIL
2. Domain agent (from .claude/rules/agent-routing.md) writes code → tests MUST PASS
3. Full suite → NO regressions
If tests pass at step 1 → INVESTIGATE before coding

PER-ISSUE COMMITS — MANDATORY:
Each issue = one commit: `feat(<app>): <description> [REQ-xxx]`
NEVER batch multiple issues into one monolithic commit.

This prevents:
- Tests that are designed to pass (written after code)
- Specs that are reverse-engineered from implementation
- Code that ignores the spec because same agent wrote both
- Monolithic commits that are impossible to review or revert
</system-reminder>

For EACH issue in dependency order, execute this chain.
Use N = issue number (e.g., issue 1 = steps 100-109, issue 2 = 110-119).

STEP N0 — TASK DESIGN DOC
  Execute: spawn Agent with subagent_type="backend-architect"
    prompt: "Read SPEC.md [REQ-xxx] for issue #{N} and design-doc Section 4. Write a task design doc: files to change, model fields, API contract, error format. Use templates/task-design-doc.template.md format."
  Verify: output contains "## Files to Change" and "## API Contract"
  Trace: docs/forge-trace/{N}0-design/

STEP N1 — CONTEXT LOAD
  Execute: spawn Agent with subagent_type="context-loader-agent"
    prompt: "Fetch library docs for this issue's stack via context7 MCP: {libraries from agent-routing.md}"
  Verify: agent reports docs fetched (not "unavailable")
  Trace: docs/forge-trace/{N}1-context/

STEP N2 — WRITE SPEC ENTRY
  Execute: spawn Agent with subagent_type="requirements-analyst"
    prompt: "Read task design doc from step N0. Add [REQ-xxx] to SPEC.md with Given/When/Then acceptance criteria."
  Verify: `grep -c "REQ-" SPEC.md` increased by at least 1
  Trace: docs/forge-trace/{N}2-spec/

STEP N3 — WRITE TESTS (from SPEC, NOT from code)
  Execute: spawn Agent with subagent_type="quality-engineer"
    prompt: "Read SPEC.md [REQ-xxx] for issue #{N} and the task design doc. Write tests in a DOMAIN-SPECIFIC test file: apps/{app}/tests_{domain}.py (e.g., tests_models.py, tests_api.py, tests_discovery.py). NEVER put all tests in one tests.py — split by domain. Each file MUST stay under 300 lines. Do NOT read any implementation code. Every test has [REQ-xxx] in docstring. Minimum 5 tests."
  Verify: test file under 300 lines (split if needed)
  Execute: `uv run python manage.py test apps.{app}` via Bash
  Verify: tests FAIL (code doesn't exist yet — if they PASS, something is wrong)
  Trace: docs/forge-trace/{N}3-tests/

STEP N4 — WRITE CODE
  Execute: spawn Agent with subagent_type="{domain-agent}" (from agent-routing.md)
    prompt: "Read SPEC.md [REQ-xxx], task design doc, and test file. Write models/api/services/schemas to make tests pass. Every function has [REQ-xxx] comment. Use context7 docs from step N1."
  Verify: `uv run python manage.py test apps.{app}` → ALL PASS via Bash
  Verify: `uv run python manage.py test` → ALL tests pass (no regression) via Bash
  If FAIL: agent retries (max 3)
  If still FAIL: spawn Agent with subagent_type="root-cause-analyst"
  Trace: docs/forge-trace/{N}4-code/

STEP N5 — LINT (hook-enforced, automatic)
  Happens via PostToolUse hook on every Write/Edit

STEP N6 — SYNC CHECK
  Execute: `bash scripts/traceability.sh` via Bash
  Verify: output shows 100% for this issue's [REQ-xxx] tags
  If gap found: STOP — fix before proceeding
  Trace: docs/forge-trace/{N}6-sync/

STEP N7 — SECURITY SCAN
  Execute: spawn Agent with subagent_type="security-engineer"
    prompt: "Review the code changes for issue #{N}. Check: input validation, auth, no hardcoded secrets, error exposure, tenant isolation."
  Verify: no CRITICAL or HIGH findings
  If found: fix before commit
  Trace: docs/forge-trace/{N}7-security/

STEP N8 — REVIEW (per-issue inline review — MANDATORY)
  Execute: spawn Agent with subagent_type="reviewer"
    prompt: "Review code for issue #{N}. Rate 1-5.
    CHECK: tests cover [REQ-xxx] acceptance criteria, code matches spec, no orphan code,
    no hardcoded secrets, files <300 lines, no TODO/FIXME, error paths handled,
    auth checks on protected routes, LLM output sanitized.
    If rating <4: list EXACT fixes needed. If >=4: approve."
  Verify: rating >= 4
  If < 4: fix issues → re-run review (max 3 iterations)
  Trace: docs/forge-trace/{N}8-review/

STEP N9 — COMMIT + LEARN
  Execute: `git add apps/{app}/ && git commit -m "feat({app}): {description} [REQ-xxx]"` via Bash
  Execute: update FORGE.md — move item from Active to Done
  Execute: `skill: "checkpoint", args: "{agent} | issue #{N} complete"`
  Execute: `skill: "learn", args: "{any non-obvious pattern discovered}"` (if applicable)
  Trace: docs/forge-trace/{N}9-commit/

23. After each phase group:
    - /review (inline code review of ALL changes in this phase)
    - /gate (PR + CodeRabbit or manual checklist)
    - Log to timeline

STEP 37 — /review (phase-level inline code review — MANDATORY before gate)
  Execute: `skill: "review", args: "all changes since last gate"`
  This reviews ALL code written in Phase 3 as a whole:
    - Cross-issue consistency (naming, patterns, imports)
    - API contract alignment with design-doc.md Section 4
    - Tenant isolation across all apps
    - No duplicate logic between issues
    - Test coverage gaps across the full suite
  Verify: review produces report with 0 CRITICAL, 0 HIGH findings
  If issues found: fix → re-run review
  Execute: `bash scripts/forge-enforce.sh update-step 37 DONE`
  Trace: save to docs/forge-trace/037-review-s3/

STEP 38 — /checkpoint phase-3
  Execute: `skill: "checkpoint", args: "phase-3 | Implementation complete"`
  Execute: `bash scripts/forge-enforce.sh update-step 38 DONE`
  Trace: save to docs/forge-trace/038-checkpoint-s3/

STEP 39 — /gate stage-3 (MANDATORY — blocks Phase 4)
  Execute: `skill: "gate", args: "stage-3"`
  Verify: gate PASS
  Execute: `bash scripts/forge-enforce.sh update-gate 3`
  Execute: `bash scripts/forge-enforce.sh update-step 39 DONE`
  If FAIL → fix issues → re-run /gate
  Trace: save to docs/forge-trace/039-gate-s3/

  **PHASE 3→4 TRANSITION:**
  1. Verify: `bash scripts/forge-enforce.sh check-gate 3` → MUST be PASSED
  2. Verify: `bash scripts/docker-state.sh --check` → DOCKER_HEALTHY
  3. Run: `bash scripts/run-e2e.sh` → unit + e2e tests MUST pass
  4. Update: `bash scripts/forge-enforce.sh update-step 40 IN_PROGRESS`
  5. Continue to Phase 4 immediately — DO NOT STOP

