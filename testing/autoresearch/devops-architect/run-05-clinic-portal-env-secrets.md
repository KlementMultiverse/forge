# Run 05: clinic-portal — .env Management, Secret Rotation

## Source Files
- `/home/intruder/projects/clinic-portal/.env` (actual)
- `/home/intruder/projects/clinic-portal/.env.example`
- `/home/intruder/projects/clinic-portal/.gitignore`
- `/home/intruder/projects/clinic-portal/config/settings.py`

## Findings

### .env File (CRITICAL SECURITY ISSUES)

**CRITICAL: Real credentials in .env file**
The `.env` file contains what appear to be real AWS credentials and an Anthropic API key:
- `AWS_ACCESS_KEY_ID=AKIA...` (real IAM key pattern)
- `AWS_SECRET_ACCESS_KEY=0MjV...` (real secret)
- `ANTHROPIC_API_KEY=sk-ant-api03-...` (real API key)

While `.env` is in `.gitignore`, this is still a risk:
- If `.gitignore` was ever missing or wrong, credentials would be committed.
- No evidence of credential rotation process.
- No AWS IAM policy scoping visible — the key might have broader permissions than needed.

### .env.example (Good Template)
- Exists and documents all required variables.
- Placeholder values for secrets (`AWS_ACCESS_KEY_ID=` empty).
- Documents default database credentials.
- ISSUE: `ALLOWED_HOSTS=*` in example is dangerous — should show specific hosts.
- ISSUE: `SECRET_KEY=change-me-to-a-real-secret-key` — should document how to generate one.

### .gitignore
- `.env` IS listed — good.
- `.venv/`, `venv/`, `env/` covered.
- `__pycache__/` covered.
- `staticfiles/` covered.
- MISSING: No explicit ignore for `*.pem`, `*.key`, `credentials.json`, or other secret file patterns.

### settings.py Secret Handling
- `SECRET_KEY` from env with empty default — raises ValueError in production (good).
- `DEBUG` defaults to False (safe default).
- Database credentials from env vars (good).
- AWS credentials accessed via `os.environ.get()` in services (good pattern).
- ISSUE: `DJANGO_SECRET_KEY` env var name in actual `.env` but `SECRET_KEY` in settings.py — mismatch! Settings reads `SECRET_KEY`, .env sets `DJANGO_SECRET_KEY`. This means the app falls back to the insecure dev key.

### Secret Rotation Concerns
- No documentation or tooling for rotating AWS credentials.
- No documentation for rotating `SECRET_KEY` (would invalidate all sessions).
- No documentation for rotating `ANTHROPIC_API_KEY`.
- No credential expiry or rotation reminders.
- No integration with AWS Secrets Manager, Vault, or similar.

### Docker Compose Secret Handling
- `env_file: .env` in docker-compose.yml is acceptable for dev.
- No Docker secrets support for production.
- Hardcoded `POSTGRES_PASSWORD: postgres` in docker-compose.yml services section (should reference env_file).

## What the Agent Prompt Covers vs Misses

| Concern | Covered? | Notes |
|---|---|---|
| No secrets in Docker/CI config | YES | Anti-pattern rule |
| Use env vars and .env files | YES | Anti-pattern rule |
| Create .env.example template | YES | Chaos resilience rule |
| Secret rotation strategy | NO | Not mentioned |
| Credential scoping (IAM least privilege) | NO | Not mentioned |
| Secret manager integration | NO | Not mentioned |
| .gitignore verification for secret files | NO | Not mentioned |
| Env var name consistency check | NO | Not mentioned |
| Production secret management (Vault, Secrets Manager) | NO | Not mentioned |

## Gaps Identified for Agent Prompt
1. **Secret rotation documentation**: Agent should recommend documenting rotation procedures for every credential.
2. **IAM least privilege**: Agent should recommend verifying AWS IAM policies are scoped to only required actions/resources.
3. **Secret manager integration**: Agent should recommend Vault, AWS Secrets Manager, or similar for production.
4. **Env var name consistency**: Agent should verify env var names match between .env, .env.example, and code references.
5. **gitignore completeness**: Agent should verify .gitignore covers common secret file patterns (*.pem, *.key, credentials.json, service-account.json).
6. **Credential detection**: Agent should recommend running tools like `gitleaks` or `trufflehog` to scan for accidentally committed secrets.
