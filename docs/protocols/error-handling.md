# Error Handling Protocol

How forge handles errors. All scripts MUST follow this protocol.

---

## Error Types

| Type | Severity | Action | Max Retries | Backoff |
|------|----------|--------|-------------|---------|
| `GATE_BLOCKED` | HIGH | wait + poll | 5 polls then cooldown | 60s between polls |
| `RETRY_EXHAUSTED` | CRITICAL | escalate | 0 (already exhausted) | n/a |
| `AGENT_FAILED` | HIGH | retry with context | 3 | 5s, 15s, 30s |
| `TEST_FAILED` | HIGH | investigate then fix | 3 | immediate |
| `LINT_FAILED` | MEDIUM | auto-fix then retry | 2 | immediate |
| `TRACE_INCOMPLETE` | MEDIUM | backfill | 1 | immediate |
| `DOCKER_UNHEALTHY` | HIGH | restart then retry | 2 | 10s, 30s |
| `AUTH_EXPIRED` | CRITICAL | refresh credentials | 1 | immediate |
| `NETWORK_ERROR` | HIGH | retry with backoff | 5 | 5s, 10s, 20s, 40s, 60s |
| `SPEC_DRIFT` | MEDIUM | sync triangle | 1 | immediate |
| `FILE_TOO_LONG` | MEDIUM | split file | 0 (must fix) | n/a |

---

## Retry Policy

### Exponential Backoff Formula

```
delay = BASE_DELAY × 2^(attempt - 1)
jitter = random(0, 0.25 × delay)
total_wait = delay + jitter

BASE_DELAY = 5 seconds (agent failures)
MAX_DELAY  = 60 seconds
MAX_RETRIES = 3 (default, per error type above)
```

### Consecutive Failure Tracking

Every retry-able step tracks in forge-state.json:

```json
{
  "retry_state": {
    "current_step": 14,
    "consecutive_failures": 2,
    "last_error_type": "AGENT_FAILED",
    "last_error_detail": "backend-architect returned empty output",
    "first_failure_at": "2026-04-05T10:30:00Z",
    "backoff_until": "2026-04-05T10:30:15Z"
  }
}
```

Rules:
1. On SUCCESS → reset `consecutive_failures` to 0
2. On FAILURE → increment `consecutive_failures`, set `backoff_until`
3. At max retries → set error type to `RETRY_EXHAUSTED`, stop retrying
4. `RETRY_EXHAUSTED` → log to violations, print action for user

---

## Circuit Breaker (Gate Polling)

Used when waiting for external approval (observer, CodeRabbit).

### States

```
CLOSED (normal) → polls every 60s
    ↓ (5 polls, no change)
OPEN (cooldown) → waits 5 minutes, no polling
    ↓ (cooldown expires)
HALF-OPEN → single poll
    ↓ (still no change)      ↓ (approved!)
OPEN (cooldown #2)          CLOSED (continue)
    ↓ (3 cooldown cycles)
ESCALATE → manual override needed
```

### State in forge-state.json

```json
{
  "gate_circuit": {
    "state": "CLOSED",
    "poll_count": 0,
    "cooldown_count": 0,
    "last_poll_at": null,
    "cooldown_until": null,
    "last_response": null
  }
}
```

### Rules

1. CLOSED: poll every 60s, track response
2. After 5 identical responses → transition to OPEN
3. OPEN: wait 5 minutes (no polling)
4. After cooldown → HALF-OPEN: single poll
5. If response changed → CLOSED (reset everything)
6. If same response → OPEN again (cooldown_count++)
7. After 3 cooldown cycles → ESCALATE
8. ESCALATE: print instructions for manual override, stop polling

---

## Error Classification

### How to classify an error

```bash
forge-enforce.sh classify-error <context>
```

Input context (from tool output, test result, or hook):
- Contains "FAIL" + "test" → `TEST_FAILED`
- Contains "ruff" or "lint" → `LINT_FAILED`
- Contains "BLOCKED" + "gate" → `GATE_BLOCKED`
- Contains "unhealthy" + "docker" → `DOCKER_UNHEALTHY`
- Contains "401" or "403" or "token" → `AUTH_EXPIRED`
- Contains "timeout" or "ECONNRESET" → `NETWORK_ERROR`
- Contains "300 lines" or "FILE TOO LONG" → `FILE_TOO_LONG`
- Contains "REQ-" + "missing" or "orphan" → `SPEC_DRIFT`
- Contains "trace" + "incomplete" → `TRACE_INCOMPLETE`
- Default → `AGENT_FAILED`

### Error log entry format

```json
{
  "type": "AGENT_FAILED",
  "severity": "HIGH",
  "step": 14,
  "event_seq": 42,
  "timestamp": "2026-04-05T10:30:00Z",
  "detail": "backend-architect returned empty output",
  "action": "retry",
  "retry_count": 1,
  "resolved": false
}
```

---

## Escalation Path

```
Error occurs
  ↓
Classify → get action + max_retries
  ↓
RETRY (with backoff)
  ↓ (still failing after max_retries)
COOLDOWN (if applicable — gate polling)
  ↓ (cooldown cycles exhausted)
ESCALATE
  ↓
Print to user:
  [FORGE] ESCALATED: {error_type} after {N} retries
  [FORGE] Step: {step_number} ({step_name})
  [FORGE] Last error: {detail}
  [FORGE] Action needed: {human_action}
  ↓
Log to violations in forge-state.json
STOP (do not continue)
```

---

## Logging Requirements

Every error MUST be logged to:

1. **forge-state.json** `violations` array — structured entry (type, severity, step, detail)
2. **docs/.builder-activity.log** — one-line summary for timeline
3. **docs/forge-timeline.md** — if error changes step status (BLOCKED)

Every retry MUST log:
1. Which attempt (1/3, 2/3, 3/3)
2. Backoff delay applied
3. Whether the retry succeeded

---

## Adding New Error Types

Protocol for adding a new error type:

1. Create GitHub issue describing the error scenario
2. Add type to the table above (this file)
3. Add classification pattern to `classify-error` in forge-enforce.sh
4. Add handling to relevant scripts
5. Update forge-core.json checksum
6. Commit with issue reference

---

## Patterns from Claude Code Source

These patterns were derived from analyzing the Claude Code v2.1.88 source:

| Claude Code Pattern | File | Our Implementation |
|--------------------|----|-------------------|
| Exponential backoff | `withRetry.ts` (500ms × 2^n) | 5s × 2^n in retry policy |
| Consecutive 529 tracking | `withRetry.ts` line 334 | consecutive_failures counter |
| Fast mode cooldown | `fastMode.ts` state machine | Gate circuit breaker (CLOSED→OPEN→HALF-OPEN) |
| Tool error classification | `toolExecution.ts` classifyToolError() | classify-error command |
| Hook graceful failure | `toolHooks.ts` line 189 | `|| true` on all hooks |
| Foreground vs background | `withRetry.ts` line 62 | Critical vs non-critical steps |
| Retry-after header | `withRetry.ts` line 519 | backoff_until in state |
| Streaming fallback | `claude.ts` line 2505 | Agent retry with different prompt |
