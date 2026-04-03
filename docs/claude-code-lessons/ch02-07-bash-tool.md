# Bash Tool Architecture: Key Technical Patterns

## Core Architecture

The Bash Tool implements a **seven-layer validation pipeline** before subprocess execution and three output layers afterward.

```
Input → validateInput → checkPermissions → call() → buildExecCommand
→ sandbox wrap → spawn → output stream → interpretResult → persist
```

## Shell Snapshot System

Captures environment once at session start rather than spawning expensive login shells per command:
- Executes `getSnapshotScript()` sourcing user's `.zshrc`/`.bashrc`
- Extracts functions via `typeset -f` (zsh) or `declare -F` (bash)
- Stores snapshot at `~/.claude/shell-snapshots/`
- Every command sources the snapshot

## 23 Security Validators Chain

Each validator returns: `allow`, `passthrough`, or `ask`. First non-passthrough wins.

Critical validators:
- **#7 NEWLINES**: Unquoted newlines
- **#8 DANGEROUS_PATTERNS**: Command substitution `$()`, backticks
- **#14 MALFORMED_TOKEN_INJECTION**: Quote mis-tokenization detection
- **#19 MID_WORD_HASH**: `'x'#` pattern where `#` becomes comment after stripping
- **#23 QUOTED_NEWLINE**: Literal newline inside quoted strings

**Safe heredoc early-allow**: Special path for heredoc patterns bypasses all validators if conditions met.

**Compound command cap**: 50 subcommand limit to prevent CPU-starvation DoS.

## Permission Plumbing

**Environment variable stripping** (two-phase fixed-point loop): Strip safe env vars, then wrapper commands (timeout, time, nice, nohup).

Rule matching modes: Exact, Prefix (`npm run:*`), Wildcard (`git * --force`).

**Auto-prefix generation**: User approval suggests prefix rules, never exact message or bare `Bash(*)`.

## Output Handling

- **Size limits**: Inline 30KB default, 150KB hard cap, 64MB disk cap with truncation
- **Image detection**: Base64 PNG/JPEG headers trigger image content blocks
- **Semantic exit codes**: Table-driven interpretation (grep 1 = "no matches")
- **Hint stripping**: `<claude-code-hint />` tags on stderr recorded then stripped

## Background Execution

Three distinct paths:
- `run_in_background: true` (explicit model request)
- `backgroundedByUser: true` (manual Ctrl+B)
- `assistantAutoBackgrounded: true` (15s timeout in assistant mode)

**Sleep blocker**: Integer-duration `sleep N` (N >= 2) blocked when Monitor tool enabled.

## UI Classification

Command classification for collapse behavior with pipeline collapsibility requiring all parts in search/read set.

**Sed special case**: Commands matching `sed -i 's/.../.../' file` display as FileEdit operations with diff-style dialogs.
