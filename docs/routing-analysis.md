# Forge Routing Analysis — All Scenarios

Comprehensive analysis of every scenario forge.md routing must handle.
Generated from CodeRabbit review (issue #117) + internal audit.

---

## Handled Scenarios (9)

| # | Scenario | Detection | Route | Status |
|---|----------|-----------|-------|--------|
| 1 | Empty folder (new project) | No CLAUDE.md, no code | CASE1 → phase-a-setup.md | ✅ |
| 2 | Has plan, no code | CLAUDE.md, no code files | CASE2 → cases.md | ✅ |
| 3 | Add feature | CLAUDE.md + code + "add/feature" | CASE3 → cases.md | ✅ |
| 4 | Fix bug | CLAUDE.md + code + "fix/bug" | CASE4 → cases.md | ✅ |
| 5 | Improve/refactor | CLAUDE.md + code + "improve" | CASE5 → cases.md | ✅ |
| 6 | Unclear intent | CLAUDE.md + code + empty args | CASE6 → ask user | ✅ |
| 7 | Brownfield (code, no forge) | Code exists, no CLAUDE.md | CASE7 → reverse-engineer | ✅ |
| 8 | Violation auto-fix | forge-state.json has violations | CASE8 → auto-fix | ✅ |
| 9 | Resume interrupted build | forge-state.json step 1-56 | CASE_RESUME → continue | ✅ |

---

## Critical Gaps (6) — Issues created

| # | Scenario | Issue | Problem |
|---|----------|-------|---------|
| 10 | Cloned/forked repo | #118 | No hooks/state installed for existing projects |
| 11 | Observer not configured | #119 | Gates block forever waiting for observer |
| 12 | Wrong directory | #120 | /forge in ~/  creates files in home dir |
| 13 | No reset/restart | #121 | Can't restart failed build, always resumes |
| 14 | git reset blocked | #122 | Hook blocks recovery, no escape path |
| 15 | forge-manifest.json missing | #123 | Referenced but doesn't exist, step count hardcoded |

---

## High Gaps (4) — To be addressed

| # | Scenario | Problem |
|---|----------|---------|
| 16 | Partial Phase A crash | Re-routes to CASE2, skips missing infra |
| 17 | Multiple branches | Approvals and state bleed across branches |
| 18 | Step 57 (complete) | check-continuation undefined for complete |
| 19 | CI/CD headless | forge-runner.py exists but unreachable from routing |

---

## Medium Gaps (6) — Future work

| # | Scenario | Problem |
|---|----------|---------|
| 20 | STEP 0 vs 0.5 priority | Violations may be skipped on resume |
| 21 | Missing sub-cases | Deploy/rollback/maintain not routed |
| 22 | Monorepo | No detection, corrupts root state |
| 23 | FORGE.md priority | No priority field for queued items |
| 24 | CASE 6 no loop-back | Session ends without next step |
| 25 | Failed build stuck | IN_PROGRESS not treated as violation |

---

## Detection Logic (current)

```text
Session starts → SessionStart hook (gh CLI, auth, remote, CLAUDE.md size)
    ↓
/forge typed → UserPromptSubmit hook (gated)
    ↓
forge-state.json exists AND step 1-56?
    YES → CASE_RESUME (early exit)
    ↓
CLAUDE.md exists?
    NO → code exists? → YES: CASE7_BROWNFIELD / NO: CASE1_GREENFIELD
    YES → has FORGE_TEMPLATE marker? → YES: CASE1_GREENFIELD(placeholder)
         → code exists? → NO: CASE2_SPEC_ONLY / YES: EXISTING_PROJECT
             → $ARGUMENTS: fix/bug→CASE4, add/feature→CASE3, improve→CASE5, unclear→CASE6
```

## File Extensions Detected

`.py .ts .tsx .jsx .js .go .rb .java .rs .php`

Excluded: `node_modules/ .venv/ .git/ vendor/ third_party/`

Search depth: `maxdepth 4`

---

## Phase File Routing

| Step Range | Phase File |
|------------|-----------|
| No CLAUDE.md | phase-a-setup.md |
| Steps 1-19 | phase-0-2-plan.md |
| Steps 20-39 | phase-3-implement.md |
| Steps 40-56 | phase-4-5-validate.md |
| CASE 2-8 | cases.md |
| Step 57 | Complete (check FORGE.md for queue) |
