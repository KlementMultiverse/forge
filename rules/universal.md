# Universal Rules (apply to ALL projects)

1. All credentials from environment variables or .env — NEVER hardcoded
2. Run tests after EVERY code change — never defer testing
3. Every state mutation must be auditable — no silent changes
4. State transitions enforced by validation dict — never skip validation
5. Presigned URLs for file access — never serve files directly from storage
6. Format + lint after every code generation (black + ruff for Python)
7. TDD: write test FIRST, then implement, then verify
8. Every test references [REQ-xxx] from spec — no orphan tests
9. Every code module references [REQ-xxx] — no orphan code
10. Root cause before fix — always /investigate before patching
11. Max 3 reflexion attempts per issue — escalate if still failing
12. API contracts defined in design doc Section 4 — both backend and frontend read them
13. Files must stay under 300 lines — split if exceeding
14. Every agent output gets judged (rated 1-5) before acceptance
15. Git commit at every state transition — auto-checkpoints
