# FORGE.md — Work Queue

This file drives `/forge`. Add work items here. `/forge` reads this and executes them in order.

## How to Add Work

When you want to build something, add an entry:
```yaml
- type: NEW_PROJECT | FEATURE | BUG | IMPROVEMENT
  description: what to do
  status: QUEUED
```

When agents discover issues during building, they add entries too.
`/forge` processes QUEUED items top-to-bottom.

---

## Active
<!-- Currently being worked on. Only ONE item active at a time. -->

## Queued
<!-- Waiting to be processed. /forge picks the top item. -->

## Done
<!-- Completed items with full traceability. -->
