# Claude Code Boot Sequence: Technical Architecture Analysis

## Core Boot Pipeline Structure

The startup executes across **three nested layers**:

1. **CLI Entrypoint** (`cli.tsx`) - Zero-cost fast paths and environment prep
2. **Main Function** (`main.tsx`) - Commander parsing, initialization, migrations
3. **Setup + REPL** (`setup.ts` + `replLauncher.tsx`) - Session wiring and rendering

## Key Architectural Patterns

### Fast-Path Optimization
"Fast paths in cli.tsx exit before loading any heavy modules. `claude --version` never touches `main.tsx`." Commands like `--version`, `--daemon-worker`, and `remote-control` use dynamic imports to avoid full module graph evaluation.

### Parallel Prefetch Strategy
Top-level side effects in `main.tsx` launch async I/O before static imports complete:
- `startMdmRawRead()` - Spawns policy queries (20-40ms)
- `startKeychainPrefetch()` - Initiates OAuth/API key reads (65ms on macOS)

Results cache while the ~135ms import chain evaluates, eliminating sequential bottlenecks.

### Ordered Initialization Constraints
Critical dependency enforcement through comments:
```
setCwd(cwd)  // Must precede captureHooksConfigSnapshot()
// Hooks snapshot reads .claude/settings.json relative to cwd
captureHooksConfigSnapshot()
```

### Session State Management
`bootstrap/state.ts` centralizes ~60 fields including:
- Identity: `sessionId`, `projectRoot`, `cwd`
- Usage: `totalCostUSD`, token counters
- Cache stability: "latching fields" like `afkModeHeaderLatched` keep API headers stable mid-session, protecting server-side prompt caches from busting

### Bare Mode Optimization
Scripted/SDK calls skip non-essential startup: "UDS messaging server, teammate snapshot, session memory, plugin hooks, attribution hooks, and all deferred prefetches."

### Deferred Execution Window
"Deferred prefetches run after first render, hidden in the human typing window — architecture designed around perceived latency, not just raw latency."

Critical analytics beacon placement ensures telemetry before downstream operations that could crash.

## Implementation Patterns for Agent Frameworks

1. **Dynamic imports for conditional paths** reduce TTI for common operations
2. **Fire-and-forget async prefetches** during I/O-bound initialization phases
3. **Explicit ordering constraints** via source comments document state machine requirements
4. **Session state centralization** enables feature toggles without header mutations
5. **Human perception window exploitation** defers non-blocking work after UI render
