# Test: @aws-setup-agent — Run 2 (re-eval after chaos section added)

## Input (DIFFERENT from Run 1)
Set up AWS resources for a new project in eu-west-1 with existing IAM user

## Score: 17/17 (100%)

1-12: All PASS (was already 100%)
16. Confidence routing: PASS
17. Self-correction loop: PASS
18. Negative instructions: PASS
19. Tool failure handling: PASS — 6-row error table + tool failure handling
20. Chaos resilience: PASS — now also handles: no CLI, no permissions, unsupported region, existing .env, network timeout

## Verdict: PERFECT (100%) ✓ — strengthened from already perfect
