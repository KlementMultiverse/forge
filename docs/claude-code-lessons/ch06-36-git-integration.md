# Claude Code Git Integration

## Zero-Subprocess, Filesystem-First Design

Reads git's plain-text files directly (.git/HEAD, .git/config, .git/packed-refs) rather than spawning processes.

## Five Modules

gitFilesystem.ts, gitConfigParser.ts, gitignore.ts, gitOperationTracking.ts, ghAuthStatus.ts.

## Config Parser: Three-Level Lookup

section (case-insensitive) → subsection (case-sensitive) → key (case-insensitive). Validates escape sequences inside quotes.

## Worktree/Submodule Handling

When `.git` is a file (worktrees/submodules), follows `gitdir: <path>` pointer. Checks `commonDir` for shared state.

## GitFileWatcher: Dirty-Before-Compute Pattern

Clear dirty BEFORE async compute. If file changes during compute, invalidate() re-sets dirty. Write back only if dirty is still false.

## Security: Dual Validation

`isSafeRefName` allowlist: blocks path traversal, argument injection, shell metacharacters. `isValidGitSha`: only full-length SHAs.

## Operation Tracking

Regex-based detection of commits, pushes, PRs from command output. Shell-agnostic, tolerates git global flags.

## PR Auto-Linking

Double dynamic import at runtime breaks circular dependency graph.

## GitHub Auth: Offline-First

`gh auth token` (not `auth status`) — only reads local keyring. stdout set to 'ignore' to prevent token entering Node memory.

## Global Gitignore

Writes to `~/.config/git/ignore` using `**/${filename}` pattern. Pre-checks `isPathGitignored()` to avoid duplicates.
