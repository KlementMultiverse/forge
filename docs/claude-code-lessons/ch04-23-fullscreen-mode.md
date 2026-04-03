# Technical Analysis: Fullscreen & Terminal Modes

## Three Layers

1. DEC Sequences Layer — pre-generated escape codes
2. Detection Layer — pure predicates
3. React Integration — component-level lifecycle

## Key Patterns

**Pre-Generated Constants**: All escape sequences as module-level constants, eliminating formatting in hot paths.

**Defensive Teardown**: Reverse-order mode disabling (outer → inner).

**useInsertionEffect**: Fires during mutation phase, before rendering — ensures alt-screen activation precedes any terminal output.

**Synchronous tmux Probe**: `spawnSync()` despite ~5ms cost, because async probe raced against React render and lost.

## Slot-Based Composition

Fullscreen: Five named slots (scrollable, bottom, overlay, bottomFloat, modal) with viewport constraints. Non-fullscreen: Sequential stacking into normal scrollback.

## OffscreenFreeze Optimization

Returns cached ref for offscreen content — reconciler produces zero diff, preventing per-tick resets for animated spinners.

## Multi-Level Feature Flags

- `CLAUDE_CODE_NO_FLICKER=0`: Disables alt-screen
- `CLAUDE_CODE_DISABLE_MOUSE=1`: Disables capture, preserves alt-screen
- `CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1`: Clicks/drags only
