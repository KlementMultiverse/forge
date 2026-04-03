# Run 07: fastapi-template -- Write authentication flow documentation

## Task
Write authentication flow documentation for a FastAPI template project.

## Code Read
- No fastapi-template repo available locally
- Would need auth module, middleware, security dependencies

## Prompt Evaluation

### What the prompt guided well
1. **RESEARCH step** -- "Read the actual code being documented -> extract function signatures" -- would correctly guide reading auth endpoints
2. **Practical Examples** -- "Working code samples" -- essential for auth docs
3. **Accessibility Design** -- inclusive language matters for security docs (avoid jargon-heavy explanations)

### What the prompt missed or was weak on
1. **No sequence diagram instruction** -- Auth flows are best documented with sequence diagrams (login -> token -> refresh -> logout). Prompt doesn't push for visual flow documentation
2. **No security considerations section** -- Auth docs MUST cover: token storage (httpOnly cookies vs localStorage), CSRF protection, session management. Prompt doesn't push for security context
3. **No token lifecycle documentation** -- Access token expiry, refresh token rotation, session invalidation. Prompt doesn't differentiate stateless (JWT) vs stateful (session) auth docs
4. **No multi-auth documentation** -- Projects often support multiple auth methods (session, JWT, API key, OAuth). Prompt doesn't push for documenting when to use which
5. **No "common mistakes" section for auth** -- Storing tokens in localStorage, not validating expiry, CSRF vulnerabilities. Critical for auth docs
6. **No role/permission documentation link** -- Auth docs should connect to authorization/permission docs. Prompt doesn't push for cross-referencing
7. **No error response documentation for auth** -- 401 vs 403 vs 422 distinctions are critical for auth. Prompt's generic error handling is insufficient

### Documentation Quality Score: 5/10
- Auth documentation is security-critical; generic guidance is risky
- Prompt's "working examples" instruction helps but doesn't enforce security-aware examples
- Missing: sequence diagrams, token lifecycle, security considerations, multi-auth comparison

## Prompt Gaps Identified
| Gap | Severity | Fix |
|-----|----------|-----|
| No sequence diagram instruction | High | Add: "For flow-based features (auth, payment, deployment), include sequence diagrams showing actor interactions" |
| No security considerations for auth docs | High | Add: "Auth documentation MUST include Security Considerations section: token storage, CSRF, session management" |
| No token/session lifecycle docs | Medium | Add: "Document credential lifecycle: creation, expiry, renewal, revocation" |
| No multi-auth comparison | Medium | Add: "When multiple auth methods exist, compare when to use each" |
| No cross-reference to permission docs | Low | Add: "Auth docs should link to authorization/permission documentation" |
