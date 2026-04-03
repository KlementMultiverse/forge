# Technical Deep Dive: Search Tools Architecture

## Core Design Pattern: Unified Binary, Divergent Interfaces

Both Glob and Grep delegate to ripgrep. "ripgrep with `--files --glob <pattern>` is a high-performance glob traversal."

## Three-Mode Output Strategy for Grep

- **files_with_matches** (`-l` flag): Paths sorted by modification time
- **content** (no flag): Matching lines with optional context
- **count** (`-c` flag): Per-file match counts

## Absolute Path Decomposition

`extractGlobBaseDirectory()` splits absolute paths into base directory and relative pattern since ripgrep's `--glob` only accepts relative patterns.

## Pagination Through Head-Limiting

Head-limiting occurs before path relativization — optimization to avoid processing then discarding.

## Three-Tier Binary Resolution (Memoized)

```
system → embedded → builtin
```

Security: Uses command `"rg"` not resolved path to prevent PATH hijacking.

## Resource Constraint Handling

**EAGAIN Retry**: Retry with `-j 1` (single thread) for that call only. Previous versions persisted single-threaded mode globally, causing timeouts.

**Platform-Aware Timeouts**: 20 seconds standard, 60 seconds on WSL.

## Performance Optimizations

- 500-character line cap (prevents minified code flooding)
- 20MB buffer ceiling
- Streaming file counting with rounding for privacy
- Path relativization saves tokens

## Pattern Safety

Leading-dash patterns passed using `-e pattern` syntax to prevent ripgrep flag injection.

UNC paths skip `stat` calls to prevent NTLM credential leaks.

## Relevance Signal: Modification Time Sort

Results sorted by mtime (descending). Test mode overrides with alphabetic sorting for deterministic fixtures.

## Concurrent Safety

Both tools declare `isConcurrencySafe() = true`. Read-only with no shared mutable state.
