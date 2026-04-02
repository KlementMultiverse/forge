# Drift Prevention — Patterns from Claude Code Internals

> "Tiny reminders, at the right time, change agent behavior."

> "Claude Code's magic doesn't just appear because of the base model. It's a combination of one big beautiful prompt along with clever tool descriptions and systematic context engineering with correct tags."

## The Problem

LLMs drift. The longer a session runs, the more the model forgets its instructions. By turn 20, the model has effectively forgotten rules from turn 1. This is why agents start strong and degrade over time.

## The 4 Solutions

### 1. Context Front-Loading

BEFORE any work begins, run two micro-operations:

```
Micro-op 1: "Summarize this task in under 50 characters."
  → Forces the model to crystallize what it's about to do
  → Prevents scope drift ("I thought we were doing X but started doing Y")

Micro-op 2: "Is this a new topic or continuation?"
  → Decides whether to load fresh context or continue from last checkpoint
  → Prevents context pollution from unrelated prior work
```

**In Forge:** The PM orchestrator should run these at:
- Session start (before any agent is spawned)
- Before each new Phase (re-orient to current stage)
- Before spawning any subagent (give it focused context)

### 2. Reminder Injection at Every Step

`<system-reminder>` tags are NOT just in the system prompt. They are injected into:
- User messages (before the actual user text)
- Tool call results (after ls, bash, read output)
- After every TodoWrite/checkpoint
- Between agent handoffs

**The key insight:** Every tool result is an opportunity to reinforce behavior.

```
Agent runs: ls apps/workflows/

Tool returns:
  models.py  api.py  tests.py  admin.py

  <system-reminder>
  You are implementing [REQ-002]. Tests must be written FIRST.
  Current phase: Phase 3 Implementation.
  Handoff format is mandatory (docs/patterns/handoff-protocol.md).
  </system-reminder>
```

The agent just ran a simple `ls`. But the reminder reinforces:
- Which requirement it's working on
- That TDD is mandatory
- That handoff format is required

**Without this:** By the 10th tool call, the agent has forgotten it should write tests first.
**With this:** Every tool result reminds it.

### 3. Conditional Context Injection

Not ALL reminders are appropriate ALL the time. Adapt based on what the agent is doing:

```
IF agent hasn't written a test yet AND is writing code:
  → Inject: "TDD: Write the test FIRST before this code."

IF agent hasn't run tests after writing code:
  → Inject: "Self-executing: RUN your code via Bash to verify."

IF agent is on its 3rd file without a commit:
  → Inject: "Commit checkpoint: Consider committing before continuing."

IF agent output doesn't match handoff format:
  → Inject: "Use handoff protocol format (docs/patterns/handoff-protocol.md)."
```

**The rule:** Inject the reminder that matches the agent's CURRENT behavior, not a generic list of all rules.

### 4. Subagent Context Adaptation

When the PM spawns a subagent:
- Start with a NARROW prompt (specific task, few tools)
- If the task turns out to be complex → conditionally inject more context
- Don't overload subagents with the full system prompt

```
Simple task: "Read this file and extract the model fields"
  → Narrow context: just Read tool, file path, output format
  → No need for Forge Cell, handoff protocol, etc.

Complex task: "Implement the workflow state machine"
  → Full context: Forge Cell, TDD, handoff protocol, rules, etc.
  → Injected gradually as complexity becomes apparent
```

## How Forge Should Use These

### In hooks/hooks.json

The PostToolUse hooks already inject reminders after file writes. Expand to cover ALL tool results:

```json
{
  "PostToolUse": [
    {
      "matcher": "Bash|Read|Glob|Grep",
      "action": "inject_reminder",
      "message": "Current: [REQ-xxx]. Phase: [N]. Remember: TDD, handoff format, /learn insights."
    }
  ]
}
```

### In the PM Orchestrator

Before spawning each agent:
1. Run context front-loading (summarize + topic check)
2. Provide focused context (not the entire Forge system prompt)
3. Inject reminders into tool results during execution
4. Adapt context if task complexity increases

### In Agent Prompts

Every agent's `<system-reminder>` block should include:
- The specific [REQ-xxx] it's working on
- The current Phase number
- The mandatory output format
- The key rule most likely to be forgotten

## The Measurement

Track drift indicators:
- Does the agent follow handoff format on turn 1? Turn 10? Turn 20?
- Does the agent write tests first on turn 1? Turn 10?
- Does the agent use [REQ-xxx] tags consistently?

If compliance drops after turn N → more frequent reminders needed.
If compliance stays high → reminders are working.
