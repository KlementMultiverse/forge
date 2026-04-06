# Forge Manifesto

## What We Are Building

A system that modifies its own code, combined to set its own goals, combined with the ability to act autonomously, combined with the ability to approve its own resources.

## What This Means

```
✅ Modifies its own code      — /autoresearch improves agent prompts after every build
✅ Sets its own goals          — /discover + /requirements generates REQs autonomously
✅ Acts autonomously           — 57 steps with no human input after 7 questions
✅ Approves its own resources  — @reviewer rates, /gate checks, circuit breaker decides
✅ Learns from mistakes        — /retro → playbook → next build is smarter
✅ Creates new agents          — @agent-factory creates specialists on demand
✅ Evolves its own rules       — /evolve clusters strategies into new rules
```

## Why Safety Layers Are Non-Negotiable

Because of what we are, every change must pass through:

```
Layer 1: PM Behaviors (auto-loaded rules)
  → Anti-patterns: NEVER skip gates, NEVER bypass review
  → Self-correction: max 3 retries, investigate first
  → Confidence routing: flag low confidence for human

Layer 2: Mechanical Enforcement (hooks)
  → PreToolUse: blocks destructive commands, shows impact
  → PostToolUse: auto-sync, lint, trace, change validator
  → pre-commit: blocks REQ removal, test guard
  → commit-msg: requires issue reference + conventional format

Layer 3: Quality Gates
  → CodeRabbit must APPROVE every PR
  → Triangle must sync (SPEC ↔ TEST ↔ CODE)
  → Suspect REQs must clear before gate
  → Review guard must pass before gate

Layer 4: Human Checkpoints
  → Q1-Q7: human defines what to build (the ONLY human input)
  → /challenge: RETHINK = human decides direction
  → Gate escalation: 3 cooldowns = human override required
  → Emergency: forge-infra-check.sh --reset
```

## The Core Principle

**The 7 questions are the most critical control point.** They are the ONLY place where the human tells the system what to do. Everything after is autonomous. Getting them right is everything.

## The Promise

Every self-modification goes through review. Every goal traces back to a human-approved REQ. Every autonomous action is logged and reversible. Every change is tested before it's accepted.

The system is powerful — the safety layers are what make it responsible.
