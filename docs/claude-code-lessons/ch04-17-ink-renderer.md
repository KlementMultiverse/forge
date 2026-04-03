# Technical Deep Dive: Ink Rendering Engine Architecture

## Core Performance Patterns

**Dirty Flag Optimization**: Walking parent chain sets dirty flags on all ancestors. Clean nodes with unchanged positions blit from previous frame — O(changed cells) performance.

**Two-Phase Separation**: Layout computation via `onComputeLayout()` then `onRender()`. Ensures Yoga flexbox completes before reading positions.

## Data Structure Innovations

**Packed Int32 Cell Storage**: 2xInt32 per cell (8 bytes) — charId + styleId|hyperlinkId|cellWidth. Eliminates per-cell object allocation for 24,000 cells.

**Shared Pool Architecture**: CharPool and HyperlinkPool persist across both screen buffers. Blit copies integer IDs directly.

## Reconciler Integration

**Event Handler Isolation**: Handlers stored separately from attributes to prevent re-created callbacks from triggering repaints.

**Virtual-Text Ghost Nodes**: Nested Text becomes `ink-virtual-text` — no yogaNode, no layout cost.

## Layout Engine Abstraction

LayoutNode interface decouples from Yoga WASM. DOM-to-Yoga index mapping handles nodes without Yoga nodes.

## Command Buffer Pattern

Output class collects operations during tree walks. Pass 1: expand damage bounding box. Pass 2: replay blit/write/clip in DOM order.

## Style Caching

StylePool pre-computes ANSI transition strings. Visible-on-space bit enables single bitmask check to skip invisible spaces.

## Persistent Cache

charCache (capped 16384 entries) persists across frames — tokenize + grapheme clustering becomes map lookup for unchanged lines.
