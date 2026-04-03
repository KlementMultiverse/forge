# Test: @s3-lambda-agent — Run 1/10

## Input
Implement S3 presigned URL generation + Lambda invocation for document summarization

## Score: 17/17 applicable (100%) — after fixes

### Core (items 1-15)
1. Single responsibility: PASS — "AWS S3 presigned URLs and Lambda invocation specialist via boto3"
2. Forge Cell referenced: PASS — S3+LAMBDA-specific (7-step with boto3 imports, grep for error types)
3. context7 MCP: PASS — exact calls (resolve-library-id("boto3"), query-docs for S3 presigned + Lambda invoke)
4. Web search: PASS — "S3 presigned URL best practices [current year]"
5. Self-executing: PASS — import verification, grep for error handling
6. Handoff protocol: PASS — custom 5-field (Files Changed, Functions Implemented, Rules Applied, Error Handling, Next Steps)
7. [REQ-xxx]: PASS — step 6
8. Per-agent judge: PASS
9. Specific rules: PASS — 6 CRITICAL rules, ALL 6 boto3 error types listed
10. Failure escalation: PASS — NoCredentialsError → STOP, ClientError → check IAM, Lambda timeout → check settings
11. /learn: PASS — CORS issues, presigned URL gotchas, Lambda cold start
12. Anti-patterns: PASS — 6 items (no direct S3 serving, no direct LLM, all 6 error types)
13-15: N/A

### New (items 16-20)
16. Confidence routing: PASS — added
17. Self-correction loop: PASS — added
18. Negative instructions near end: PASS
19. Tool failure handling: PASS — added + original has boto3 error handling for all 6 types
20. Chaos resilience: PASS — handles missing credentials, permission denied, timeouts, missing objects

## STRENGTH
ALL 6 boto3 error types explicitly listed (ClientError, ReadTimeoutError, ConnectTimeoutError,
NoCredentialsError, PartialCredentialsError, Lambda timeout). Step 0 intent statement with
CLAUDE.md rule citations. Custom handoff format with error handling field.

## Verdict: EXCELLENT — PERFECT SCORE (100%)
