**Phase 4: Validate**

<system-reminder>
ENFORCEMENT CHECKPOINT — BEFORE Phase 4:
1. Run: `bash scripts/forge-enforce.sh check-gate 3` — Phase 3 gate MUST be passed
2. Run: `bash scripts/forge-enforce.sh check-docker` — Docker MUST be healthy
3. Run: `bash scripts/run-e2e.sh` — ALL tests (unit + e2e) MUST pass before validation
4. Update state: `bash scripts/forge-enforce.sh update-step 40 IN_PROGRESS`
5. If gate not passed → run /gate stage-3 first → THEN proceed
AUTO-CONTINUE: Do NOT stop to ask the user. Proceed through ALL Phase 4 steps.
</system-reminder>

STEP 40 — /sc:analyze
  Execute: `skill: "sc:analyze"`
  Verify: analysis report produced
  Trace: save to docs/forge-trace/040-analyze/

STEP 41 — /audit-patterns full
  Execute: `skill: "audit-patterns", args: "full"`
  Verify: pass rate > 90% — if not, fix top 5 failures then re-run
  Trace: save to docs/forge-trace/041-audit/

STEP 42 — /sc:test --coverage
  Execute: `skill: "sc:test", args: "--coverage"`
  Verify: tests pass, coverage report generated
  Trace: save to docs/forge-trace/042-coverage/

STEP 43 — traceability check
  Execute: `bash scripts/traceability.sh` via Bash
  Verify: 100% REQ coverage, 0 orphans, 0 drift
  If gaps → fix before proceeding
  Trace: save to docs/forge-trace/043-traceability/

STEP 44 — /security-scan
  Execute: `skill: "security-scan"`
  Verify: no CRITICAL or HIGH findings
  If found → fix → re-scan
  Trace: save to docs/forge-trace/044-security/

STEP 45 — /design-audit + /critic + E2E TESTS (MANDATORY if project has UI)
  Execute: `skill: "design-audit"` (if templates/ exist)
  Execute: `skill: "critic"` (if Playwright available)
  Execute: `skill: "sc:test", args: "--type e2e"` — MANDATORY, run Playwright e2e tests
  Execute: `docker compose exec web uv run python manage.py test` — MANDATORY, full unit test suite
  Verify: ALL tests pass (both unit and e2e)
  Trace: save to docs/forge-trace/045-design/

STEP 45b — /review (Phase 4 validation review — MANDATORY before gate)
  Execute: `skill: "review", args: "validation findings"`
  Review all fixes made during Phase 4 (from audit-patterns, security-scan, etc.)
  Verify: no regressions introduced by fixes, all tests still pass

STEP 46 — /gate stage-4
  Execute: `skill: "gate", args: "stage-4"`
  Verify: gate PASS
  Trace: save to docs/forge-trace/046-gate-s4/

**Phase 5: Review + Learn**

<system-reminder>
ENFORCEMENT CHECKPOINT — BEFORE Phase 5:
1. Run: `bash scripts/forge-enforce.sh check-gate 4` — Phase 4 gate MUST be passed
2. Update state: `bash scripts/forge-enforce.sh update-step 47 IN_PROGRESS`
AUTO-CONTINUE: Do NOT stop. Execute ALL steps 47-56 without pausing.
</system-reminder>

STEP 47 — /sc:cleanup
  Execute: `skill: "sc:cleanup"`
  Verify: dead code removed, no regressions (run tests)
  Trace: save to docs/forge-trace/047-cleanup/

STEP 48 — /sc:improve
  Execute: `skill: "sc:improve"`
  Verify: improvements applied, tests still pass
  Trace: save to docs/forge-trace/048-improve/

STEP 49 — /retro
  Execute: `skill: "retro"`
  Verify: `ls docs/retrospectives/*.md` → retro file exists
  Verify: CLAUDE.md Lessons Learned section updated
  STACK LEARNING FEEDBACK: After retro, append new learnings to the stack registry:
    ```bash
    STACK=$(grep -oP 'framework.*?:\s*\K\w+' CLAUDE.md | head -1 | tr '[:upper:]' '[:lower:]')
    STACK_LEARNINGS="$HOME/.claude/stacks/$STACK/learnings.md"
    if [ -f "$STACK_LEARNINGS" ]; then
      echo "" >> "$STACK_LEARNINGS"
      echo "## From $(basename $(pwd)) ($(date +%Y-%m-%d))" >> "$STACK_LEARNINGS"
    fi
    ```
    Read docs/retrospectives/*.md → extract stack-specific lessons → append to ~/.claude/stacks/{stack}/learnings.md
  Trace: save to docs/forge-trace/049-retro/

STEP 50 — /sc:reflect
  Execute: `skill: "sc:reflect"`
  Verify: task completion validated
  Trace: save to docs/forge-trace/050-reflect/

STEP 51 — /sc:document + @deploy-guide-agent
  Execute: `skill: "sc:document"`
  Execute: spawn Agent with subagent_type="general-purpose"
    prompt: "You are @deploy-guide-agent. Read CLAUDE.md, docker-compose.yml, Dockerfile, .env.example. Generate docs/DEPLOY.md with: prerequisites, quick-start (Docker exists vs not), env vars table, services table, common operations, making changes, troubleshooting, architecture diagram, health checks. Every command must be copy-pasteable. Under 200 lines."
  Verify: `ls docs/DEPLOY.md` → exists and has ## Quick Start section
  Trace: save to docs/forge-trace/051-document/

STEP 52 — @playbook-curator
  Execute: spawn Agent with subagent_type="general-purpose"
    prompt: "You are @playbook-curator. Read docs/retrospectives/*.md. Delta-update .forge/playbook/strategies.md with new entries. Check duplicates. Increment counters."
  Verify: playbook file updated
  Trace: save to docs/forge-trace/052-playbook/

STEP 53 — /prune + /evolve
  Execute: `skill: "prune"`
  Execute: `skill: "evolve"`
  Trace: save to docs/forge-trace/053-prune-evolve/

STEP 54 — /autoresearch (improve agent prompts from this build)
  Execute: `skill: "autoresearch"`
  Trace: save to docs/forge-trace/054-autoresearch/

STEP 55 — /sc:save
  Execute: `skill: "sc:save"`
  Trace: save to docs/forge-trace/055-save/

STEP 56 — /gate stage-5 → MERGE
  Execute: `skill: "gate", args: "stage-5"`
  Verify: gate PASS → merge PR
  Trace: save to docs/forge-trace/056-gate-final/

