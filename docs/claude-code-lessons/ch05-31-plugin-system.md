# Claude Code Plugin System

## Five Layers

1. Marketplace Sources (GitHub, Git URLs, monorepo, HTTP, npm, local)
2. Manifest Schema (`plugin.json`)
3. Versioned Cache (`~/.claude/plugins/cache/{mkt}/{plugin}/{version}/`)
4. Dependency Resolution (DFS closure + fixed-point demote)
5. Lifecycle Management (reconcile, autoupdate, load, hook/command/MCP registration)

## Dependency Resolution: Two-Pass

**Install-time**: Recursive DFS with cycle detection, cross-marketplace blocking.
**Load-time**: Fixed-point loop demoting plugins with missing dependencies (cascading).

Dependencies are "presence guarantees" (apt-style), not module imports.

## Security

Policy blocking at install, enable, and UI layers. Delisting mechanism via `forceRemoveDeletedPlugins`. Name protection: blocked official name patterns + reserved name validation.

## Variable Substitution

`${CLAUDE_PLUGIN_ROOT}`, `${CLAUDE_PLUGIN_DATA}`, `${CLAUDE_SESSION_ID}`, `${user_config.KEY}`. Sensitive fields stored in OS keychain, never in skill/agent content.

## Autoupdate

Non-blocking background process. Non-in-place: new version at new path; running session uses old code. Race condition handling via `pendingNotification`.

## Installation Scopes

User → Project → Local → Managed (read-only admin).

## Namespacing

Commands: `/plugin-name:command`. MCP servers: prefixed names. Prevents cross-plugin collisions.
