# BUDDY System: Technical Architecture

## Bones/Soul Split Pattern

Immutable derived state (bones: species, rarity, stats) regenerated deterministically from `hash(userId + SALT)`. Mutable stored state (soul: name, personality) persisted to `config.companion`.

Tamper-proof, rename-safe, forward-compatible.

## Deterministic Generation

Mulberry32 PRNG with content-addressed seed. Module-level rollCache eliminates redundant PRNG calls across three hot paths.

## Species Obfuscation

All 18 species names constructed at runtime via hex char codes — avoids CI excluded-strings canary.

## Animation State Machine

Weighted idle sequence with blink signals. Narrow terminal (<100 cols) fallback to single-line face.

## Rendering: Three-Stage Sprite Assembly

Eye substitution → Hat injection → Row optimization (drop blank row 0).

## Context Injection

Companion injected via `companion_intro` attachment. System prompt: don't identify as companion, respond in <=1 line when addressed by name.

## Launch Strategy: Marketing as Code

Local-time detection produces 24-hour rolling wave across timezones. April 1-7 window.

## Stat Generation

One peak stat, one dump stat. Rarity floors scale (common:5, legendary:50). Legendary always maxes peak. Shiny: 1% per companion.
