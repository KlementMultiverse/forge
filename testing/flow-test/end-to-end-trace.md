# Forge End-to-End Flow Trace

**Date:** 2026-04-02
**Traced by:** Claude Code audit
**Scope:** All 7 flow paths, all commands, all agents

---

## COMMAND EXISTENCE INVENTORY

### Forge-native commands (in `/home/intruder/projects/forge/commands/`)

| Command | File Exists | Installed to ~/.claude/commands/ |
|---------|------------|----------------------------------|
| /forge | YES - forge.md | NO (not in ~/.claude/commands/) |
| /discover | YES - discover.md | NO |
| /requirements | YES - requirements.md | NO |
| /feasibility | YES - feasibility.md | NO |
| /generate-spec | YES - generate-spec.md | NO |
| /bootstrap | YES - bootstrap.md | NO |
| /challenge | YES - challenge.md | NO |
| /investigate | YES - investigate.md | NO |
| /learn | YES - learn.md | NO |
| /careful | YES - careful.md | NO |
| /freeze | YES - freeze.md | NO |
| /guard | YES - guard.md | NO |
| /evolve | YES - evolve.md | NO |
| /prune | YES - prune.md | NO |
| /review | YES - review.md | NO |
| /security-scan | YES - security-scan.md | NO |
| /design-audit | YES - design-audit.md | NO |
| /critic | YES - critic.md | NO |
| /benchmark | YES - benchmark.md | NO |
| /codex | YES - codex.md | NO |
| /canary | YES - canary.md | NO |
| /ship | YES - ship.md | NO |
| /plan-review | YES - plan-review.md | NO |
| /design-system | YES - design-system.md | NO |
| /qa-report | YES - qa-report.md | NO |
| /create-mcp | YES - create-mcp.md | NO |

**CRITICAL FINDING:** `install.sh` copies commands to `~/.claude/commands/` but NONE of the Forge-native commands are currently installed there. The install script copies `*.md` from `forge/commands/` to `~/.claude/commands/`, but the user has NOT run `./install.sh` (or it was run and overwritten). Only SuperClaude + custom commands exist in `~/.claude/commands/`.

### SuperClaude/base commands (in `~/.claude/commands/`)

| Command | File Exists | Notes |
|---------|------------|-------|
| /specify | YES | ~/.claude/commands/specify.md |
| /design-doc | YES | ~/.claude/commands/design-doc.md |
| /plan-tasks | YES | ~/.claude/commands/plan-tasks.md |
| /gate | YES | ~/.claude/commands/gate.md |
| /checkpoint | YES | ~/.claude/commands/checkpoint.md |
| /retro | YES | ~/.claude/commands/retro.md |
| /audit-patterns | YES | ~/.claude/commands/audit-patterns.md |
| /run-with-checkpoint | YES | ~/.claude/commands/run-with-checkpoint.md |
| /autoresearch | YES | ~/.claude/commands/autoresearch.md |
| /build-project | YES | ~/.claude/commands/build-project.md |
| /sc:implement | YES | ~/.claude/commands/sc/implement.md |
| /sc:test | YES | ~/.claude/commands/sc/test.md |
| /sc:brainstorm | YES | ~/.claude/commands/sc/brainstorm.md |
| /sc:build | YES | ~/.claude/commands/sc/build.md |
| /sc:analyze | YES | ~/.claude/commands/sc/analyze.md |
| /sc:cleanup | YES | ~/.claude/commands/sc/cleanup.md |
| /sc:document | YES | ~/.claude/commands/sc/document.md |
| /sc:estimate | YES | ~/.claude/commands/sc/estimate.md |
| /sc:git | YES | ~/.claude/commands/sc/git.md |
| /sc:improve | YES | ~/.claude/commands/sc/improve.md |
| /sc:index-repo | YES | ~/.claude/commands/sc/index-repo.md |
| /sc:load | YES | ~/.claude/commands/sc/load.md |
| /sc:save | YES | ~/.claude/commands/sc/save.md |
| /sc:reflect | YES | ~/.claude/commands/sc/reflect.md |
| /sc:research | YES | ~/.claude/commands/sc/research.md |
| /sc:spawn | YES | ~/.claude/commands/sc/spawn.md |
| /sc:troubleshoot | YES | ~/.claude/commands/sc/troubleshoot.md |
| /sc:workflow | YES | ~/.claude/commands/sc/workflow.md |
| /sc:spec-panel | YES | ~/.claude/commands/sc/spec-panel.md |
| /sc:task | YES | ~/.claude/commands/sc/task.md |

### Agent files (in `/home/intruder/projects/forge/agents/`)

**Universal agents (28 files exist):**
- deep-researcher.md, requirements-analyst.md, business-panel-experts.md
- system-architect.md, backend-architect.md, api-architect.md
- security-engineer.md, quality-engineer.md, performance-engineer.md
- frontend-architect.md, devops-architect.md, python-expert.md
- refactoring-expert.md, technical-writer.md, reviewer.md
- code-archaeologist.md, root-cause-analyst.md, self-review.md
- learning-guide.md, socratic-mentor.md, repo-index.md
- context-loader-agent.md, pattern-auditor-agent.md, agent-factory.md
- playbook-curator.md, playwright-critic.md, sdlc-enforcer.md
- retrospective-miner.md, aws-setup-agent.md
- ALSO: mcp-architect.md, tools-architect.md (not listed in PM orchestrator)

**Stack agents (Django):**
- django-tenants-agent.md, django-ninja-agent.md, s3-lambda-agent.md

**Other stack agents:**
- Azure: azure-openai-agent.md, azure-setup-agent.md
- GCP: gcp-setup-agent.md, vertex-ai-agent.md
- GenAI: agent-orchestrator.md, ai-safety-agent.md, chatbot-builder.md, eval-engineer.md, llm-integration-agent.md, rag-architect.md, voice-agent-builder.md
- LangChain: langchain-agent.md, langgraph-agent.md, langsmith-agent.md

**CRITICAL FINDING about agents:** These are .md prompt files, NOT executable code. They work via Claude Code's `Agent` tool (subagent spawning). The PM orchestrator says "Spawn @agent-name" but this means "use the Agent tool with the agent's prompt as instructions." There is no agent registry or runtime -- it depends entirely on Claude Code reading the .md file and following its instructions within a subagent call.

---

## FLOW 1: Brand New Project (Greenfield)

**Trigger:** User says `/forge "Build a bookmark manager"`

### Step-by-step trace:

1. **`/forge` command invoked**
   - **EXISTS?** YES, as `forge/commands/forge.md`
   - **INSTALLED?** Only if user ran `./install.sh`. Currently NOT installed to `~/.claude/commands/`.
   - **ACTUAL MECHANISM:** Claude Code reads forge.md as a slash command prompt. The entire file is injected into the conversation as instructions.

2. **Phase 0: Genesis**

   a. **`/discover`** -- Spawns `@deep-research-agent`
   - EXISTS? YES (forge/commands/discover.md + agents/universal/deep-researcher.md)
   - MECHANISM: PM (Claude) reads discover.md instructions, then uses the Agent tool to spawn a subagent with the deep-researcher.md prompt
   - OUTPUT: `docs/discovery-report.md`
   - **WORKS:** The command is well-defined. The agent prompt exists. Output location specified.
   - **AMBIGUOUS:** "Spawn @deep-research-agent" -- the PM orchestrator references `@deep-research-agent` but the file is `deep-researcher.md`. Name mismatch (minor).
   - **MISSING:** No mechanism to verify the agent actually used WebSearch or context7. It's all trust-based.

   b. **`/requirements`** -- Spawns `@requirements-analyst` + `/sc:brainstorm`
   - EXISTS? YES (both files exist)
   - OUTPUT: `docs/requirements.md` with [REQ-xxx] tags
   - **WORKS:** Command defined, agent exists, output format specified.
   - **MISSING:** The "Then spawn /sc:brainstorm" step -- /sc:brainstorm exists but there's no enforcement that it actually runs after requirements-analyst.

   c. **`/feasibility`** -- Spawns `@system-architect` + `@security-engineer`
   - EXISTS? YES
   - OUTPUT: `docs/feasibility.md`
   - **WORKS:** Commands and agents exist.
   - **CRITICAL:** "ASK USER" step -- this is the first hard stop. PM must ask user to confirm stack.
   - **AMBIGUOUS:** "Check: agents exist for this stack?" -- this check is purely Claude reading the agents/stacks/ directory. No programmatic check exists.
   - **MISSING:** `@agent-factory` is referenced for creating new agents on the fly. The file exists (agent-factory.md), but creating a new agent means writing a new .md file during the session. Untested whether this actually produces usable agents.

   d. **`/generate-spec`** -- PM synthesizes 3 docs into SPEC.md
   - EXISTS? YES
   - **NOTABLE:** This is one of the few commands where the PM itself does the work (not an agent). It reads the template and fills it in.
   - **WORKS:** Well-defined input/output.
   - **MISSING:** No validation that ALL [REQ-xxx] from requirements.md made it into SPEC.md beyond the judge step.

   e. **`/challenge`** -- 6 forcing questions
   - EXISTS? YES
   - OUTPUT: Spec Challenge Report with verdict (PROCEED/REFINE/RETHINK)
   - **WORKS:** Self-contained prompt-based analysis.
   - **CRITICAL:** If verdict is RETHINK, flow STOPS and asks user. This is the second hard stop.
   - **AMBIGUOUS:** Who evaluates the 6 questions? The PM itself? No agent is specified.

   f. **`/bootstrap`** -- Scaffolds the project
   - EXISTS? YES
   - **MECHANISM:** Creates folder, copies templates, runs `git init`, runs `gh repo create`
   - **WORKS:** Template files exist (CLAUDE.template.md, SPEC.template.md, docker-compose.template.yml, pyproject.template.toml)
   - **BROKEN:** References `.gitignore.template` in pm-orchestrator.md but the actual file is `.gitignore.template` -- NOT in templates/ directory. Templates dir contains no .gitignore template.
   - **DEPENDENCY:** Requires `gh` CLI installed and authenticated for `gh repo create`.

   g. **`@code-archaeologist` baseline**
   - EXISTS? YES (agents/universal/code-archaeologist.md)
   - **WORKS:** Agent prompt exists.
   - **AMBIGUOUS:** For a greenfield project, what does "baseline assessment" even mean? The project was just scaffolded.

   h. **`/sc:index-repo`** + **`/sc:load`**
   - EXISTS? YES (both in ~/.claude/commands/sc/)
   - **WORKS:** These are SuperClaude commands, tested and functional.

   i. **`/gate phase-0`**
   - EXISTS? YES (~/.claude/commands/gate.md)
   - **MECHANISM:**
     1. Runs `/audit-patterns quick`
     2. Commits and pushes via `/sc:git --smart-commit`
     3. Creates PR via `gh pr create`
     4. Polls for CodeRabbit review via `gh api`
     5. Checks review state = "APPROVED"
   - **WORKS:** The gate command is thoroughly defined with exact `gh api` commands.
   - **DEPENDENCY:** Requires CodeRabbit installed on the GitHub repo. If not installed, gate will timeout after 3 minutes.
   - **MISSING:** No fallback if CodeRabbit is not configured. The gate just says "check webhook config" and STOPS.

### GitHub Issue Creation
- **HOW:** Via `gh issue create` CLI commands embedded in /specify and /plan-tasks
- **WORKS:** The gh commands are well-formed with --title, --body, --label flags.
- **DEPENDENCY:** Requires gh CLI authenticated + repo exists on GitHub.

### Verdict for Flow 1:
- **WORKS:** All command files exist. All agent files exist. The flow is logically complete.
- **BROKEN:** Forge commands not installed to ~/.claude/commands/ (need to run install.sh). Missing .gitignore template.
- **MISSING:** No enforcement mechanism -- everything depends on Claude faithfully following the PM orchestrator prompt. No code validates sequence.
- **AMBIGUOUS:** Agent "spawning" is just the Agent tool with a prompt. Whether Claude actually reads all the referenced files before acting is trust-based.

---

## FLOW 2: Existing Repo (Brownfield)

**Trigger:** User has clinic-portal repo, wants to add a feature.

### Step-by-step trace:

1. **Session Start** (from PM orchestrator "Session Lifecycle"):
   - `/sc:load` restores session context
   - Read CLAUDE.md -- check for SDLC Flow section
   - Load playbook, rules, ethos
   - Read checkpoint INDEX.md
   - Read PROJECT_INDEX.md

2. **Detection of existing project:**
   - **HOW?** PM reads CLAUDE.md at session start (line 128-132 of pm-orchestrator.md)
   - If CLAUDE.md has "SDLC Flow" section -- follow it EXACTLY
   - If no SDLC Flow -- check if `/forge` was invoked
   - If neither -- use default PDCA cycle
   - **WORKS:** The detection logic is clearly defined.

3. **Does it run /sc:index-repo?**
   - Only if PROJECT_INDEX.md doesn't exist yet.
   - If it exists, it's loaded at session start.
   - **AMBIGUOUS:** No explicit "if no index, create one" step for brownfield.

4. **How does it know what already exists?**
   - Reads CLAUDE.md (tech stack, rules, architecture)
   - Reads PROJECT_INDEX.md (file listing with descriptions)
   - Reads SPEC.md (requirements)
   - Reads existing code via Grep/Glob/Read tools
   - @code-archaeologist can scan the codebase
   - **WORKS:** Multiple mechanisms for understanding existing code.

### Verdict for Flow 2:
- **WORKS:** Session start lifecycle correctly prioritizes reading CLAUDE.md for custom SDLC flows.
- **MISSING:** No explicit "brownfield detection" step. It relies on CLAUDE.md existing.
- **MISSING:** No command to analyze an existing repo and generate CLAUDE.md + SPEC.md retroactively (you'd have to run /forge which assumes greenfield Genesis).
- **AMBIGUOUS:** If the user has a repo with NO CLAUDE.md and NO SPEC.md, the PM says "STOP: Cannot orchestrate without project definition. Run /bootstrap first." But /bootstrap assumes a greenfield scaffold.

---

## FLOW 3: New Issue/Feature on Existing Project

**Trigger:** User says "Add dark mode to the dashboard"

### Step-by-step trace:

1. **PM reads the request** and determines this is a new feature, not a bug.

2. **Does it create a GitHub issue first?**
   - NOT immediately. The PM first needs to determine scope.
   - Flow: user request -> PM decides which stage to enter (Phase 1 for features, Phase 3 for small changes).

3. **For a feature (goes to Phase 1: SPECIFY):**
   a. `/specify` runs on the feature description
      - @requirements-analyst extracts requirements
      - @business-panel-experts validates
      - Produces `docs/proposals/NN-dark-mode.md`
      - **Creates GitHub Issues** via `gh issue create` (one per task in implementation plan)
      - **WORKS:** Well-defined flow.

   b. `/checkpoint` evaluates the proposal

   c. `/gate stage-1` -- PR + CodeRabbit

4. **Phase 2: ARCHITECT:**
   a. `/design-doc` on the proposal
      - @system-architect, @backend-architect, @security-engineer
      - Produces `docs/design-doc.md` with 10 sections
   b. `/plan-tasks` on the design doc
      - Creates more GitHub Issues with labels
   c. `/gate stage-2`

5. **Phase 3: IMPLEMENT:**
   - For each GitHub Issue (in dependency order):
   - **Which agent picks it up?** Based on domain label on the issue:
     - `domain-tenants` -> @django-tenants-agent
     - `domain-auth` -> @django-ninja-agent
     - `domain-frontend` -> /sc:implement (frontend persona)
     - etc. (from Agent Selection Matrix in CLAUDE.md)
   - **WORKS:** Label-based routing is clearly defined.

6. **How does it know which files to touch?**
   - The design doc Section 4 lists "File Changes" explicitly
   - Each GitHub Issue body contains the files to modify
   - The agent reads PROJECT_INDEX.md + existing code
   - **WORKS:** Multiple sources of file targeting.

7. **Sync check (spec<->test<->code):**
   - Step 5 of Forge Cell: [REQ-xxx] tags traced across SPEC.md, test files, and code files
   - `scripts/traceability.sh` is a real bash script that greps for [REQ-xxx] tags
   - Reports: coverage %, orphans (code without REQ), drift (REQ without code)
   - **WORKS:** traceability.sh exists and is functional (reads SPEC.md, tests/, apps/).
   - **LIMITATION:** Only works if [REQ-xxx] tags are consistently placed in comments. If developers forget tags, sync check misses coverage.

### Task-level design doc (Step 0 of Forge Cell):
- Template exists: `templates/task-design-doc.template.md`
- **WORKS:** Template file exists.
- **AMBIGUOUS:** When is this "mini design doc" written vs skipped? The PM decides "simple issues skip to Step 1."

### Verdict for Flow 3:
- **WORKS:** Full feature flow from request to implementation is defined with clear stage transitions.
- **MISSING:** No explicit way to say "this is a small change, skip Phase 1+2 and go directly to Phase 3."
- **AMBIGUOUS:** The PM orchestrator says "Loop to Phase 1 (features) or Phase 3 (fixes)" but doesn't define the threshold between a "feature" and a "fix."

---

## FLOW 4: Bug Fix

**Trigger:** User says "Login returns 302 instead of 401"

### Step-by-step trace:

1. **PM identifies this as a bug** (not a feature).
   - Flow goes to Phase 6: Iterate -> /investigate FIRST

2. **`/investigate` runs:**
   - EXISTS? YES
   - Spawns `@root-cause-analyst`
   - Agent reads error, identifies root cause, provides evidence, recommends fix
   - Output: Investigation report (root cause + evidence + recommended fix + prevention)
   - **WORKS:** Well-defined command and agent.
   - **DOES @root-cause-analyst actually get spawned?** Yes, IF Claude faithfully follows the /investigate instructions. The Agent tool must be invoked.

3. **Fix implementation:**
   - The domain agent (NOT root-cause-analyst) implements the fix
   - Follows the Forge Cell (9 steps): context load -> research -> TDD -> build -> sync check -> judge -> commit
   - **WORKS:** Clear separation between investigation and fixing.

4. **How does the fix get tested?**
   - Step 3 of Forge Cell: TDD
     - Write TEST first (must fail without fix)
     - Write FIX
     - Run test (must pass)
     - Run ALL tests (no regressions)
   - **WORKS:** TDD flow is well-defined.

5. **How does the fix get committed?**
   - Step 7 of Forge Cell: `/sc:git commit` with conventional message
   - GitHub issue closed
   - `/checkpoint` evaluates
   - `/learn` captures prevention insight
   - **WORKS:** Clear commit flow.

6. **Prevention:**
   - /investigate output includes a "Prevention" section
   - This becomes a `/learn` entry in the playbook
   - **WORKS:** Learning loop is defined.

### Verdict for Flow 4:
- **WORKS:** Complete bug fix flow from report to prevention.
- **MISSING:** No triage step -- how does PM determine severity? No priority routing.
- **MISSING:** No way to distinguish "quick fix" from "complex bug requiring investigation."
- **AMBIGUOUS:** Does the user need to run `/investigate` manually, or does the PM auto-invoke it? The PM orchestrator says "Bug found -> /investigate FIRST" which implies auto-invoke.

---

## FLOW 5: Test -> Fix -> Verify Cycle (Reflexion)

**Trigger:** Agent writes code, tests fail.

### Step-by-step trace:

1. **Test failure detected** in Step 4 of Forge Cell (BUILD + QUALITY):
   ```
   Run full test suite via Bash -> FAIL
   ```

2. **Reflexion loop (max 3 attempts):**

   Attempt 1:
   - Run `/sc:troubleshoot` (diagnosis before fix)
   - Run `/investigate` (root cause analysis by @root-cause-analyst)
   - Domain agent tries a DIFFERENT approach (not the same thing again)
   - Run tests again

   Attempt 2 (if still failing):
   - Same cycle: troubleshoot -> investigate -> different fix -> test
   - **CRITICAL RULE:** "NEVER retry the same approach -- try something DIFFERENT"

   Attempt 3 (if still failing):
   - Same cycle one more time

   After 3 failures:
   - **STOP and ask user**
   - Document what was tried
   - PM reports: "3 reflexion attempts failed on issue #N. Approaches tried: [list]. Asking for human guidance."

3. **How does reflexion actually work?**
   - **MECHANISM:** It's a prompt-level loop, not programmatic code. The PM orchestrator tracks attempt count mentally (in conversation context). There is NO code counter.
   - `/sc:troubleshoot` exists as a SuperClaude command
   - `/investigate` exists and spawns @root-cause-analyst
   - The "try something DIFFERENT" rule is enforced only by prompt instructions
   - **WORKS:** The flow is logically sound.
   - **BROKEN:** No programmatic enforcement of "max 3." If Claude loses track of context (e.g., after compaction), it might retry more or fewer times.
   - **MISSING:** No persistence of attempt count across context compaction events.

4. **What if all 3 attempts fail?**
   - PM STOPS
   - Documents all 3 attempts
   - Asks user for guidance
   - User can: provide a hint, skip the issue, or manually fix
   - **WORKS:** Escalation path is defined.
   - **AMBIGUOUS:** After user provides guidance, does the counter reset? The docs don't say.

### Verdict for Flow 5:
- **WORKS:** The reflexion concept is well-defined with clear escalation.
- **BROKEN:** No programmatic counter -- relies on Claude's conversation memory.
- **MISSING:** No persistence mechanism for attempt tracking across sessions or compaction.
- **AMBIGUOUS:** Counter reset behavior after user intervention.

---

## FLOW 6: GitHub Integration

### Issue Creation
- **HOW:** `gh issue create` CLI commands
- **WHERE:** In /specify (Phase 3 saves) and /plan-tasks (Phase 3 creates)
- **LABELS:** `phase-N-implement`, `ready`, `domain-[relevant]`, `priority-[level]`
- **WORKS:** gh commands are well-formed in both command files.
- **DEPENDENCY:** Requires `gh` CLI installed and authenticated.

### Issue Assignment to Agents
- **HOW:** By label. The Agent Selection Matrix in CLAUDE.md maps `domain-*` labels to agents:
  - `domain-tenants` -> @django-tenants-agent
  - `domain-auth` -> @django-ninja-agent
  - `domain-workflows` -> @django-ninja-agent
  - `domain-documents` -> @s3-lambda-agent + @django-ninja-agent
  - `domain-aws` -> @aws-setup-agent
  - `domain-frontend` -> /sc:implement
- **WORKS:** Clear routing table.
- **MISSING:** No `gh issue edit --assignee` command to actually assign issues in GitHub. Assignment is conceptual (PM knows which agent handles it) not reflected in GitHub.

### Issue Closing
- **HOW:** Step 7 of Forge Cell says "close issue" but no explicit `gh issue close #N` command is shown.
- **AMBIGUOUS:** Is it `gh issue close`? Or does the PR merge auto-close? The flow creates PRs per gate, so issues might close via "Fixes #N" in commit messages, but this is never explicitly stated.

### PR Creation
- **HOW:** `/gate` command runs `gh pr create` with title, body, labels
- **WORKS:** The exact gh command is in gate.md with proper heredoc body formatting.
- **MECHANISM:** Every /gate creates a PR for that stage.

### CodeRabbit Review
- **HOW:** /gate polls `gh api repos/{owner}/{repo}/pulls/{pr_number}/reviews`
- **TRIGGER:** CodeRabbit triggers automatically via GitHub webhook when a PR is created.
- **POLLING:** Max 5 retries, 30s apart (total 3 min timeout).
- **PASS CONDITION:** Last review from coderabbitai[bot] must have state = "APPROVED"
- **WORKS:** Polling logic and pass/fail conditions are well-defined.
- **DEPENDENCY:** Requires CodeRabbit installed as a GitHub App on the repo.
- **BROKEN if not installed:** Gate will timeout and STOP with "check webhook config."
- **MISSING:** No step to INSTALL CodeRabbit if it's not already on the repo. No `gh api` command to check if CodeRabbit is installed.

### Verdict for Flow 6:
- **WORKS:** Issue creation, PR creation, and CodeRabbit polling are well-defined.
- **BROKEN:** Issue closing mechanism is ambiguous.
- **MISSING:** No issue assignment in GitHub. No CodeRabbit installation check.
- **DEPENDENCY:** Entire gate system depends on gh CLI + CodeRabbit GitHub App.

---

## FLOW 7: Learning/Playbook

### /learn -- Save Insight

- **HOW:** Reads `playbook/strategies.md`, checks for duplicates, adds new entry or increments counter.
- **FORMAT:** `[str-NNN] helpful=0 harmful=0 :: insight text`
- **WORKS:** Command file is well-defined. Playbook files are initialized by `install.sh init`.
- **WHERE does playbook live?**
  - Global: `forge/playbook/strategies.md` (in forge repo)
  - Project-local: `.forge/playbook/strategies.md` (created by `install.sh init`)
  - **AMBIGUOUS:** Which one does /learn write to? The command doesn't specify. It says "playbook/strategies.md" which is relative -- could be either.

### Counter Updates (helpful/harmful)
- **HOW:** /retro and /checkpoint update counters based on outcomes.
  - /retro: @learning-guide extracts lessons, updates CLAUDE.md and playbook
  - /checkpoint: If a strategy was used and output was PASS, increment helpful. If FAIL, increment harmful.
- **MECHANISM:** Text editing of the .md file (Edit tool changes `helpful=3` to `helpful=4`).
- **WORKS:** The concept is sound.
- **BROKEN:** No lock mechanism. If two agents write to playbook simultaneously (max 2 parallel agents per PM rules), they could overwrite each other.
- **MISSING:** No explicit code in /checkpoint that says "find the strategy used and increment its counter." The checkpoint evaluates the agent output but doesn't trace back to which strategy was applied.

### /prune -- Remove Bad Rules
- **HOW:** Reads strategies.md, finds entries where `harmful > helpful`, moves them to `playbook/archived.md` with date and reason.
- **WORKS:** Well-defined pruning criteria and archive mechanism.
- **TRIGGER:** Run after every /retro.
- **MISSING:** The "age > 5 builds" criterion has no mechanism to track builds per entry.

### /evolve -- Cluster into Skills
- **HOW:** Finds 3+ related strategies with helpful > 3, creates a skill file in rules/ or agents/stacks/.
- **WORKS:** Well-defined clustering logic.
- **MISSING:** No mechanism to detect "related" strategies beyond Claude's judgment. No embedding similarity or tag matching.

### Verdict for Flow 7:
- **WORKS:** /learn, /prune, /evolve are all well-defined commands with clear file operations.
- **BROKEN:** Counter increment mechanism is implicit, not explicit. No concurrent write protection.
- **MISSING:** Build counter for age-based pruning. Relatedness detection for /evolve.
- **AMBIGUOUS:** Which playbook file (global vs project-local) is the target.

---

## HOOKS ANALYSIS

**File:** `/home/intruder/projects/forge/hooks/hooks.json`

### PreToolUse hooks (9 rules):
1. Block destructive ops (rm -rf, git reset --hard, etc.) -- **WORKS if hooks.json is loaded by Claude Code**
2. Block --no-verify on git -- **WORKS**
3. Command injection detection -- **WORKS** (blocks subshell+curl, eval, chained backticks)
4. Block dev server starts -- **WORKS**
5. Secret detection in Write/Edit -- **WORKS**
6. TDD guard (warn if writing code without test) -- **AMBIGUOUS:** `check: "no_matching_test_file"` is a custom check with no implementation
7. Smart-approve safe commands -- **WORKS** (auto-approves ls, cat, grep, etc.)
8. Config file protection -- **WORKS** (warns on pyproject.toml, settings.py edits)
9. File size limit -- **AMBIGUOUS:** `check: "line_count > 300"` is a custom check with no implementation

### PostToolUse hooks (7 rules):
1. Auto-format Python with black+ruff -- **AMBIGUOUS:** `command: "black {file}"` -- the `{file}` interpolation has no implementation
2. Auto-checkpoint logging -- **WORKS** (just a log message)
3. Sync check reminder -- **WORKS** (reminder text)
4. Debt violation check -- **AMBIGUOUS:** `check: "grep -n 'TODO' {file}"` needs interpolation
5. Learning log reminder -- **WORKS** (reminder text)
6. Commit guard -- **AMBIGUOUS:** `check: "commit_message_format"` is a custom check
7. Drift prevention reminder injection -- **WORKS** (injects system-reminder)

### SessionStart hooks (4 rules):
1. Load playbook, rules, ethos -- **AMBIGUOUS:** `action: "load"` with file paths -- no implementation for auto-loading
2. Load checkpoint index -- **WORKS** conceptually
3. Report session context -- **WORKS** (reminder message)
4. Context front-loading -- **AMBIGUOUS:** `action: "run"` with a natural language command -- no implementation

**CRITICAL FINDING about hooks:** The hooks.json file defines 21 rules, but Claude Code's hooks system only supports a SUBSET of these actions:
- `action: "deny"` with pattern matching -- **LIKELY WORKS** (Claude Code does support deny rules)
- `action: "approve"` -- **LIKELY WORKS** (auto-approval)
- `action: "warn"` -- **LIKELY WORKS** (warning messages)
- `action: "remind"` -- **CUSTOM** -- not a standard Claude Code hook action
- `action: "run"` with commands -- **CUSTOM** -- not standard
- `action: "load"` with file lists -- **CUSTOM** -- not standard
- `action: "log"` -- **CUSTOM** -- not standard
- `action: "inject_reminder"` -- **CUSTOM** -- not standard
- `check:` field with custom conditions -- **CUSTOM** -- not standard

**Many hooks are ASPIRATIONAL, not functional.** The deny/warn/approve hooks likely work. The run/load/log/inject_reminder/check hooks require custom infrastructure that doesn't exist.

---

## SCRIPTS ANALYSIS

### traceability.sh
- **EXISTS:** Yes, at `scripts/traceability.sh`
- **WORKS:** Real bash script that greps for [REQ-xxx] tags across SPEC.md, tests/, and apps/
- **REPORTS:** Coverage %, orphan code, drift
- **LIMITATION:** Only works with grep-based tag detection. Tags must be in `[REQ-NNN]` format.

### sync-report.sh
- **EXISTS:** Yes, at `scripts/sync-report.sh`
- Not read in detail but exists alongside traceability.sh.

---

## TEMPLATES ANALYSIS

All referenced templates exist:
- `SPEC.template.md` -- YES
- `CLAUDE.template.md` -- YES
- `test.template.py` -- YES
- `test.e2e.template.py` -- YES
- `docker-compose.template.yml` -- YES
- `pyproject.template.toml` -- YES
- `traceability-matrix.template.md` -- YES
- `task-design-doc.template.md` -- YES
- `design-doc-completeness-checklist.md` -- YES
- `design-doc.example.md` -- YES
- `gate-handoff-checklists.md` -- YES

**MISSING:** `.gitignore.template` (referenced in pm-orchestrator.md line 73 but not in templates/).

---

## MASTER SUMMARY

### What ACTUALLY WORKS end-to-end:

1. **Command files** -- All 26 Forge commands and all 30+ SuperClaude commands exist as .md files with complete instructions.
2. **Agent files** -- All 28+ universal agents and stack-specific agents exist as .md prompt files.
3. **Template files** -- 11 templates exist and are well-structured.
4. **traceability.sh** -- Real executable script that checks [REQ-xxx] sync.
5. **install.sh** -- Real executable script that copies files to ~/.claude/.
6. **hooks.json** -- Defines 21 rules (deny/warn/approve hooks likely functional).
7. **Gate flow** -- /gate has exact `gh api` commands for CodeRabbit polling.
8. **GitHub integration** -- /specify and /plan-tasks have exact `gh issue create` commands.
9. **Playbook system** -- /learn, /prune, /evolve have clear file operations.
10. **The PM orchestrator prompt** -- Comprehensive orchestration instructions covering all phases.

### What is BROKEN:

1. **Forge commands not installed** -- forge/commands/ files are NOT in ~/.claude/commands/. User must run `./install.sh` first.
2. **Custom hook actions** -- `run`, `load`, `log`, `inject_reminder`, `check` are not standard Claude Code hook actions. ~50% of hooks are aspirational.
3. **No programmatic enforcement** -- Everything relies on Claude faithfully following prompts. No code validates sequence, counters, or state.
4. **Missing .gitignore template** -- Referenced but doesn't exist.
5. **Issue closing** -- No explicit `gh issue close` in the Forge Cell. Mechanism ambiguous.

### What is MISSING:

1. **Brownfield onboarding** -- No command to retroactively generate CLAUDE.md + SPEC.md for an existing project.
2. **CodeRabbit installation check** -- Gate assumes CodeRabbit is already installed.
3. **Reflexion counter persistence** -- No mechanism to track attempt count across context compaction.
4. **Build counter for playbook** -- /prune references "age > 5 builds" but no counter exists.
5. **Concurrent write protection** -- Playbook can be corrupted by parallel agent writes.
6. **Issue assignment in GitHub** -- Labels route agents but `gh issue edit --assignee` is never called.
7. **Feature vs fix threshold** -- No clear rule for when to enter Phase 1 vs Phase 3.
8. **Error recovery** -- If a gate fails and CodeRabbit is down, there's no bypass mechanism.
9. **Codex command** -- Requires secondary model API key with no detection/fallback.

### What is AMBIGUOUS:

1. **Agent "spawning"** -- Means different things in different contexts. Sometimes it's Agent tool (subagent), sometimes it's just "follow these instructions."
2. **Playbook location** -- Global forge/playbook/ vs project .forge/playbook/ -- /learn doesn't specify which.
3. **PM code writing** -- PM "NEVER writes application code" but /generate-spec has the PM filling in SPEC.md. Where is the line between "orchestration output" and "code"?
4. **Challenge evaluator** -- /challenge doesn't specify which agent evaluates the 6 forcing questions.
5. **Counter reset after user intervention** -- Does the reflexion counter reset?
6. **Hook check conditions** -- `no_matching_test_file`, `no_recent_test_write`, `commit_message_format`, `line_count > 300` have no implementation.

### Execution Dependencies:

| Dependency | Required By | Status |
|-----------|------------|--------|
| `gh` CLI | /gate, /specify, /plan-tasks, /ship, /critic, /qa-report, /bootstrap | Must be installed |
| CodeRabbit GitHub App | /gate (all gates) | Must be configured on repo |
| `black` | PostToolUse hook, Step 4 of Forge Cell | Must be in project deps |
| `ruff` | PostToolUse hook, Step 4 of Forge Cell | Must be in project deps |
| `uv` | All Python commands | Must be installed |
| Docker | /bootstrap scaffold | Must be installed |
| context7 MCP | @context-loader-agent, research steps | Must be configured |
| Playwright MCP | /critic, /design-audit | Must be configured |
| Secondary AI API | /codex | Optional (skipped if missing) |
| Claude Code Agent tool | All @agent spawning | Built into Claude Code |

### Architecture Reality:

The Forge system is a **prompt-based orchestration framework**. It has:
- NO runtime code (no Python/TypeScript orchestrator)
- NO state machine (no programmatic phase tracking)
- NO database (no persistent state beyond files)
- NO API (no webhooks, no event system)

It is ENTIRELY composed of:
- Markdown prompt files (.md) that instruct Claude Code
- A shell script (install.sh) that copies files
- A shell script (traceability.sh) that greps for tags
- A JSON file (hooks.json) that configures Claude Code hooks

The entire system relies on Claude Code's ability to:
1. Read prompt files and follow their instructions faithfully
2. Use the Agent tool to spawn subagents with focused prompts
3. Use Bash to run gh CLI commands for GitHub integration
4. Maintain conversational state across a multi-hour session

This is both the system's greatest strength (no infrastructure to maintain) and its greatest weakness (no enforcement beyond prompt adherence).
