# Stack Registry

When a tech stack is selected during forge discovery (Q4), the system:
1. Copies stack-specific rules into the project's `.claude/rules/`
2. Sets up the correct agent routing
3. Loads stack-specific learnings from previous builds

## How It Works

Each stack has a folder here with:
- `rules.md` — stack-specific rules (copied to project `.claude/rules/{stack}.md`)
- `agents.md` — agent routing template (merged into project agent-routing.md)
- `learnings.md` — accumulated learnings from past builds (grows with /retro)
- `scaffold.md` — scaffold instructions for @devops-architect

## Adding a New Stack

1. Create folder: `~/.claude/stacks/{stack-name}/`
2. Add the 4 files above
3. The forge discovery (Q4) will detect it and offer it as an option

## Stack Selection Flow

```
Q4: "Tech preferences?"
  → User says "Django" or "FastAPI" or "Next.js"
  → forge reads ~/.claude/stacks/{selection}/
  → Copies rules.md → project .claude/rules/{stack}.md
  → Merges agents.md → project .claude/rules/agent-routing.md
  → Includes learnings.md in agent prompts
  → Uses scaffold.md for Step S7
```
