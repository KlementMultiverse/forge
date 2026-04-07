### CASE 1: NEW PROJECT (no CLAUDE.md or placeholder CLAUDE.md)

#### Phase A — Setup (Session 1: creates all files agents need)

<!-- Architecture: PM behaviors (self-correction, anti-patterns, confidence routing,
     chaos resilience) are auto-loaded from rules/pm-behaviors.md via Pipe 1.
     Universal agent execution loop auto-loaded from rules/universal-agent-loop.md.
     This file routes to sub-files for each step group. -->

<system-reminder>
SESSION 1 RULES:
- PM behaviors auto-loaded from rules/pm-behaviors.md
- Universal agent loop auto-loaded from rules/universal-agent-loop.md
- PM orchestrates but NEVER writes CLAUDE.md or SPEC.md directly
- Each file is built by a SPECIALIST AGENT following a TEMPLATE
- Every agent output VERIFIED via universal loop (rate >= 4, retry if < 4, max 3)
- Session 1 ends with "Setup complete. Run forge again to build."
- NO CODE IS WRITTEN in Session 1 — only planning/spec/config files
</system-reminder>

**STEP S1: PREPARE** (PM prepares workspace — no agents)

NOTE: Project type detection (GREENFIELD/BROWNFIELD/EXISTING) was already done by the UserPromptSubmit hook before reaching this file. S1 does NOT re-detect — it only prepares the workspace.

```bash
# 1. Ensure git repo (user may have forgotten git init)
if [ ! -d ".git" ]; then
    git init -b main
    echo "[FORGE] Initialized git repository"
fi

# 2. Create directories needed by S3-S9
mkdir -p docs/forge-trace docs/proposals docs/retrospectives

# 3. Check for partial setup (Phase A was interrupted previously)
# If CLAUDE.md exists but SPEC.md or .forge/ is missing → resume from missing step
```

Based on partial setup check:
- Nothing exists → Read commands/forge-phases/phase-a-s2-discovery.md → start S2
- CLAUDE.md exists but no SPEC.md → Read commands/forge-phases/phase-a-s3-s5-specs.md → resume at S4
- CLAUDE.md + SPEC.md but no scaffold → Read commands/forge-phases/phase-a-s6-s8-scaffold.md → resume at S7
- Everything exists → "Setup already complete. Run /forge again to build."

**STEP ROUTING** — PM reads the sub-file for the current step group:

| Steps | Sub-file | What it does |
|-------|----------|-------------|
| S2 (Q1-Q7) | `commands/forge-phases/phase-a-s2-discovery.md` | Adaptive discovery with 8-part protocol |
| S3-S5 | `commands/forge-phases/phase-a-s3-s5-specs.md` | Generate CLAUDE.md, SPEC.md, FORGE.md |
| S6-S8 | `commands/forge-phases/phase-a-s6-s8-scaffold.md` | Generate rules, scaffold, infrastructure |
| S9-S10 | `commands/forge-phases/phase-a-s9-s10-review.md` | Review all files + commit |

PM MUST Read the sub-file before executing those steps. Do NOT try to execute from memory.

---

**BROWNFIELD VARIANT** (code exists, no CLAUDE.md):
Read commands/forge-phases/phase-a-s9-s10-review.md for brownfield steps (S5-BROWNFIELD).

---

#### Phase B — Full SDLC (CHAINED EXECUTION — each step MUST complete before next)

<system-reminder>
CHAINED EXECUTION PROTOCOL — ENFORCED BY HOOKS AND SCRIPTS:

BEFORE ANYTHING: Run `bash scripts/forge-enforce.sh check-state` to load current state.
BEFORE ANYTHING: Run `bash scripts/forge-enforce.sh check-continuation` to find the NEXT step.
BEFORE ANYTHING: Run `bash scripts/docker-state.sh` to capture Docker state.

RESUME LOGIC — CRITICAL:
  Read docs/forge-state.json. For each step:
  - If status = "DONE" → SKIP IT. Do not re-run completed steps.
  - If status = "NOT_STARTED" → EXECUTE this step.
  - If status = "IN_PROGRESS" → RESUME this step.

Each step below MUST be executed using the Skill tool (for commands) or Agent tool (for agents).
After EACH step: verify output, log trace, update state, THEN proceed.

AUTO-CONTINUATION — MANDATORY:
  NEVER stop to ask "should I continue?" — always continue.
  NEVER ask which agent to use — consult agent-routing.md.
  ONLY stop for: gate BLOCKED, /challenge RETHINK, missing credentials, 3 failed retries.
</system-reminder>
