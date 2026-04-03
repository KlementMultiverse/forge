# Claude Code Hooks System

## 27 Extension Points

Five command types (power hierarchy): command (subprocess), prompt (single LLM query), agent (multi-turn, max 50), http (POST with env var interpolation), function (TypeScript callback).

Exit code semantics: 0 = success, 2 = blocking error, other = warning.

## Matcher-Based Filtering

PreToolUse: `tool_name`. FileChanged: glob patterns. SessionStart: `source` (startup/resume/clear/compact). `if` field: permission rule syntax.

## Configuration Hierarchy (6 Sources)

userSettings → projectSettings → localSettings → policySettings → pluginHook → sessionHook. Policy: `allowManagedHooksOnly`, `disableAllHooks`.

## Session Hooks

Use `Map<string, SessionStore>` instead of plain objects to prevent React re-renders. Self-destructing via `"once": true`.

## Async Execution

`async: true` launches and continues. `asyncRewake: true` interrupts model on exit code 2.

## HTTP Hooks Security

URL allowlist, env var allowlist, SSRF guard (blocks private IPs, allows loopback). Header injection: CR/LF/NUL stripping.

## Agent Hooks

Structured output enforcement: registers Stop function hook, checks for StructuredOutput tool call, injects error if missing. 50-turn limit.

## Hook Event Bus

Three event types: started, progress (1s intervals), response (completion). Up to 100 events buffer.
