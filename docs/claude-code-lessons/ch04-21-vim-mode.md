# Vim Mode Implementation: Technical Architecture

## Discriminated Union State Machine

`VimState` has two modes (INSERT/NORMAL); `CommandState` has eleven variants. Compile-time exhaustiveness checking ensures adding a new state forces handlers throughout.

## Pure Functions + Context Injection

Engine has zero knowledge of text storage/rendering. All side effects flow through context interfaces (`OperatorContext`, `TransitionContext`).

## Motion Resolution

Pure functions resolving motion key + count to target Cursor. Classified as inclusive or linewise for operator range computation.

## Text Object Algorithms

Brackets use depth-counting bidirectional scans. Symmetric delimiters use linear scan + pairing. Word objects use `Intl.Segmenter` for grapheme-safe unicode.

## Compound Counts

`2d3w` multiplies operator and motion counts. `MAX_VIM_COUNT = 10000` prevents performance catastrophes.

## Persistent State for Dot-Repeat

`RecordedChange` captures everything needed to replay a command.
