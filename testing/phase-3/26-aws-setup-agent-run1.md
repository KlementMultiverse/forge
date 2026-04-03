# Test: @aws-setup-agent — Run 1/10

## Input
Set up S3 bucket + Lambda function + IAM user for clinic-portal

## Score: 17/17 applicable (100%) — after fixes

### Core (items 1-15)
1. Single responsibility: PASS — "Creates S3 bucket, Lambda function, IAM user, generates .env"
2. Forge Cell referenced: PASS — AWS-specific (7-step: verify → research → create → verify → .env → gitignore → security)
3. context7 MCP: PASS — step 2
4. Web search: PASS — step 2
5. Self-executing: PASS — exact AWS CLI commands for every step, verification commands
6. Handoff protocol: PASS — custom 5-field AWS handoff + standard 6-field
7. [REQ-xxx]: PASS
8. Per-agent judge: PASS
9. Specific rules: PASS — extremely detailed (Step 0-5, error table with 6 failure modes)
10. Failure escalation: PASS — 6-row error handling table with specific actions
11. /learn: PASS
12. Anti-patterns: PASS — 6 items AWS-specific (no wildcard policies, no skipping verification)
13-15: N/A

### New (items 16-20)
16. Confidence routing: PASS — added
17. Self-correction loop: PASS — added
18. Negative instructions near end: PASS
19. Tool failure handling: PASS — EXCELLENT (6-row error handling table covers permission denied, bucket name taken, region mismatch, Lambda deploy failure, missing role, user exists)
20. Chaos resilience: PASS — error table handles edge cases (bucket name taken, user already exists)

## STRENGTH
The most operationally specific agent. Every AWS command is exact, verifiable, and handles failure.
6-row error table is production-grade. Step 0 states intent and waits for user confirmation.
The ONLY agent scoring 100% on the 20-point checklist.

## Verdict: EXCELLENT — PERFECT SCORE (100%)
