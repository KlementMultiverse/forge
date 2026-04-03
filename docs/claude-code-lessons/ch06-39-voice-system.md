# Claude Code Voice System Architecture

## Multi-Layer Gating

Compile-time feature flag + runtime OAuth token validation. GrowthBook defaults to "not killed."

## Backend Fallback Chain

NAPI (native, ~1s warm) → arecord (Linux, 150ms probe) → SoX (subprocess).

## Audio Streaming & Buffering

PCM chunks buffer in-memory until WebSocket connects, eliminating perceived latency.

## WebSocket Finalization

Four resolution paths: post_closestream_endpoint (~300ms), no_data_timeout (1.5s), ws_close (3-5s), safety_timeout (5s cap).

## Silent-Drop Resilience

Detects session-sticky pod bug (~1% sessions). Replays full audio buffer on fresh connection in 32KB slices.

## Hold-to-Talk

5 rapid keypresses for bare-character bindings; modifier combos activate on first press. Release = 200ms gap in auto-repeat.

## Language Normalization

Maps user language to BCP-47 codes. Keyterms from globals, project basename, git branch boosted for STT.

## Audio Level Visualization

RMS with sqrt curve to spread quieter speech across more bars.

## Focus Mode

Differs in trigger, termination, transcript delivery, silence timeout, replay behavior.

## React Integration

Custom `Store<VoiceState>` with `useSyncExternalStore`. Auth check memoized on `authVersion` bump.
