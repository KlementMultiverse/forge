# Universal Rules (apply to ALL projects)

Rules are annotated with governance level:
- `[MVP]` — enforce from day 1, even for prototypes
- `[Production]` — enforce when shipping to real users
- `[Enterprise]` — enforce for compliance-sensitive projects

## Core (Always On)

1. `[MVP]` All credentials from environment variables or .env — NEVER hardcoded
2. `[MVP]` Run tests after EVERY code change — never defer testing
3. `[MVP]` Format + lint after every code generation (black + ruff for Python)
4. `[MVP]` TDD: write test FIRST, then implement, then verify
5. `[MVP]` Root cause before fix — always /investigate before patching
6. `[MVP]` Max 3 reflexion attempts per issue — escalate if still failing
7. `[MVP]` Git commit at every state transition — auto-checkpoints
8. `[MVP]` After 2 failed corrections on same issue — fresh start with better prompt

## Quality (Production+)

9. `[Production]` Every state mutation must be auditable — no silent changes
10. `[Production]` State transitions enforced by validation dict — never skip validation
11. `[Production]` Presigned URLs for file access — never serve files directly
12. `[Production]` Every test references [REQ-xxx] from spec — no orphan tests
13. `[Production]` Every code module references [REQ-xxx] — no orphan code
14. `[Production]` API contracts defined in design doc Section 4 — both backend and frontend read them
15. `[Production]` Files must stay under 300 lines — split if exceeding
16. `[Production]` Every agent output gets judged (rated 1-5) before acceptance

## Zero Technical Debt

17. `[Production]` No TODO comments — implement now or create a GitHub Issue
18. `[Production]` No FIXME comments — fix now or create a GitHub Issue
19. `[Production]` No HACK comments — refactor properly
20. `[Production]` No commented-out code — delete it (git has history)
21. `[Production]` No deferred fixes — every fix is complete before commit

## Validation Tiers

22. `[MVP]` **Quick** (after each file change): ruff check only
23. `[Production]` **Full** (before each commit): ruff + black + full test suite
24. `[Enterprise]` **Comprehensive** (before PR): ruff + black + test + coverage + /audit-patterns + /security-scan

## Logging Standards

25. `[Production]` Log errors with full context (file, function, input that caused it)
26. `[Production]` Log external API calls (S3, Lambda, third-party) with duration
27. `[Production]` Log state mutations (who changed what, from what to what)
28. `[Production]` Log security events (login, failed auth, access denied, role change)
29. `[Production]` NEVER log: passwords, tokens, API keys, PII, session IDs

## Stop Protocol

30. `[MVP]` After 2 failed reflexion attempts → STOP, document what was tried, ask the user
31. `[MVP]` When local test and CI disagree → STOP, investigate environment difference first
32. `[MVP]` When agent output contradicts spec → STOP, re-read spec, do not proceed on assumption
