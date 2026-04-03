# Claude Code Sandbox & Secure Storage

## Platform Backends

macOS: Apple Seatbelt (sandbox-exec). Linux/WSL2: bubblewrap + seccomp + socat. WSL1/Windows: unsupported.

## Three Sandbox Modes

Disabled (no isolation), Regular (sandboxed, asks before executing), Auto-allow (sandboxed, auto-approval).

## Network Control

Domain filtering from settings + permission rules. Enterprise `allowManagedDomainsOnly` silently blocks unapproved.

## Filesystem Hardening

Always-denied: all settings.json files, .claude/skills, bare git repo sentinels (HEAD, objects, refs, hooks, config) — prevents CVE-class escape via `core.fsmonitor`.

## Secure Storage

macOS: keychain with stable hash-derived service name, hex serialization, ~4032 byte stdin buffer limit.
Linux: plaintext with chmod 0o600.

### Cache with Stale-While-Error

30-second TTL. Failed reads return cached data. Generation counter discards stale async reads. In-flight dedup shares subprocess.

### Startup Prefetch

Two `security` subprocesses fire in parallel at process start (~65ms before needed).

### Fallback Migration

Keychain write fails → plaintext succeeds → stale keychain entry deleted to prevent shadowing.

## Live Configuration Refresh

`settingsChangeDetector` fires on file change. Permission grants take effect immediately.

## Violation Reporting

stderr annotation, SandboxDoctorSection in assistant response, XML block stripping.
