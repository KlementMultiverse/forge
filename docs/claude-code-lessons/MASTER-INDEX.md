# MASTER INDEX: Claude Code Deep Dive — Patterns for Forge

Source: [markdown.engineering/learn-claude-code](https://www.markdown.engineering/learn-claude-code/)
50 lessons across 8 chapters. All fetched and extracted 2026-04-02.

---

## Chapter Index

### Chapter 1: Core Architecture
| # | File | Key Pattern |
|---|------|-------------|
| 01 | [ch01-01-boot-sequence.md](ch01-01-boot-sequence.md) | Fast-path optimization, parallel prefetch, deferred execution window |
| 02 | [ch01-02-query-engine.md](ch01-02-query-engine.md) | Async generators throughout, transcript-first reliability, structured retry |
| 03 | [ch01-03-state-management.md](ch01-03-state-management.md) | 35-line generic store, DeepImmutable pattern, centralized onChange |
| 04 | [ch01-04-system-prompt.md](ch01-04-system-prompt.md) | Priority waterfall, static/dynamic boundary, CLAUDE.md hierarchy |
| 05 | [ch01-05-architecture-overview.md](ch01-05-architecture-overview.md) | Two-layer state model, QueryEngine lifecycle, hook security snapshot |

### Chapter 2: The Tool System
| # | File | Key Pattern |
|---|------|-------------|
| 06 | [ch02-06-tool-system.md](ch02-06-tool-system.md) | Structural protocol, fail-closed defaults, three-tier registration |
| 07 | [ch02-07-bash-tool.md](ch02-07-bash-tool.md) | Shell snapshot, 23 security validators, sibling abort cascades |
| 08 | [ch02-08-file-tools.md](ch02-08-file-tools.md) | Read-before-write gate, dedup mechanism, atomic write sequence |
| 09 | [ch02-09-search-tools.md](ch02-09-search-tools.md) | Unified ripgrep binary, mtime relevance sort, flag injection prevention |
| 10 | [ch02-10-mcp-integration.md](ch02-10-mcp-integration.md) | 7-level config cascade, 8 transport types, OAuth pseudo-tool |
| 11 | [ch02-11-skills-system.md](ch02-11-skills-system.md) | Six-stage pipeline, path-based activation, forked execution model |

### Chapter 3: Agent Intelligence
| # | File | Key Pattern |
|---|------|-------------|
| 12 | [ch03-12-agent-system.md](ch03-12-agent-system.md) | Fork path cache sharing, worktree isolation, inter-agent messaging |
| 13 | [ch03-13-coordinator-mode.md](ch03-13-coordinator-mode.md) | Pure dispatcher, four-phase workflow, continue vs spawn decision |
| 14 | [ch03-14-teams-and-swarm.md](ch03-14-teams-and-swarm.md) | File-based coordination, three backends, permission escalation |
| 15 | [ch03-15-memory-system.md](ch03-15-memory-system.md) | Three-layer memory, four-type taxonomy, mutual exclusion extraction |
| 16 | [ch03-16-auto-memory-and-dreams.md](ch03-16-auto-memory-and-dreams.md) | Forked extraction + consolidation, lock-as-timestamp, taxonomy exclusions |

### Chapter 4: The Interface
| # | File | Key Pattern |
|---|------|-------------|
| 17 | [ch04-17-ink-renderer.md](ch04-17-ink-renderer.md) | Dirty flag blit, packed Int32 cells, virtual-text ghost nodes |
| 18 | [ch04-18-commands-system.md](ch04-18-commands-system.md) | Discriminated union, lazy loading, scoped tool permissions |
| 19 | [ch04-19-dialog-ui.md](ch04-19-dialog-ui.md) | Promise-based dialogs, wizard pattern, render isolation |
| 20 | [ch04-20-notification-system.md](ch04-20-notification-system.md) | Priority-based toast queue, fold semantics, OS notification routing |
| 21 | [ch04-21-vim-mode.md](ch04-21-vim-mode.md) | Discriminated union state machine, pure functions + context injection |
| 22 | [ch04-22-keybindings.md](ch04-22-keybindings.md) | Five-layer pipeline, chord resolution, 18 context-sensitive tables |
| 23 | [ch04-23-fullscreen-mode.md](ch04-23-fullscreen-mode.md) | useInsertionEffect timing, synchronous tmux probe, OffscreenFreeze |
| 24 | [ch04-24-theme-styling.md](ch04-24-theme-styling.md) | Flat theme type, terminal environment fixes, daltonized accessibility |

### Chapter 5: Infrastructure
| # | File | Key Pattern |
|---|------|-------------|
| 25 | [ch05-25-permissions.md](ch05-25-permissions.md) | 7-step pipeline, bypass-immune paths, shadow rule detection |
| 26 | [ch05-26-settings-config.md](ch05-26-settings-config.md) | Five-layer cascade, three-tier caching, file watch suppression |
| 27 | [ch05-27-session-management.md](ch05-27-session-management.md) | Append-only JSONL, linked-list chains, interrupt detection |
| 28 | [ch05-28-context-compaction.md](ch05-28-context-compaction.md) | Cost-ladder strategies, 9-section summary, circuit breaker |
| 29 | [ch05-29-analytics-telemetry.md](ch05-29-analytics-telemetry.md) | Pre-sink queue, PII via type system, fail-open resilience |
| 30 | [ch05-30-migrations.md](ch05-30-migrations.md) | Idempotent one-shot functions, settings layer discipline |
| 31 | [ch05-31-plugin-system.md](ch05-31-plugin-system.md) | Five layers, DFS dependency resolution, namespaced isolation |
| 32 | [ch05-32-hooks-system.md](ch05-32-hooks-system.md) | 27 extension points, five command types, exit code semantics |
| 33 | [ch05-33-error-handling.md](ch05-33-error-handling.md) | Typed error classes, conversation recovery, telemetry safety naming |

### Chapter 6: Connectivity
| # | File | Key Pattern |
|---|------|-------------|
| 34 | [ch06-34-bridge-and-remote.md](ch06-34-bridge-and-remote.md) | FlushGate pattern, dual transport versions, mirror mode |
| 35 | [ch06-35-oauth-authentication.md](ch06-35-oauth-authentication.md) | PKCE without secrets, dual concurrent flows, logout sequencing |
| 36 | [ch06-36-git-integration.md](ch06-36-git-integration.md) | Filesystem-first (no subprocess), dirty-before-compute, dual validation |
| 37 | [ch06-37-upstream-proxy.md](ch06-37-upstream-proxy.md) | HTTPS CONNECT tunnel via WebSocket, prctl anti-ptrace, fail-safe init |
| 38 | [ch06-38-cron-scheduling.md](ch06-38-cron-scheduling.md) | PID-based distributed lock, deterministic jitter, catch-up prevention |
| 39 | [ch06-39-voice-system.md](ch06-39-voice-system.md) | Backend fallback chain, silent-drop resilience, hold-to-talk mechanics |

### Chapter 7: Unreleased
| # | File | Key Pattern |
|---|------|-------------|
| 40 | [ch07-40-buddy-companion.md](ch07-40-buddy-companion.md) | Bones/soul split, deterministic generation, species obfuscation |
| 41 | [ch07-41-ultraplan.md](ch07-41-ultraplan.md) | Detached launch, cursor-based polling, dual delivery paths |
| 42 | [ch07-42-entrypoints-sdk.md](ch07-42-entrypoints-sdk.md) | Stub-and-inject SDK, build-time DCE, 26 hook events |
| 43 | [ch07-43-kairos-always-on.md](ch07-43-kairos-always-on.md) | Tick loop heartbeat, cost-aware idling, dual durability tiers |
| 44 | [ch07-44-cost-analytics.md](ch07-44-cost-analytics.md) | Dual pipeline, microdollar storage, disk-backed retry |
| 45 | [ch07-45-desktop-app.md](ch07-45-desktop-app.md) | Four subsystems, lockfile IDE discovery, fast-path CLI |

### Chapter 8: The Big Picture
| # | File | Key Pattern |
|---|------|-------------|
| 46 | [ch08-46-model-system.md](ch08-46-model-system.md) | Multi-provider registry, five-layer selection, runtime suffix system |
| 47 | [ch08-47-sandbox-security.md](ch08-47-sandbox-security.md) | Platform-native backends, stale-while-error cache, startup prefetch |
| 48 | [ch08-48-message-processing.md](ch08-48-message-processing.md) | Four-stage waterfall, query guard generation counter, multi-pass normalization |
| 49 | [ch08-49-task-system.md](ch08-49-task-system.md) | Atomic one-way latch, two-layer output, 50-message memory cap |
| 50 | [ch08-50-repl-screen.md](ch08-50-repl-screen.md) | Ref-based stability, deferred rendering, 14-step session resume |

---

## Top Patterns for Forge Agent Framework

### 1. Agent Orchestration Patterns
| Pattern | Source | Forge Application |
|---------|--------|-------------------|
| **Pure dispatcher coordinator** | ch03-13 | Forge orchestrator should delegate, never execute tools directly |
| **Four-phase workflow** (research → synthesis → implement → verify) | ch03-13 | Standard workflow template for multi-agent tasks |
| **File-based inter-agent messaging** | ch03-14 | Use filesystem mailboxes for process-isolated agents |
| **Fork path with cache sharing** | ch03-12 | Maximize prompt cache hits when spawning sub-agents |
| **Continue vs spawn decision** | ch03-13 | High context overlap → reuse agent; low overlap → fresh agent |
| **Worktree isolation** | ch03-12 | Git worktrees for parallel implementation agents |

### 2. Memory & Context Management
| Pattern | Source | Forge Application |
|---------|--------|-------------------|
| **Three-layer memory** (auto/session/team) | ch03-15 | Separate persistent, ephemeral, and shared memory stores |
| **Four-type taxonomy** (user/feedback/project/reference) | ch03-15 | Classify memories to prevent stale content pollution |
| **Exclude derivable content** from memory | ch03-16 | Never store code patterns or architecture — derivable from live code |
| **Cost-ladder compaction** (micro → session → LLM → reactive) | ch05-28 | Cheapest strategy first; escalate only when needed |
| **9-section structured summary** | ch05-28 | Standardized compaction output for reliable reconstruction |
| **Circuit breaker** (3 failures → stop) | ch05-28 | Prevent retry hammering on compaction failures |
| **Mutual exclusion** between main agent and memory extractor | ch03-16 | Detect writes to memory paths to avoid double-writes |

### 3. Tool System Design
| Pattern | Source | Forge Application |
|---------|--------|-------------------|
| **Structural protocol over inheritance** | ch02-06 | Any object satisfying interface is a tool — no class hierarchy |
| **Fail-closed defaults** | ch02-06 | New tools assume unsafe until proven otherwise |
| **Per-invocation concurrency safety** | ch02-06 | `isConcurrencySafe(input)` — not per-tool, per-call |
| **Three input copies** (original, observable, mutable) | ch02-06 | Prevent transcript corruption from hook mutations |
| **23 security validators** for shell commands | ch02-07 | Defense-in-depth for command execution |
| **Read-before-write invariant** | ch02-08 | Prevent blind overwrites; require prior file read |
| **Shell snapshot system** | ch02-07 | Capture environment once, source per command |

### 4. Reliability & Resilience
| Pattern | Source | Forge Application |
|---------|--------|-------------------|
| **Transcript-first** (persist before API call) | ch01-02 | Write user message to disk before calling LLM |
| **Structured retry intelligence** | ch01-02 | Different strategies per error type (529, 401, overflow) |
| **Fail-open telemetry** | ch05-29 | Control plane failure never silences monitoring |
| **Stale-while-error caching** | ch08-47 | Return last known good value on transient failures |
| **Generation counter** for race prevention | ch08-50 | Prevent stale async callbacks from corrupting state |
| **Append-only JSONL with linked-list chains** | ch05-27 | Non-destructive session persistence enabling branching |

### 5. Configuration & Settings
| Pattern | Source | Forge Application |
|---------|--------|-------------------|
| **Five-layer merge cascade** with trust domains | ch05-26 | user → project → local → flag → policy |
| **Three-tier caching with atomic invalidation** | ch05-26 | Session → source → file cache, all clear atomically |
| **File watch suppression** for self-writes | ch05-26 | Prevent infinite reload loops |
| **Idempotent migrations** | ch05-30 | Detect own completion state; never break startup |
| **Drop-in directory convention** | ch05-26 | `managed-settings.d/` for modular policy injection |

### 6. Permission & Security
| Pattern | Source | Forge Application |
|---------|--------|-------------------|
| **Deny-first pipeline** | ch05-25 | Always check denies before allows |
| **Bypass-immune operations** | ch05-25 | Some operations always require approval |
| **Shadow rule detection** | ch05-25 | Flag unreachable rules in configuration |
| **Hook security snapshot** at startup | ch01-05 | Prevent mid-session injection of hook commands |
| **Platform-native sandboxing** | ch08-47 | Seatbelt (macOS), bubblewrap (Linux) |

### 7. Performance Optimization
| Pattern | Source | Forge Application |
|---------|--------|-------------------|
| **Fast-path optimization** (skip module loading) | ch01-01 | Simple commands never load full framework |
| **Parallel prefetch during import** | ch01-01 | Fire async I/O before static imports complete |
| **Human perception window** exploitation | ch01-01 | Defer non-blocking work after first render |
| **Static/dynamic prompt boundary** for cache hits | ch01-04 | Split system prompt for global cacheability |
| **Build-time dead code elimination** | ch01-05 | `feature()` gates remove code from binaries |
| **Deferred rendering** (`useDeferredValue`) | ch08-50 | Keep interaction responsive during streaming |

### 8. System Prompt Engineering
| Pattern | Source | Forge Application |
|---------|--------|-------------------|
| **Priority waterfall** (override → coordinator → agent → custom → default) | ch01-04 | Only first matching layer executes |
| **Memoized section registry** with explicit uncached opt-in | ch01-04 | Cache aggressively; justify volatility |
| **Hierarchical file discovery** (managed → user → project → local) | ch01-04 | Positional weighting by proximity to CWD |
| **Subagent lean defaults** | ch01-04 | Minimal prompt for delegation, not full system prompt |

### 9. Hooks & Extension Points
| Pattern | Source | Forge Application |
|---------|--------|-------------------|
| **Exit code as control protocol** (0=ok, 2=block, other=warn) | ch05-32 | Simple subprocess control without complex IPC |
| **Five command types** (command, prompt, agent, http, function) | ch05-32 | Power hierarchy from simple subprocess to full agent |
| **Matcher-based filtering** | ch05-32 | Tool name, glob patterns, permission rule syntax |
| **Async rewake** | ch05-32 | Background hook can interrupt model on exit code 2 |

### 10. SDK & Integration
| Pattern | Source | Forge Application |
|---------|--------|-------------------|
| **Stub-and-inject architecture** | ch07-42 | Type-safe public API with runtime transport injection |
| **26 hook events** for lifecycle observation | ch07-42 | Rich observer pattern without tight coupling |
| **MCP server symmetry** (provide and consume) | ch07-42 | Expose tools to external agents via standard protocol |
| **Dual remote control patterns** (daemon vs child) | ch07-42 | Choose reliability vs simplicity per deployment |

---

## Cross-Cutting Themes

1. **Cheapest gate first**: Always evaluate boolean checks before I/O, I/O before network calls
2. **Fail-safe by default**: New features start restricted; explicit opt-in for power
3. **Cache everything, invalidate atomically**: Three-tier caching pattern appears in settings, commands, features, tools
4. **Separate derivable from stored state**: Never persist what can be recomputed from live data
5. **Type system as governance**: Use TypeScript's type system (never types, DeepImmutable, discriminated unions) to enforce invariants at compile time
6. **Process isolation with file coordination**: Filesystem-based IPC over shared memory for multi-agent systems
7. **Prompt cache awareness**: Architecture decisions driven by API-level cache key sensitivity
