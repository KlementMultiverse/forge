# REAL TEST: @security-engineer on clinic-portal

## Input
"Scan clinic-portal for security vulnerabilities"

## Real Findings: 11 issues

| # | Severity | Finding | File:Line |
|---|---|---|---|
| 1 | CRITICAL | Hardcoded passwords in seed command (admin123, staff123) | seed_demo.py:36,50,128,134 |
| 2 | CRITICAL | Hardcoded fallback password "changeme123" for superadmin | create_public_tenant.py:65 |
| 3 | HIGH | Tenant session switching without membership verification in FlexibleTenantMiddleware | middleware.py:63-82 |
| 4 | HIGH | Missing production security headers (SSL, HSTS, CSRF_SECURE) | settings.py |
| 5 | MEDIUM | Insecure SECRET_KEY fallback in dev mode | settings.py:9-13 |
| 6 | MEDIUM | ALLOWED_HOSTS includes wildcard ngrok domains | settings.py:16-19 |
| 7 | MEDIUM | Error messages leak internal infrastructure details | api.py:86,405,298 |
| 8 | MEDIUM | No rate limiting on login/register endpoints | users/api.py:103,127 |
| 9 | MEDIUM | Weak password policy (length 8 only, no complexity) | users/api.py:213-214 |
| 10 | LOW | MD5 used for cache keys (collision risk with 8-char truncation) | workflows/api.py:284 |
| 11 | LOW | Docker Compose exposes default PostgreSQL credentials | docker-compose.yml:7-9 |

## Positive Findings (9 things done right)
1. Zero SQL injection — all ORM, no raw queries
2. No hardcoded secrets in application code — all from os.environ
3. .env in .gitignore ✓
4. API auth consistently applied (django_auth on all routers)
5. CSRF protection active
6. LLM output sanitized with strip_tags() ✓
7. S3 key tenant validation ✓
8. TenantMainMiddleware at position 0 ✓
9. Session cookies HttpOnly + SameSite ✓

## Agent Quality Assessment
- Read REAL files with line numbers: ✓
- Specific remediations for each finding: ✓
- Severity classification accurate: ✓
- No false positives: ✓
- Handoff format usable: ✓

## Score: EXCELLENT — production-grade audit output
