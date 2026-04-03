# Technical Deep Dive: Claude Code File Tools Architecture

## Core Design Principles

**Single Invariant Contract**: "Every write operation requires a prior read of the target file."

## Read Tool Implementation

**Pagination**: Default 2,000 lines. Two-stage token gate: fast estimate first, then API-based exact count if suspicious.

**Dedup Mechanism** (~18% hit rate): Tracks `readFileState` with content, timestamp, offset, limit. Returns ~100-byte stub if `mtime` unchanged.

**Special Format Support**: Images (base64), PDFs (20-page max), Jupyter notebooks, macOS thin space handling.

**Device Path Blocking**: Prevents hanging on `/dev/zero`, `/dev/random`, etc.

## Write Tool Architecture

**Read-Before-Write Gate** (Three Failure Modes):
1. No read in session: `errorCode: 2`
2. Partial read detected: same rejection
3. File modified after read: `errorCode: 3`

**Atomic Write Sequence**:
```
mkdir → fileHistoryTrackEdit →
[CRITICAL SECTION] readFileSyncWithMetadata() → staleness check → writeTextContent()
→ LSP notifications → readFileState update
```

**Line-Ending Policy**: Always LF regardless of original encoding.

## Edit Tool Mechanics

**String Matching**: Single occurrence = direct replacement. Multiple = error unless `replace_all: true`.

**Quote Normalization**: Normalizes curly quotes to straight for matching, preserves original typography.

**Desanitization Table**: Handles API injection prevention patterns.

**Markdown Exception**: `.md` and `.mdx` files skip trailing whitespace stripping (two spaces = hard line breaks).

## Race Condition Mitigation

**Two-Phase Staleness Check**: Pre-permission check and synchronous re-read during call().

## Limits Precedence Hierarchy

1. Environment variable
2. GrowthBook flag
3. Hardcoded default: 25,000 tokens / 256 KB
