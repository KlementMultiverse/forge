# Technical Architecture: State Management in Claude Code

## Core Store Pattern

Claude Code implements a **35-line generic store** independent of React:

```typescript
type Store<T> = {
  getState: () => T
  setState: (updater: (prev: T) => T) => void
  subscribe: (listener: Listener) => () => void
}
```

**Key invariant**: `setState` accepts only updater functions `(prev) => next`, never partial objects. This "enforces immutability at the call site" by requiring spreads of previous state.

## Why This Approach

- **No external dependencies**: Zustand/Jotai add bundle weight for an interface matching exactly what `useSyncExternalStore` requires
- **Works outside React**: Headless mode, SDK print layer, and teammate sessions all access state without component tree coupling
- **Reference equality optimization**: `Object.is` comparison prevents re-renders when references haven't changed

## Three-Layer Architecture

| Layer | Purpose |
|-------|---------|
| **Primitive** | `createStore<T>` — framework-agnostic, 35 lines |
| **Domain** | `AppState + AppStateStore` — 400+ field shape, `.ts` to avoid React pulls |
| **React** | `AppStateProvider` + hooks — wires store into Context |

## AppState Shape

"Enormous on purpose" (90+ fields) as single source of truth:

```typescript
export type AppState = DeepImmutable<{
  settings: SettingsJson
  mainLoopModel: ModelSetting
  toolPermissionContext: ToolPermissionContext
}> & {
  tasks: { [taskId: string]: TaskState }
  agentNameRegistry: Map<string, AgentId>
}
```

The `DeepImmutable<...> & { mutables }` pattern makes serializable fields read-only while keeping function-typed fields usable.

## Side-Effect Centralization: onChangeAppState

"Single diff-observer passed as `onChange` to `createStore`" captures all state mutations in one place. This solves the critical problem: before this pattern, permission-mode changes only synced via 2 of 8+ mutation paths, leaving the web UI stale.

## React Integration: useSyncExternalStore

```typescript
export function useAppState(selector) {
  const store = useAppStateStore()
  const get = () => selector(store.getState())
  return useSyncExternalStore(store.subscribe, get, get)
}
```

**Critical selector rule**: Never return new objects/arrays. An inline `s => ({ a: s.a })` creates new reference every render leading to infinite re-renders. Return existing references or primitives only.

## Derived State Patterns

**selectors.ts**: Pure functions accepting `Pick<AppState, ...>` (not full state) for isolated testability.

**Transition helpers** (e.g., `enterTeammateView`) receive `setAppState` as argument, staying framework-agnostic and testable outside React.

## Agent Task Lifecycle: Retain/Evict

Tasks follow a state machine through AppState fields:
- **Stub**: `retain: false`, `messages: undefined`
- **Retained**: `retain: true`, messages loaded (blocks eviction)
- **Eviction pending**: `evictAfter = Date.now() + 30_000` (30s grace period)
- **Dismissed**: `evictAfter = 0` (immediate hide)

## Key Design Decisions

1. **Updater-function enforcement**: Prevents accidental mutations and makes immutability auditable
2. **External store accessible outside React**: Enables SDK integration, headless operation
3. **Centralized `onChange` hook**: "Means new mutation paths automatically get the right behavior for free"
4. **DeepImmutable with escape hatch**: Leverages TypeScript type system while pragmatically handling functions/collections
5. **No module singletons**: Centralizes state for easier testing and resetting across sessions
