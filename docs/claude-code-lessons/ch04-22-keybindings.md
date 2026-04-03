# Technical Architecture: Claude Code Keybindings System

## Five-Layer Pipeline

1. Terminal Decode (escape sequences → ParsedKey)
2. Binding Config (defaults + user overrides)
3. Key Matching (modifier normalization)
4. Chord Resolution (single keys + multi-step sequences)
5. React Dispatch (hooks consume resolved actions)

## Three Keyboard Protocols

Legacy VT, CSI u (Kitty), xterm modifyOtherKeys. Modifier bitmask: shift=1, alt=2, ctrl=4, super=8.

## Chord Resolution

Prefix detection: enters `chord_started` only if at least one longer chord exists. Five outcomes: match, none, unbound, chord_started, chord_cancelled.

## Override Model

User bindings concatenate after defaults; resolver scans linearly, last match wins. `null` action swallows events.

## 18 Context-Sensitive Binding Tables

Components register/unregister active contexts on mount/unmount.

## Hot-Reload Pipeline

Chokidar watches with 500ms stabilize delay. Loads async, updates cache, emits change signal.

## Validation

Non-rebindable: ctrl+c, ctrl+d, ctrl+m. Terminal-reserved: ctrl+z, ctrl+\\. macOS OS-level: cmd+c/v/x/q/w/tab/space. Duplicate key detection in raw JSON before parsing.
