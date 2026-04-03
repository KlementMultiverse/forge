# Theme and Visual Styling System

## Four Layers

1. Semantic Palette (~70 tokens mapped to raw colors)
2. Chalk Normalization (environment detection at module load)
3. Layout Types (CSS-like API for terminal)
4. Theme Resolution (bridge from theme keys to raw colors)

## Flat Theme Type

O(1) lookups, direct JSON serialization, self-describing color strings via prefixes (`rgb(`, `#`, `ansi:`, `ansi256(`).

## Terminal Environment Fixes

- VS Code: Boost to truecolor (level 3) when detected as 256-color
- tmux: Clamp to level 2 (escape hatch: `CLAUDE_CODE_TMUX_TRUECOLOR=1`)
- Boost runs first; tmux clamp re-clamps afterward

## Color Resolution

Curried `color()` function returns reusable colorizer — avoids repeated lookups.

## Accessibility: Six Themes

dark, light, light-daltonized, dark-daltonized, light-ansi, dark-ansi. Daltonized replaces green-red with blue-red.

## Sub-agent Color Management

`AgentColorManager` maps names to theme slots using `satisfies` compile-time constraint.
