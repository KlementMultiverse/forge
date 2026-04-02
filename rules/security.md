# Security Rules

1. All credentials from environment variables — NEVER hardcoded
2. Session cookies: HttpOnly=True, SameSite=Lax, Secure=True in production
3. CSRF protection on all state-changing endpoints
4. Input validation at system boundaries (user input, external APIs)
5. LLM output treated as untrusted — sanitize before storage/display
6. Presigned URLs for file access — never expose storage keys
7. Tenant data isolation enforced at database level (schema, row, or column)
8. Password hashing via framework default (PBKDF2, bcrypt, argon2)
9. Staff users must reset temporary password before accessing anything
10. Audit log: immutable (save raises error if pk exists, delete raises error)
11. Role-based access: check permissions on every protected endpoint
12. CORS: whitelist specific origins — never wildcard in production
13. Rate limiting on auth endpoints (login, register, password reset)
14. No sensitive data in logs (passwords, tokens, API keys, PII)
15. Dependencies: check for known vulnerabilities before adding
