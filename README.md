# Forge

Autonomous software development framework. One command builds production-grade applications.

```
/forge "I want to build a clinic management portal for medical practices"
```

That's it. Forge handles discovery, requirements, architecture, implementation, testing, and review — autonomously.

## Quick Start

```bash
# Install Forge commands + agents into Claude Code
./install.sh

# Start a new project
/forge "your idea in one sentence"
```

## How It Works

Forge runs a 7-phase pipeline:

| Phase | What | Command |
|-------|------|---------|
| 0 | Discovery + Requirements + Spec | /discover → /requirements → /feasibility → /generate-spec → /bootstrap |
| 1 | Specification | /specify → proposal + GitHub Issues |
| 2 | Architecture | /design-doc → /plan-tasks |
| 3 | Implementation | Per-issue TDD via domain agents + judges |
| 4 | Validation | /audit-patterns + /sc:test |
| 5 | Review | /retro + playbook update |
| 6 | Iterate | Feedback → loop |

Every agent runs through the **Forge Cell** — a universal 7-step wrapper:
1. Load Context → 2. Research → 3. TDD Implement → 4. Quality Check → 5. Sync Check → 6. Judge → 7. Commit + Learn

## Key Features

- **One command** — `/forge` runs the entire SDLC autonomously
- **Bidirectional sync** — spec, tests, and code always in agreement via [REQ-xxx] tracing
- **Per-agent judges** — every agent has its own domain reviewer that rates output (1-5)
- **Self-improving** — playbook with helpful/harmful counters; bad rules auto-pruned
- **On-demand agents** — @agent-factory creates new agents for unknown stacks
- **Quality gates** — nothing proceeds without passing /gate (CodeRabbit 0 suggestions)
- **Safety commands** — /investigate, /careful, /freeze, /guard

## Structure

```
forge/
├── commands/       ← slash commands (/forge, /discover, /investigate, etc.)
├── agents/         ← specialist agents (universal + per-stack)
├── rules/          ← modular governance (not one giant CLAUDE.md)
├── hooks/          ← runtime enforcement (PreToolUse, PostToolUse)
├── templates/      ← project scaffolding (SPEC, CLAUDE.md, docker, etc.)
├── playbook/       ← self-improving strategies with scoring
├── scripts/        ← traceability + sync checking
└── docs/           ← methodology + patterns
```

## Requirements

- Claude Code CLI
- Git + GitHub (with CodeRabbit for PR review)
- context7 MCP server (for library docs)
