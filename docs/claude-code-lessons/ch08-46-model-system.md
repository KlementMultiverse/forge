# Claude Code Model System Architecture

## Multi-Provider Registry

Single source of truth via `ModelConfig` mapping logical models across four providers. One entry regardless of provider-specific naming.

## Five-Layer Selection Priority

1. Session override (`/model`)
2. CLI flag (`--model`)
3. Environment variable (`ANTHROPIC_MODEL`)
4. Persisted settings
5. Subscription-based default

Allowlist gate silently ignores disallowed models.

## Runtime Suffix System

`[1m]` suffix is a runtime flag, not a separate model. Preserved through pipeline, stripped at API boundaries via `normalizeModelStringForAPI()`.

## Access Control

hard-disable → provider check → subscription → billing → feature flag (Statsig). Inverted funnel, fails safely.

## Subagent Inheritance

Default to "inherit" mode with alias-to-version resolution preserving parent tier. Prevents silent downgrade.

## Allowlist Narrowing

Both "opus" and "opus-4-5" in allowlist → family wildcard suppressed, restricts to 4.5 only.

## Validation & Deprecation

Custom model IDs validated via minimal API calls (max_tokens: 1). Provider-specific retirement dates. Graceful fallbacks for 3P.
