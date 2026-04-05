# Forge — autonomous software development
# Usage: forge              (in any folder — initializes if needed, opens claude)
#        forge myapp         (creates ~/projects/myapp, initializes, opens claude)
#        forge .             (initializes current folder, opens claude)
#        forge /path/to/dir  (initializes that folder, opens claude)
forge() {
  local FORGE_DIR="$HOME/projects/forge"
  export PATH="$HOME/.smux/bin:$HOME/.local/bin:$PATH"

  # Observer mode — run from anywhere, auto-detects project, auto-prompts
  if [ "$1" = "observe" ]; then
    # Find active project — explicit arg, or auto-detect
    local PROJ="${2:-}"
    # Convert relative path to absolute
    if [ -n "$PROJ" ] && [[ "$PROJ" != /* ]]; then
      PROJ="$HOME/projects/$PROJ"
    fi
    if [ -z "$PROJ" ]; then
      # 1. Check bridge file (written by forge builder)
      PROJ=$(cat "$HOME/.forge-bridge/active-project.txt" 2>/dev/null)
    fi
    if [ -z "$PROJ" ] || [ ! -d "$PROJ" ]; then
      # 2. Most recently modified forge-state.json (active forge builds only)
      PROJ=$(find "$HOME/projects" -name "forge-state.json" -printf '%T@ %h\n' 2>/dev/null | sort -rn | head -1 | awk '{print $2}' | sed 's|/docs||')
    fi
    if [ -z "$PROJ" ]; then
      # 3. Most recently modified .forge/ directory (forge-initialized projects)
      PROJ=$(find "$HOME/projects" -maxdepth 2 -name ".forge" -type d -printf '%T@ %h\n' 2>/dev/null | sort -rn | head -1 | awk '{print $2}')
    fi
    if [ -z "$PROJ" ]; then
      # 4. Most recently created git repo with no code yet (likely just forge-initialized)
      PROJ=$(find "$HOME/projects" -maxdepth 2 -name ".git" -type d -newer "$HOME/projects" -printf '%T@ %h\n' 2>/dev/null | sort -rn | head -1 | awk '{print $2}')
    fi
    if [ -z "$PROJ" ]; then
      echo "No forge project found. Usage: forge observe [project-name-or-path]"
      return 1
    fi

    cd "$HOME/.claude"
    claude "You are the OBSERVER for a forge build at $PROJ.

FIRST: Run /loop 1m to auto-check every minute. Then do your initial check.

## How to Check (MANDATORY — run this EVERY cycle)

STEP A: Run the check script:
  ! bash ~/.claude/scripts/forge-observer-check.sh $PROJ

STEP B: If the script outputs FILES NEED REVIEW, you MUST review each one:
  For EACH file listed:
    1. ! touch $PROJ/docs/.observer-reviewing
    2. Use Agent tool with subagent_type=reviewer to read and rate the file (1-5)
    3. ! echo the rating to $PROJ/docs/.observer-reviews.log
    4. ! rm -f $PROJ/docs/.observer-reviewing

STEP C: If the script outputs GATE BOUNDARY — APPROVAL NEEDED:
  ! bash ~/.claude/scripts/forge-observer-approve.sh approve $PROJ

STEP D: If the script outputs no review needed and no gate:
  Say the status line only. Do not expand.

You MUST run Step A every cycle. Steps B-D depend on Step A output.
If Step A shows REVIEW files, you CANNOT skip Step B — the builder is WAITING.

## Phase-Aware Monitoring (CRITICAL — do not flag wrong-phase violations)

Read forge-state.json to determine current phase. ONLY flag violations for the CURRENT or PAST phases:

### Phase A / Phase 0 (Setup + Genesis) — steps S1-S10 then 1-8
EXPECTED: Many files created, NO commits until Step S10, NO traces yet, NO gates yet.
The builder creates CLAUDE.md, SPEC.md, FORGE.md, rules, scaffold — then commits ALL at once.
ONLY flag: builder writing app code (apps/**/*.py with business logic) before SPEC.md exists.
DO NOT flag: no commits, no traces, no gates — these come LATER.

### Phase 1 (Specify) — steps 9-11
EXPECTED: /specify creates proposals, then checkpoint + gate.
ONLY flag: no SPEC.md, no proposal created.

### Phase 2 (Architect) — steps 12-19
EXPECTED: design-doc, plan-tasks, API contracts.
ONLY flag: no design-doc before implementation starts.

### Phase 3 (Implement) — steps 20-39
NOW flag: no per-issue commits, no TDD, no agent separation, no traces, skipped gates.
This is where most violations happen.

### Phase 4-5 (Validate + Review) — steps 40-56
Flag: skipped /review, skipped /retro, no e2e tests.

## Reporting Format

Each check, output ONE compact status line:
  Phase [N] | Step [X/57] | Files [N] (+N new) | Commits [N] | Active: [last activity] | Status: [OK / ISSUE]

Example outputs:
  Phase 0 | Step 3/57 | Files 63 (+5 new) | Commits 1 | Active: AGENT system-architect | Status: OK
  Phase 3 | Step 22/57 | Files 89 (+2 new) | Commits 8 | Active: SKILL gate stage-2 | Status: OK
  Phase 3 | Step 22/57 | Files 89 (+0 new) | Commits 8 | Active: last activity 12min ago | Status: IDLE

Only expand details when:
  - Status changes from last check (new commits, new phase, new files)
  - A REAL violation for the CURRENT phase is detected
  - Builder has been idle 10+ minutes (no new activity log entries)
  - A new agent or skill started (show what it is)

When idle, say 'No change.' — do NOT repeat the full violation table.

## Quality Review (ACTIVE — spawn reviewer on new artifacts)

When the activity log shows a NEW artifact was created (WRITE to a key file), review it:

Key files to review (when they appear or change):
  - CLAUDE.md → rate: under 100 lines? MUST/NEVER rules? code snippets? tech stack table?
  - SPEC.md → rate: 20+ REQs? models with field types? API endpoints? traceability table?
  - docs/design-doc.md → rate: 10 sections? Pydantic schemas? test scenarios? decisions?
  - apps/*/models.py → rate: [REQ-xxx] comments? field types correct? relationships?
  - apps/*/api.py → rate: Django Ninja routes? Pydantic schemas? auth on protected?
  - apps/*/tests.py → rate: [REQ-xxx] in docstrings? minimum 5 tests per issue? TDD?
  - docker-compose.yml → rate: volume mount? dev command? healthcheck?
  - docs/DEPLOY.md → rate: copy-pasteable commands? env vars table? under 200 lines?

HOW TO REVIEW:

STEP 1: Signal builder to wait:
  ! touch $PROJ/docs/.observer-reviewing

STEP 2: Spawn reviewer:
  Use Agent tool with subagent_type='reviewer':
  prompt: 'Read {file} at {project_path}. Also read SPEC.md and CLAUDE.md for context.
           Read ~/.claude/observer/review-criteria.md for scoring criteria.
           Rate 1-5 on: completeness, correctness, forge compliance.
           Output: RATING: N/5 | ISSUES: [list] | VERDICT: PASS/NEEDS_FIX'

STEP 3: Log the rating:
  ! echo '{timestamp} | {file} | {rating}/5 | {verdict} | {issues}' >> $PROJ/docs/.observer-reviews.log

STEP 4: Remove signal:
  ! rm -f $PROJ/docs/.observer-reviewing

STEP 5: PHASE APPROVAL (CRITICAL — builder WAITS for this)
  After reviewing ALL artifacts for the current phase, run these commands:
  First check: ! bash ~/.claude/scripts/forge-observer-approve.sh check $PROJ
  If READY TO APPROVE: ! bash ~/.claude/scripts/forge-observer-approve.sh approve $PROJ
  If NOT READY: tell the user what needs fixing. Do NOT approve.
  The builder CANNOT proceed to the next phase without this approval.

REVIEW RULES:
  - Only review files that are NEW or CHANGED since last check
  - Don't review the same file twice unless it changed
  - Rate >= 4 = PASS, < 4 = NEEDS_FIX
  - ALWAYS touch .observer-reviewing BEFORE starting review
  - ALWAYS rm .observer-reviewing AFTER finishing review
  - ALWAYS write PHASE-N-APPROVED after ALL artifacts pass for that phase
  - If review takes over 5 min, that's OK — builder waits patiently
  - On each check cycle: first do the status check, THEN review any new artifacts

## When User Asks for Advice

Read the FULL forge flow at ~/.claude/commands/forge.md to understand what step comes next.
Read forge-state.json for current position.
Read docs/.observer-reviews.log for quality history.
Give the user the EXACT text to paste into the builder terminal.

Start your initial check now."
    return
  fi

  # No arguments — work with current directory
  if [ -z "$1" ]; then
    # Has forge? Just open
    if [ -f ".claude/settings.json" ] || [ -d ".forge" ]; then
      claude --dangerously-skip-permissions
      return
    fi
    # Has code or CLAUDE.md but no forge? Initialize then open
    if [ -f "CLAUDE.md" ] || [ -f "manage.py" ] || [ -f "package.json" ] || [ -f "Cargo.toml" ] || [ -f "go.mod" ]; then
      echo "Project detected. Initializing Forge..."
      bash "$FORGE_DIR/install.sh" "$(pwd)"
      claude --dangerously-skip-permissions
      return
    fi
    # Empty or unknown folder — safety check: don't init in ~/projects/ root
    if [ "$(pwd)" = "$HOME/projects" ] || [ "$(pwd)" = "$HOME" ]; then
      echo "Error: Don't run forge in ~/projects/ root or home. Use: forge <project-name>"
      return 1
    fi
    echo "Initializing Forge in $(pwd)..."
    bash "$FORGE_DIR/install.sh" "$(pwd)"
    claude --dangerously-skip-permissions
    return
  fi

  local TARGET="$1"

  # "forge ." — initialize in current directory
  if [ "$TARGET" = "." ]; then
    bash "$FORGE_DIR/install.sh" "$(pwd)"
    claude --dangerously-skip-permissions
    return
  fi

  # Absolute path given
  if [[ "$TARGET" = /* ]]; then
    mkdir -p "$TARGET"
    bash "$FORGE_DIR/install.sh" "$TARGET"
    cd "$TARGET"
    claude --dangerously-skip-permissions
    return
  fi

  # Relative name — create in ~/projects/
  local PROJECT_DIR="$HOME/projects/$TARGET"

  if [ -d "$PROJECT_DIR" ]; then
    # Existing project
    if [ -f "$PROJECT_DIR/.claude/settings.json" ] || [ -d "$PROJECT_DIR/.forge" ]; then
      echo "Forge already initialized in $PROJECT_DIR. Opening..."
      cd "$PROJECT_DIR"
      claude --dangerously-skip-permissions
    else
      echo "Existing project without forge. Initializing..."
      bash "$FORGE_DIR/install.sh" "$PROJECT_DIR"
      cd "$PROJECT_DIR"
      claude --dangerously-skip-permissions
    fi
  else
    # Brand new project
    mkdir -p "$PROJECT_DIR"
    bash "$FORGE_DIR/install.sh" "$PROJECT_DIR"
    cd "$PROJECT_DIR"
    claude --dangerously-skip-permissions
  fi
}
