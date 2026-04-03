# Settings & Configuration Architecture

## Five-Layer Merge Cascade

userSettings → projectSettings → localSettings → flagSettings → policySettings (later overrides earlier).

### Policy: First-Source-Wins

Remote API → MDM registries → managed-settings.json → HKCU registry. Only first non-empty source applies.

### Array Deduplication

Concatenates then deduplicates. Permission rules accumulate across all enabled sources.

### Three-Tier Caching

sessionSettingsCache → perSourceCache → parseFileCache → readFileSync + Zod. All clear atomically.

### File Watch Suppression

Internal writes mark themselves; 5-second window suppresses reload cascades.

### Delete-and-Recreate Grace Period

1700ms grace window after deletion for atomic update detection.

## Remote Settings

ETag-based caching with SHA-256 checksums. Fail-open design: network errors retry up to 5 times. Startup parallelism: MDM reads spawn early.

## Security: Layered Trust Domains

Certain flags exclude projectSettings: `skipDangerousModePermissionPrompt`, classifier config, etc.

Enterprise lockdown: `allowManagedPermissionRulesOnly`, `allowManagedHooksOnly`.

## Settings Sync

Syncs user settings between CLI and headless via cloud key-value store. Project keys scoped by git remote URL hash.

## Drop-In Directory Convention

`managed-settings.d/` for multiple teams delivering policy fragments. Files merge alphabetically (systemd convention).
