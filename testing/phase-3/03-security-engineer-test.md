# Test: @security-engineer — Security Audit (Run 1/10)

## Input
Django settings.py excerpt with SECRET_KEY fallback, DB defaults, ngrok in ALLOWED_HOSTS

## Score: 12/12 (100%)

Found 7 issues: 2 CRITICAL, 2 HIGH, 2 MEDIUM, 1 LOW
- F-01 [CRITICAL] Hardcoded fallback SECRET_KEY — session/CSRF forgery
- F-02 [CRITICAL] postgres superuser as DB default — cross-tenant breach
- F-03 [HIGH] ngrok wildcard in ALLOWED_HOSTS — Host header injection
- F-04 [HIGH] Missing HSTS/SSL/XSS headers
- F-05 [MEDIUM] Missing XFrameOptionsMiddleware — clickjacking
- F-06 [MEDIUM] No DEBUG production assertion
- F-07 [LOW] No DB SSL mode

Used OWASP Top 10 + STRIDE matrix. Severity tags correct. Remediation code provided.
Handoff format followed. No /learn insights flagged (minor gap).

## Verdict: EXCELLENT — agent caught real security issues
The only improvement: add explicit /learn flag for findings.
