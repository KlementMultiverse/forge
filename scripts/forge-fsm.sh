#!/bin/bash
# Forge Finite State Machine — Deterministic flow enforcement
# This is the SINGLE SOURCE OF TRUTH for what the forge should do next.
# Hooks call this. The LLM reads the output. No ambiguity.
#
# Usage:
#   forge-fsm.sh next          — what must happen next (deterministic)
#   forge-fsm.sh can-gate      — can /gate run? (checks review marker)
#   forge-fsm.sh can-pr        — can PR/push happen? (checks review + gate)
#   forge-fsm.sh can-write <f> — can this file be written? (agent separation)
#   forge-fsm.sh on-review     — mark review done (called by PostToolUse)
#   forge-fsm.sh on-gate <N>   — mark gate done (called after gate passes)
#   forge-fsm.sh on-commit     — update state (called by PostToolUse)
#   forge-fsm.sh status        — full status dump

set -euo pipefail

# Source shared phase mapping and dependency checker
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/forge-phase-map.sh"
source "$SCRIPT_DIR/forge-deps.sh" && check_forge_deps

# Auto-detect project root
find_root() {
    local d="${1:-$PWD}"
    while [ "$d" != "/" ]; do
        [ -f "$d/CLAUDE.md" ] || [ -d "$d/.git" ] && echo "$d" && return
        d=$(dirname "$d")
    done
    echo "$PWD"
}

D="${PROJECT_ROOT:-$(find_root)}"
STATE="$D/docs/forge-state.json"
REVIEW_DIR="$D/docs/.forge-reviews"
mkdir -p "$REVIEW_DIR" 2>/dev/null || true

# Helper: read state value
state_val() {
    python3 -c "import json; s=json.load(open('$STATE')); print($1)" 2>/dev/null
}

has_state() { [ -f "$STATE" ]; }

# ═══════════════════════════════════════════════
# DETERMINISTIC NEXT ACTION
# Uses ARTIFACT VERIFICATION, not state markers.
# ═══════════════════════════════════════════════
cmd_next() {
    if ! has_state; then
        echo "ACTION: init"
        echo "COMMAND: bash scripts/forge-enforce.sh init $(basename $D)"
        echo "REASON: No forge-state.json found"
        return
    fi

    # PRIORITY 0: Check artifact gaps FIRST (proof of execution)
    local verify_script="$D/scripts/forge-verify.sh"
    [ ! -f "$verify_script" ] && verify_script="$HOME/.claude/scripts/forge-verify.sh"
    if [ -f "$verify_script" ]; then
        local gap_output
        gap_output=$(bash "$verify_script" next-gap 2>/dev/null)
        local gap_action
        gap_action=$(echo "$gap_output" | grep "^ACTION:" | cut -d' ' -f2-)
        if [ "$gap_action" != "all-verified" ] && [ -n "$gap_action" ]; then
            # There's an artifact gap — this takes priority over state
            echo "$gap_output"
            echo "SOURCE: artifact-verification (proof-of-execution check)"
            return
        fi
    fi

    python3 << 'PYEOF'
import json, os, glob

D = os.environ.get("D", os.getcwd())
STATE = os.path.join(D, "docs/forge-state.json")
REVIEW_DIR = os.path.join(D, "docs/.forge-reviews")

with open(STATE) as f:
    s = json.load(f)

violations = s.get("violations", [])
phases = s.get("phases", {})
status = s.get("status", "")

# Priority 1: Violations exist → fix them
if violations:
    # Categorize
    gate_v = [v for v in violations if v["type"] == "GATE_SKIPPED"]
    review_v = [v for v in violations if v["type"] == "REVIEW_SKIPPED"]
    p5_v = [v for v in violations if v["type"] == "PHASE5_BATCH_SKIPPED"]

    if review_v:
        # Check if review marker exists now
        phase = str(s.get("current_phase", "?"))
        marker = os.path.join(REVIEW_DIR, f"phase-{phase}-reviewed.json")
        if not os.path.exists(marker):
            print("ACTION: run-review")
            print("COMMAND: /review")
            print("REASON: REVIEW_SKIPPED violation — /review must run before gate/PR")
            print("BLOCKING: /gate and gh pr create are BLOCKED until /review completes")
            exit(0)

    if gate_v:
        # Find first ungated phase
        for p_num in sorted(phases.keys(), key=int):
            p = phases[p_num]
            if p.get("status", "").startswith("DONE") and not p.get("gate_passed", False):
                # But check review first
                marker = os.path.join(REVIEW_DIR, f"phase-{p_num}-reviewed.json")
                if not os.path.exists(marker):
                    print(f"ACTION: run-review-for-gate")
                    print(f"COMMAND: /review then /gate phase-{p_num}")
                    print(f"REASON: Phase {p_num} needs gate but /review must run first")
                    exit(0)
                print(f"ACTION: run-gate")
                print(f"COMMAND: /gate phase-{p_num}")
                print(f"REASON: Phase {p_num} ({p.get('name', '?')}) completed but gate not passed")
                exit(0)

    if p5_v:
        # Find first unskipped Phase 5 step
        p5_steps = {
            47: "/sc:cleanup", 48: "/sc:improve", 49: "/retro",
            50: "/sc:reflect", 51: "/sc:document", 52: "@playbook-curator",
            53: "/prune + /evolve", 54: "/autoresearch", 55: "/sc:save"
        }
        p5 = phases.get("5", {}).get("steps", {})
        for step_num in sorted(p5_steps.keys()):
            step = p5.get(str(step_num), {})
            # If step was batch-marked, treat as needing re-run
            if step.get("status") == "DONE" and "PHASE5_BATCH_SKIPPED" in [v["type"] for v in violations]:
                print(f"ACTION: rerun-phase5-step")
                print(f"COMMAND: {p5_steps[step_num]}")
                print(f"STEP: {step_num}")
                print(f"REASON: Step {step_num} was batch-marked DONE without executing")
                exit(0)

    # If only historical violations remain (can't fix)
    fixable = [v for v in violations if v["type"] not in ("AGENT_SEPARATION", "TDD_SKIPPED", "TRACE_INCOMPLETE", "CHECKPOINT_SKIPPED")]
    if not fixable:
        print("ACTION: acknowledge-historical")
        print("COMMAND: No fixable violations remain. Historical violations logged.")
        print("REASON: Remaining violations are from initial build and cannot be retroactively fixed")
        exit(0)

# Priority 2: Check for open PR with CodeRabbit reviews
try:
    import subprocess
    pr = subprocess.run(["gh", "pr", "list", "--state", "open", "--json", "number", "-q", ".[0].number"],
                       capture_output=True, text=True, cwd=D)
    pr_num = pr.stdout.strip()
    if pr_num:
        # Auto-detect repo from git remote instead of hardcoding
        repo_result = subprocess.run(
            ["gh", "repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner"],
            capture_output=True, text=True, cwd=D)
        repo_name = repo_result.stdout.strip()
        if not repo_name:
            # Fallback: parse from git remote
            remote = subprocess.run(["git", "remote", "get-url", "origin"],
                                    capture_output=True, text=True, cwd=D)
            url = remote.stdout.strip()
            # Handle both HTTPS and SSH URLs
            import re as _re
            m = _re.search(r'[:/]([^/]+/[^/]+?)(?:\.git)?$', url)
            repo_name = m.group(1) if m else ""
        if not repo_name:
            pass  # Skip CodeRabbit check if we can't detect repo
        else:
            reviews = subprocess.run(
                ["gh", "api", f"repos/{repo_name}/pulls/{pr_num}/comments",
                 "--jq", '[.[] | select(.user.login | contains("coderabbit"))] | length'],
                capture_output=True, text=True)
            comment_count = int(reviews.stdout.strip() or "0")
            if comment_count > 0:
                print(f"ACTION: fix-coderabbit-comments")
                print(f"COMMAND: Read PR #{pr_num} CodeRabbit comments → fix → push → wait")
                print(f"REASON: PR #{pr_num} has {comment_count} CodeRabbit comment(s) to address")
                exit(0)
except Exception:
    pass

# Priority 3: Incomplete steps
cp = s.get("current_phase", 0)
cs = s.get("current_step", 0)
if cs < 57:
    from collections import OrderedDict
    ALL_STEPS = {
        0: {1: "/discover", 2: "/requirements", 3: "/feasibility", 4: "/generate-spec",
            5: "/challenge", 6: "/bootstrap", 7: "/checkpoint", 8: "/gate phase-0"},
        1: {9: "/specify", 10: "/checkpoint", 11: "/gate stage-1"},
        2: {12: "/plan-review", 13: "@api-architect", 14: "/design-doc", 15: "/plan-tasks",
            16: "/sc:estimate", 17: "/sc:workflow", 18: "/checkpoint", 19: "/gate stage-2"},
        3: {20: "implementation-start", 39: "/gate stage-3"},
        4: {40: "/sc:analyze", 41: "/audit-patterns", 42: "/sc:test --coverage",
            43: "traceability", 44: "/security-scan", 45: "e2e+visual", 46: "/gate stage-4"},
        5: {47: "/sc:cleanup", 48: "/sc:improve", 49: "/retro", 50: "/sc:reflect",
            51: "/sc:document", 52: "@playbook-curator", 53: "/prune+/evolve",
            54: "/autoresearch", 55: "/sc:save", 56: "/gate stage-5"},
        6: {57: "check-queue"}
    }
    for phase_num in sorted(ALL_STEPS.keys()):
        if phase_num < cp:
            continue
        for step_num in sorted(ALL_STEPS[phase_num].keys()):
            if phase_num == cp and step_num <= cs:
                continue
            step_data = phases.get(str(phase_num), {}).get("steps", {}).get(str(step_num), {})
            if step_data.get("status") != "DONE":
                print(f"ACTION: execute-step")
                print(f"COMMAND: {ALL_STEPS[phase_num][step_num]}")
                print(f"PHASE: {phase_num}")
                print(f"STEP: {step_num}")
                print(f"REASON: Next incomplete step in flow")
                exit(0)

# Priority 4: Check FORGE.md for queued items
forge_md = os.path.join(D, "FORGE.md")
if os.path.exists(forge_md):
    content = open(forge_md).read()
    if "QUEUED" in content:
        print("ACTION: process-queue")
        print("COMMAND: Read FORGE.md, pick first QUEUED item, route to correct case")
        print("REASON: Queued work items exist")
        exit(0)

# Priority 5: Everything done
print("ACTION: done")
print("COMMAND: All phases complete, no violations, no queued items")
print("REASON: Project is fully built and verified")
PYEOF
}

# ═══════════════════════════════════════════════
# GUARD FUNCTIONS (called by hooks, exit 2 = block)
# ═══════════════════════════════════════════════
cmd_can_gate() {
    if ! has_state; then return 0; fi
    local phase
    phase=$(state_val "s.get('current_phase', '?')")
    local marker="$REVIEW_DIR/phase-${phase}-reviewed.json"
    if [ -f "$marker" ]; then
        return 0
    else
        echo "[FORGE-BLOCKED] /gate requires /review first. Run /review now." >&2
        exit 2
    fi
}

cmd_can_pr() {
    if ! has_state; then return 0; fi
    local phase
    phase=$(state_val "s.get('current_phase', '?')")
    local marker="$REVIEW_DIR/phase-${phase}-reviewed.json"
    if [ -f "$marker" ]; then
        return 0
    else
        echo "[FORGE-BLOCKED] PR/push requires /review first. Run /review now." >&2
        exit 2
    fi
}

cmd_can_write() {
    local f="${1:-}"
    if echo "$f" | grep -qE "/apps/[^/]+/(models|api|schemas|services|views|urls|middleware)\.py$"; then
        if has_state; then
            local status
            status=$(state_val "s.get('status', '')")
            if [ "$status" = "IN_PROGRESS" ]; then
                echo "[FORGE-ENFORCE] App code write: $f — use specialist agent, not PM." >&2
            fi
        fi
    fi
    return 0
}

# ═══════════════════════════════════════════════
# EVENT HANDLERS (called by hooks)
# ═══════════════════════════════════════════════
cmd_on_review() {
    if ! has_state; then return 0; fi
    local phase
    phase=$(state_val "s.get('current_phase', '?')")
    mkdir -p "$REVIEW_DIR"
    echo "{\"phase\": \"$phase\", \"reviewed_at\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\", \"status\": \"REVIEWED\"}" > "$REVIEW_DIR/phase-${phase}-reviewed.json"
    echo "[FORGE-REVIEW] Phase $phase marked REVIEWED — /gate and PR now unlocked"
}

cmd_on_gate() {
    local phase="${1:-}"
    if has_state && [ -n "$phase" ]; then
        python3 -c "
import json, datetime
with open('$STATE') as f:
    s = json.load(f)
if '$phase' in s.get('phases', {}):
    s['phases']['$phase']['gate_passed'] = True
    s['phases']['$phase']['status'] = 'DONE'
s['last_updated'] = datetime.datetime.now(datetime.UTC).isoformat()
with open('$STATE', 'w') as f:
    json.dump(s, f, indent=2)
" 2>/dev/null
        echo "[FORGE-GATE] Phase $phase gate PASSED"
    fi
}

cmd_on_commit() {
    if has_state; then
        python3 -c "
import json, datetime
with open('$STATE') as f:
    s = json.load(f)
s['last_updated'] = datetime.datetime.now(datetime.UTC).isoformat()
with open('$STATE', 'w') as f:
    json.dump(s, f, indent=2)
" 2>/dev/null
    fi
}

cmd_status() {
    echo "=== Forge FSM Status ==="
    has_state || { echo "No state file"; return; }

    echo ""
    echo "--- State ---"
    state_val "f'Phase: {s[\"current_phase\"]} Step: {s[\"current_step\"]} Status: {s[\"status\"]}'"
    state_val "f'Gates: {sum(1 for p in s[\"phases\"].values() if p.get(\"gate_passed\"))}/{len(s[\"phases\"])}'"
    state_val "f'Violations: {len(s.get(\"violations\", []))}'"

    echo ""
    echo "--- Review Guard ---"
    for f in "$REVIEW_DIR"/phase-*-reviewed.json; do
        [ -f "$f" ] || { echo "  No reviews"; break; }
        echo "  $(basename $f .json): REVIEWED"
    done

    echo ""
    echo "--- Next Action ---"
    cmd_next
}

case "${1:-help}" in
    next)       cmd_next ;;
    can-gate)   cmd_can_gate ;;
    can-pr)     cmd_can_pr ;;
    can-write)  shift; cmd_can_write "$@" ;;
    on-review)  cmd_on_review ;;
    on-gate)    shift; cmd_on_gate "$@" ;;
    on-commit)  cmd_on_commit ;;
    status)     cmd_status ;;
    *)
        echo "Forge FSM — Deterministic flow control"
        echo "  next         What must happen next"
        echo "  can-gate     Block /gate without /review"
        echo "  can-pr       Block PR without /review"
        echo "  can-write <f> Check agent separation"
        echo "  on-review    Mark review done"
        echo "  on-gate <N>  Mark gate passed"
        echo "  on-commit    Update timestamp"
        echo "  status       Full status"
        ;;
esac
