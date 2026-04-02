# Forge Constitution — Single Source of Truth

All governance rules in 10 articles. Progressive levels: `[MVP]` / `[Production]` / `[Enterprise]`.

---

## Article 1: Git Workflow `[MVP+]`
1.1 All changes through feature branches and PRs — no direct commits to main
1.2 Branch naming: `feature/`, `fix/`, `docs/`, `refactor/`
1.3 Conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`
1.4 Main branch protection required `[Production+]`

## Article 2: Documentation `[Production+]`
2.1 Feature proposal required before implementation
2.2 Retrospective required BEFORE creating PR
2.3 Retrospective contents: what went well, improvements (with root cause), lessons learned, changes made
2.4 Update retrospective after every significant change (not just at end)

## Article 3: Architecture `[Production+]`
3.1 Design document required before code (10 sections, "Will implement X because" format)
3.2 API contracts in design doc Section 4 (exact request/response/error shapes)
3.3 Start with hardest integrations first
3.4 Bootstrap exception: fresh projects can defer architecture docs during scaffold

## Article 4: Code Quality `[MVP+]`
4.1 No TODO, FIXME, HACK comments `[Production+]`
4.2 No commented-out code — use version control `[Production+]`
4.3 Error handling required for all operations — no suppressing exceptions
4.4 No "temporary" solutions or deferred fixes `[Production+]`
4.5 Files must stay under 300 lines — split if exceeding
4.6 Every function/endpoint must have at least one test

## Article 5: Validation `[MVP+]`
5.1 Quick validation after writing code (lint only)
5.2 Full validation before commits (lint + test suite) `[Production+]`
5.3 Comprehensive validation before PR (lint + test + coverage + audit + security) `[Production+]`
5.4 Zero technical debt threshold `[Production+]`
5.5 Traceability: every [REQ-xxx] has test + code (100% coverage, 0 orphans, 0 drift)

## Article 6: Agent Collaboration `[MVP+]`
6.1 Check for relevant specialist agents before significant work
6.2 Orchestrator coordinates — agents never call each other directly
6.3 Every agent output follows handoff protocol (docs/patterns/handoff-protocol.md)
6.4 Every agent output reviewed by per-domain judge (rated 1-5, accept ≥4)
6.5 Agents suggest who to call next (delegation hints)
6.6 Max 3 reflexion attempts — then STOP and ask user

## Article 7: Logging `[Production+]`
7.1 10 required logging points: function entry/exit, errors, external calls, state mutations, security events, business milestones, performance anomalies, config changes, validation failures, resource limits
7.2 NEVER log: passwords, tokens, API keys, PII, session IDs, biometrics

## Article 8: Security `[MVP+]`
8.1 Never store secrets in code — use environment variables
8.2 Validate and sanitize all external input
8.3 LLM output treated as untrusted — sanitize before storage/display
8.4 Presigned URLs for file access — never serve files directly
8.5 Tenant data isolation enforced at database level
8.6 CSRF protection on all state-changing endpoints

## Article 9: Self-Review `[MVP+]`
9.1 Review all artifacts against requirements before presenting
9.2 Use systematic solutions — not magic number patches
9.3 Root cause before fix — always /investigate before patching
9.4 After 2 failed corrections → STOP, document, ask user

## Article 10: Progressive Levels
10.1 **MVP** — Quick exploration. TODOs allowed. Basic validation. Direct commits OK.
10.2 **Production** — Real users. Zero tech debt. Full validation. All architecture docs. Gate tests blocking.
10.3 **Enterprise** — Regulated environments. Compliance docs. Audit trails. Multiple reviewers. Maximum rigor.
10.4 Don't over-engineer MVPs. Don't under-engineer production.
