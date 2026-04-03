# Cron and Task Scheduling

## Three Core Layers

1. User-facing tools (CronCreate, CronDelete, CronList)
2. Scheduler core (1-second tick loop)
3. Persistent storage (.claude/scheduled_tasks.json)

## Distributed Lock

PID-based locking. Stale detection via PID validity. Session tasks bypass locks.

## Jitter Strategy

Recurring: forward jitter up to 10% of interval (capped 15 min). One-shot: backward jitter at :00/:30 marks. Deterministic per task ID hash.

## Catch-Up Prevention

Reschedule from `now`, not from computed fire time.

## Lazy Enablement

Scheduler starts polling, transitions to active only when tasks exist. Timers `unref()`'d for headless exit.

## React Integration

Fired prompts use `'later'` priority, never interrupting active queries.

## Startup Resilience

Missed one-shot tasks surface with injection-resistant notification (adaptive backtick fence). Missed recurring tasks fire normally.

## Live Ops

GrowthBook flags: `tengu_kairos_cron` kill switch, `tengu_kairos_cron_config` jitter parameters. Strict Zod validation with atomic fallback.
