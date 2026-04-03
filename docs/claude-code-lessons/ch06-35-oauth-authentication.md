# OAuth 2.0 Implementation Architecture

## PKCE Without Embedded Secrets

Fresh code verifier (256-bit entropy) per login, stored only in memory. S256 challenge sent to auth server.

## Dual Concurrent Flows

Automatic (browser redirect via localhost) and manual (copy-paste fallback). First to resolve wins via Promise racing.

## Localhost Capture

Port 0 assignment (OS selects free port). Pending response pattern stores browser's ServerResponse before resolving auth code promise.

## Token Storage

macOS: `security` CLI (keychain) with hex encoding to defeat process monitors. Linux: plaintext. Stale-while-error caching returns last known good value.

## Profile Optimization

Skips `/api/oauth/profile` during refresh if config already has required fields.

## Scope-Based Routing

`user:inference` present → Claude.ai infrastructure. Absent → Console API key path.

## Proactive Refresh

5-minute buffer before expiry. Scope expansion possible without re-authentication.

## Logout Sequencing

1. Flush telemetry (preserves org attribution)
2. Wipe secure storage
3. Clear auth caches
4. Update global config

## Enterprise

`CLAUDE_CODE_CUSTOM_OAUTH_URL` with strict allowlist prevents credential exfiltration.
