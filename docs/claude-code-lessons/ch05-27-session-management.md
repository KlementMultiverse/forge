# Claude Code Session Management

## Append-Only JSONL with Linked-List Chains

Messages stored as JSONL with `parentUuid` pointers. Loading walks backward from newest leaf to root, then reverses.

## Singleton Project Class with Per-File Write Queues

100ms local drain, 10ms cloud drain. Deduplication via `Set<UUID>`.

## Lazy File Materialization

Session files only created on first real user/assistant message.

## Tail-Window Metadata Preservation

Critical metadata in final 64KB of JSONL. Head+tail read strategy: first 4KB for initial prompt/branch/cwd, last 64KB for title/tag/lastPrompt.

## Interrupt Detection and Auto-Resume

Three categories: `none` (last is assistant response), `interrupted_prompt` (last is user text), `interrupted_turn` (last is tool result — injects "Continue from where you left off").

## Three-State Session Machine

`idle → running → requires_action → running → idle`

## Dual Remote Persistence

v1 Session Ingress (REST POST) and CCR v2 (internal event writer/reader). Both flush at 10ms intervals.

## Worktree Resume with TOCTOU Safety

Uses `process.chdir()` as live existence check.

## Preserved Segment Relink on Compaction

Preserves message suffix, re-links pointers on resume.

## Content Replacement Records

Tool results exceeding size thresholds substituted with reference records.
