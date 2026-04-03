# Autoresearch Log: refactoring-expert

**Date**: 2026-04-02
**Agent**: /home/intruder/projects/forge/agents/universal/refactoring-expert.md
**Test Repos**: clinic-portal, saleor, fastapi-template, medusa

## Web Research Sources

- [Code Smell Detection: Complete Guide to Clean Code 2025](https://kensoftph.com/code-smell-detection-complete-guide-to-clean-code-2025/)
- [What is Code Smell Detection? 2026 Guide](https://www.codeant.ai/blogs/what-is-code-smell-detection)
- [Code Smells - Refactoring Guru](https://refactoring.guru/refactoring/smells)
- [SmellDetector: Code Smell Detection and Refactoring with LLMs](https://openreview.net/forum?id=g-LPFWsB9qC)
- [5 Code Review Anti-Patterns You Can Eliminate with AI](https://www.coderabbit.ai/blog/5-code-review-anti-patterns-you-can-eliminate-with-ai)
- [Agentic AI Coding: Best Practice Patterns](https://codescene.com/blog/agentic-ai-coding-best-practice-patterns-for-speed-with-quality)
- [AI should help us produce better code - Simon Willison](https://simonwillison.net/guides/agentic-engineering-patterns/better-code/)
- [Code Smells and Anti-Patterns - Codacy](https://blog.codacy.com/code-smells-and-anti-patterns)

## Changes Made to Prompt

### Added: Smell Detection Catalog (entire new section)
14 named smells with detection criteria, replacing vague "identify improvement opportunities" with a concrete checklist. Each smell maps to real code found in test repos.

### Added: Size & Complexity Thresholds Table
Concrete numbers replacing the single "300 lines" rule:
- Function >50 lines, Cyclomatic >10, Class >20 methods, Class >500 lines, Imports >30, Import depth >3

### Added: Architecture Smell Detection
- Business logic in views/handlers
- Cross-cutting concern leakage (audit, cache, logging)
- Missing service layers
- Shotgun surgery

### Added: Monorepo-Specific Smells
- Structural duplication across packages
- Shared utility underuse
- Cross-package consistency

### Added: Positive Pattern Recognition
Agent now explicitly recognizes and preserves good patterns instead of only flagging problems.

### Added: Error Handling Consistency Check
- Inconsistent HTTP status codes
- Missing exception hierarchies
- Magic values scattered in code

### Added: Transaction Safety Verification
Flags multi-step operations without atomic transactions as a follow-up issue.

### Modified: Forge Cell Compliance
Added step 3 (run Smell Detection Catalog) and step 8 (check all thresholds).

### Modified: Handoff Protocol
Added "Smells Found" and "Good Patterns Preserved" fields.

### Modified: Learning Section
Added shotgun surgery, business logic in views, and good pattern INSIGHT templates.

### Modified: Chaos Resilience
Added function >50 lines, class >20 methods, import >30 triggers, monorepo detection, transaction safety.

### Modified: Anti-Patterns
Added "NEVER refactor good patterns" and "NEVER skip Smell Detection Catalog".

## Gaps Resolved

24 gaps identified across 10 test runs. All HIGH severity gaps addressed:
- GAP-1: Function-level threshold (50 lines)
- GAP-3: Business logic in API handlers (named smell #6)
- GAP-4: God Class metric (20 methods / 500 lines)
- GAP-7: Architecture smells section
- GAP-16: Error handling consistency check
- GAP-20: Shotgun surgery (named smell #2)
- GAP-21: Cross-cutting concern detection (named smell #7)

All MEDIUM gaps addressed. LOW gaps addressed where they fit naturally.
