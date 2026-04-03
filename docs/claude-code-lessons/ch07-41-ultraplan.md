# ULTRAPLAN: Remote Planning Architecture

## Detached Launch Pattern

Returns user feedback immediately via void async closure. `ultraplanLaunching` flag set synchronously before async work.

## Keyword Trigger System

Smart disambiguation filters "ultraplan" in quoted/bracketed contexts, file paths, shell flags, questions.

## Polling Architecture

Cursor-based pagination: 3-second ticks, up to 50 event pages. Tolerates 5 consecutive network failures over 30 minutes.

## ExitPlanModeScanner

Stateful classifier: Approved (is_error=false + marker), Teleport (is_error=true + sentinel), Rejected (is_error=true), Pending, Terminated.

## Phase State Machine

running (default) → needs_input (idle + no events) → plan_ready (ExitPlanMode tool_use exists).

## Dual Delivery Paths

**Remote**: User approves in browser → PR result.
**Teleport**: User clicks "back to terminal" → plan delivered locally via UltraplanChoiceDialog.

## Prompt Construction

Seed plan outside system-reminder (visible). Instructions inside tag (model sees, UI hides). Omits "ultraplan" keyword to prevent self-triggering.

## Persistence & Recovery

Session metadata in sidecar file. `--resume` restores ULTRAPLAN context.
