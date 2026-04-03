# Run 09: saleor — Path traversal in file uploads, SSRF in webhooks, mark_safe usage

## Target
- Repo: `/home/intruder/projects/forge-test-repos/saleor`
- Scope: File uploads, SSRF, template safety

## Files Examined
- `saleor/app/installation_utils.py` — HTTP requests for app manifests
- `saleor/core/tests/test_http_client.py` — IP filter tests
- `saleor/graphql/core/tests/test_file_validation.py` — upload validation tests
- Grep for mark_safe, requests_hardened, path traversal patterns

## Security Findings

### 1. SSRF protection via requests_hardened (GOOD)
- **File**: `saleor/core/tests/test_http_client.py:13,36`
- Saleor uses `requests_hardened.HTTPSession` with IP filtering that blocks private IP ranges.
- `allow_redirects=False` is set on outbound requests — prevents SSRF via redirect.
- **Excellent**: This is better than most projects.

### 2. File upload validation exists (GOOD)
- **File**: `saleor/graphql/core/tests/test_file_validation.py`
- Tests exist for file validation with MIME type checking.

### 3. No mark_safe usage found (GOOD)
- Grep for `mark_safe|SafeData|format_html` returned zero results in production code.
- Saleor is API-only (no Django templates serving HTML), so this is expected.

### 4. Webhook URLs are validated (GOOD)
- Webhook delivery uses requests_hardened with IP filtering.
- `allow_redirects=False` prevents redirect-based SSRF.

### 5. No path traversal in file handling (GOOD)
- No evidence of user-controlled filenames being used in `os.path.join` or similar.
- File storage appears to use Django's storage backend which handles path sanitization.

### 6. HTTP timeouts are enforced (GOOD)
- **File**: `saleor/app/installation_utils.py:72,88,209` — all outbound requests have explicit timeouts.

## Agent Prompt Evaluation

| Finding | Would prompt guide to this? | Notes |
|---|---|---|
| SSRF protection | PARTIAL | Prompt mentions "check auth on endpoints" but not SSRF specifically |
| File upload validation | NO | No file upload security guidance |
| mark_safe | NO | Not in grep patterns (prompt greps for password, secret, api_key, csrf_exempt) |
| Webhook URL validation | NO | No webhook security guidance |
| Path traversal | NO | Not mentioned in prompt |
| HTTP timeouts | NO | Not mentioned |

## GAPs Identified
1. **GAP: No SSRF checklist** — needs: check for IP filtering on outbound requests, redirect following, DNS rebinding, cloud metadata endpoint blocking (169.254.169.254)
2. **GAP: No file upload security checklist** — needs: MIME validation, filename sanitization, path traversal checks, file size limits, storage location isolation
3. **GAP: No outbound HTTP security guidance** — needs: timeouts, redirect policy, TLS verification, IP filtering
4. **GAP: Grep patterns are too narrow** — current grep only checks `password|secret|api_key` and `csrf_exempt`. Should also check `mark_safe`, `|safe`, `innerHTML`, `eval(`, `exec(`, `os.system`, `subprocess`, `pickle.loads`
