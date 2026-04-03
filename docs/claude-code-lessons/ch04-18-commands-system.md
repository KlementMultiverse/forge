# Claude Code Commands System - Technical Deep Dive

## Architecture: Discriminated Union Pattern

Three execution types: `local` (sync TypeScript), `local-jsx` (React/Ink component), `prompt` (text expansion to model).

### Lazy Loading Pattern

Both `local` and `local-jsx` defer implementation imports until invocation, accelerating startup.

## Registration Pipeline

```
bundledSkills → builtinPluginSkills → skillDirCommands
→ workflowCommands → pluginCommands → pluginSkills → COMMANDS()
```

Earlier sources take priority for deduplication.

## Input Processing

No framework-level parsing — each command interprets its own argument string. Shell command substitution via `` !`command` `` pattern replaces patterns before model receives prompt.

## REPL Integration

Local commands: load → call → update messages.
Local-JSX: load → render → onDone → unmount → optionally query.
Prompt commands: getPromptForCommand → ContentBlockParam[] → becomes user message.

## Security & Permission Scoping

`allowedTools` on prompt commands restricts model capability to listed tools during execution.

## Feature Gating

Internal-only commands eliminated at build time. Commands like `/commit` don't exist in user-installed versions.

## Cache Management

Three layers: `COMMANDS()` singleton, `loadAllCommands` per-cwd, `getSkillToolCommands` per-cwd. Granular clear functions.

## Remote & Bridge Mode Restrictions

Remote mode uses `REMOTE_SAFE_COMMANDS`. Bridge mode: local-jsx always blocked, prompt always allowed, local requires explicit opt-in.
