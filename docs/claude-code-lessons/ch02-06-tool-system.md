# Claude Code Tool System Architecture: Key Patterns

## Core Design Principles

**Structural Protocol Over Inheritance**
The `Tool<Input, Output, P>` type uses TypeScript's structural typing rather than class hierarchies. Any object satisfying the interface is a tool — built-in, MCP, or dynamically generated.

**Fail-Closed Defaults**
`buildTool()` applies conservative defaults for unspecified methods:
- `isConcurrencySafe` → `false` (assume state mutation)
- `isReadOnly` → `false`
- `checkPermissions` → `allow` (defer to general system)

## Three-Tier Registration Pipeline

```
getAllBaseTools() → getTools() → assembleToolPool()
```

1. **Exhaustive catalog** with feature-flag dead-code elimination
2. **Context filtering** by mode, deny-rules, and per-tool `isEnabled()` veto
3. **Stable sorting** as two alphabetical groups (built-ins, then MCP) to preserve prompt cache breakpoint

## Runtime Concurrency Control

**Data-Driven Safety Assessment**: `isConcurrencySafe(input)` is evaluated per invocation. A Bash tool running `ls` could be safe while `rm -rf` is unsafe.

**Partitioning Algorithm**: Consecutive safe tools batch together; any unsafe tool breaks the batch. Concurrent batch uses `all()` with concurrency ceiling (default 10).

## Input Mutation Safety Pattern

Three distinct input copies maintain isolation:
1. **API-bound original** — preserved for transcript serialization
2. **Backfilled observable clone** — seen by hooks and permission gates
3. **Potentially-mutated call input** — what `tool.call()` receives after hook processing

## Permission Gate Architecture

Sequential validation pipeline:
1. Zod schema parsing
2. Semantic validation via `tool.validateInput()`
3. Speculative classifier for Bash
4. `backfillObservableInput` cloning
5. PreToolUse hooks
6. `canUseTool()` main gate
7. `tool.call()` execution
8. PostToolUse hooks

## Bash Exception: Sibling Abort Cascades

Only Bash tool errors trigger `siblingAbortController.abort()` to cancel parallel siblings. "Bash commands often have implicit dependency chains... Read/WebFetch/etc are independent."

## In-Order Result Emission Under Concurrent Execution

`StreamingToolExecutor` yields results in model-requested order despite concurrent execution. Progress messages bypass ordering (emitted immediately out-of-order).

## Defensive Measures

- Zod `strictObject` rejects unknown fields
- `isConcurrencySafe()` wrapped in try/catch; parse failures default to `false`
- Speculative classifier runs pre-hook to avoid permission-prompt race conditions
- Context mutations via functional returns rather than global state access
