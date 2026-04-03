# Message Processing Pipeline

## Four-Stage Async Waterfall

1. Submit & Route (validation, queuing, exit-word handling)
2. Input Classification (images, slash commands, bash mode)
3. Message Construction (typed UserMessage objects)
4. API Normalization (flattening, dedup, virtual message stripping)

## Dual-Path Design

Queue Processor Path (skips validation) and Direct User Input Path (reference expansion, exit-word checking, command detection).

## Query Guard

Reserved BEFORE processing to prevent submission races. Generation counter prevents stale finally blocks.

## Image Processing

Multi-stage downsampling. Pasted images parallelized. Image metadata in separate `isMeta` messages.

## API Normalization Multi-Pass

1. Message splitting (deterministic UUID derivation)
2. Attachment reordering
3. Virtual message stripping
4. Error-to-strip map building
5. System/attachment message filtering
6. Consecutive same-role message merging
7. Orphaned tool_use pairing with SYNTHETIC_TOOL_RESULT_PLACEHOLDER

## Message Taxonomy

UserMessage, AssistantMessage, AttachmentMessage, SystemMessage, ProgressMessage, TombstoneMessage.

## Training Data Safety

SYNTHETIC_TOOL_RESULT_PLACEHOLDER export — HFI submission path rejects payloads containing this marker.

## Short Message ID

Base36 6-character IDs derived from UUID for model references.

## Memory Correction Hint

Conditional postscript on rejection/cancellation messages when auto-memory enabled.
