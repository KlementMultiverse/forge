# /security-scan — Security Audit

Comprehensive security audit using OWASP Top 10 + STRIDE threat modeling. Scans code, config, and architecture for vulnerabilities.

<system-reminder>
CRITICAL RULES:
- Check ALL items in ~/.claude/rules/security.md — do not skip any
- OWASP Top 10 is the minimum checklist — check every category
- CRITICAL and HIGH findings MUST be fixed before proceeding
- Check for hardcoded secrets, SQL injection, XSS, CSRF, tenant isolation
- Read .env.example — every secret MUST come from env vars
</system-reminder>

## Input
$ARGUMENTS — optional scope (e.g., "auth", "storage", "all"). Default: "all"

## Execution

Spawn `@security-engineer` with:

### OWASP Top 10 Scan

| # | Category | What To Check |
|---|----------|--------------|
| A01 | Broken Access Control | Auth checks on every protected endpoint. Tenant isolation enforced. Role-based permissions. |
| A02 | Cryptographic Failures | Passwords hashed (never plaintext). Secrets in env vars. HTTPS enforced. Session cookies HttpOnly+Secure. |
| A03 | Injection | SQL injection (parameterized queries). XSS (template escaping). Command injection (no shell=True). |
| A04 | Insecure Design | State machine enforced (not bypassable). Audit log immutable. Rate limiting on auth endpoints. |
| A05 | Security Misconfiguration | DEBUG=False in production. ALLOWED_HOSTS configured. CSRF protection enabled. CORS whitelist (no wildcard). |
| A06 | Vulnerable Components | Dependencies checked for CVEs. No outdated packages with known vulnerabilities. |
| A07 | Auth Failures | Brute force protection. Password complexity. Session timeout. Forced password reset for invited users. |
| A08 | Data Integrity | LLM output sanitized (strip_tags). File uploads validated. Presigned URL expiry enforced. |
| A09 | Logging Failures | Security events logged (login, failed auth, access denied). No credentials in logs. |
| A10 | SSRF | No user-controlled URLs in server-side requests. Lambda invocation via ARN, not URL. |

### STRIDE Threat Model

| Threat | Question | Check |
|--------|----------|-------|
| **S**poofing | Can someone pretend to be another user? | Session management, auth tokens |
| **T**ampering | Can data be modified in transit/storage? | CSRF protection, signed URLs |
| **R**epudiation | Can actions be denied? | Audit log immutability |
| **I**nformation Disclosure | Can data leak to wrong users? | Tenant isolation, error messages |
| **D**enial of Service | Can the system be overwhelmed? | Rate limiting, timeout handling |
| **E**levation of Privilege | Can a user gain admin access? | Role checks, permission model |

## Output

```markdown
# Security Audit Report

## Risk Level: [LOW / MEDIUM / HIGH / CRITICAL]

## Findings
| # | Severity | Category | File | Description | Remediation |
|---|----------|----------|------|-------------|-------------|

## Passed Checks
[List of checks that passed]

## Recommendations
[Priority-ordered list of fixes]
```
