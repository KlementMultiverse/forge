#!/bin/bash
# Forge Enforcement Script — Global, project-agnostic
# Works with ANY forge-managed project by auto-detecting project root
#
# Usage:
#   forge-enforce.sh check-gate <phase>        — verify gate passed for phase
#   forge-enforce.sh check-trace <step>         — verify trace has 3 files
#   forge-enforce.sh check-agent <file_path>    — block PM from writing to app code
#   forge-enforce.sh check-docker               — verify containers healthy
#   forge-enforce.sh check-state                — show current forge state
#   forge-enforce.sh check-continuation         — report next step to execute (ALL phases)
#   forge-enforce.sh update-step <step> <status> — update step in forge-state.json
#   forge-enforce.sh update-gate <phase>         — mark gate as passed
#   forge-enforce.sh full-audit                  — run all checks, report violations
#   forge-enforce.sh init [project_name]         — initialize forge-state.json for new project

set -euo pipefail

# Source shared phase mapping and dependency checker
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/forge-phase-map.sh"
source "$SCRIPT_DIR/forge-deps.sh" && check_forge_deps

# Auto-detect project root: walk up until we find CLAUDE.md or .git
find_project_root() {
    local dir="${1:-$PWD}"
    while [ "$dir" != "/" ]; do
        if [ -f "$dir/CLAUDE.md" ] || [ -d "$dir/.git" ]; then
            echo "$dir"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    echo "$PWD"
}

PROJECT_ROOT="${PROJECT_ROOT:-$(find_project_root)}"
STATE_FILE="$PROJECT_ROOT/docs/forge-state.json"
TRACE_DIR="$PROJECT_ROOT/docs/forge-trace"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
log_fail() { echo -e "${RED}[FAIL]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
log_block() { echo -e "${RED}[BLOCKED]${NC} $1"; exit 2; }

ensure_state_file() {
    if [ ! -f "$STATE_FILE" ]; then
        log_fail "forge-state.json not found at $STATE_FILE"
        echo "Run: forge-enforce.sh init <project_name> to create it"
        exit 1
    fi
}

# ═══════════════════════════════════════════════
# FULL PHASE/STEP MAP — ALL 57+ STEPS
# ═══════════════════════════════════════════════

read_step_map() {
    python3 << 'PYEOF'
import json, sys

# Complete forge phase/step map — ALL phases, ALL steps
# NOTE: Canonical bash mapping is in forge-phase-map.sh. Keep in sync.
PHASES = {
    0: {
        "name": "Genesis",
        "steps": {
            1:  {"name": "discover",         "command": "/discover"},
            2:  {"name": "requirements",     "command": "/requirements"},
            3:  {"name": "feasibility",      "command": "/feasibility"},
            4:  {"name": "generate-spec",    "command": "/generate-spec"},
            5:  {"name": "challenge",        "command": "/challenge"},
            6:  {"name": "bootstrap",        "command": "/bootstrap"},
            7:  {"name": "checkpoint-p0",    "command": "/checkpoint phase-0"},
            8:  {"name": "gate-p0",          "command": "/gate phase-0"},
        }
    },
    1: {
        "name": "Specify",
        "steps": {
            9:  {"name": "specify",          "command": "/specify"},
            10: {"name": "checkpoint-s1",    "command": "/checkpoint specify"},
            11: {"name": "gate-s1",          "command": "/gate stage-1"},
        }
    },
    2: {
        "name": "Architect",
        "steps": {
            12: {"name": "plan-review",      "command": "/plan-review"},
            13: {"name": "api-architect",    "command": "@api-architect"},
            14: {"name": "design-doc",       "command": "/design-doc"},
            15: {"name": "plan-tasks",       "command": "/plan-tasks"},
            16: {"name": "sc-estimate",      "command": "/sc:estimate"},
            17: {"name": "sc-workflow",      "command": "/sc:workflow"},
            18: {"name": "checkpoint-s2",    "command": "/checkpoint architect"},
            19: {"name": "gate-s2",          "command": "/gate stage-2"},
        }
    },
    3: {
        "name": "Implement",
        "note": "Per-issue loop: steps N0-N9 per issue (100-109, 110-119, ...)",
        "steps": {
            20: {"name": "phase-3-start",    "command": "Begin per-issue implementation loop"},
            39: {"name": "phase-3-gate",     "command": "/gate stage-3"},
        }
    },
    4: {
        "name": "Validate",
        "steps": {
            40: {"name": "sc-analyze",       "command": "/sc:analyze"},
            41: {"name": "audit-patterns",   "command": "/audit-patterns full"},
            42: {"name": "sc-test-coverage", "command": "/sc:test --coverage"},
            43: {"name": "traceability",     "command": "bash scripts/traceability.sh"},
            44: {"name": "security-scan",    "command": "/security-scan"},
            45: {"name": "design-audit+e2e", "command": "/design-audit + /critic + /sc:test --type e2e + manage.py test"},
            46: {"name": "gate-s4",          "command": "/gate stage-4"},
        }
    },
    5: {
        "name": "Review+Learn",
        "steps": {
            47: {"name": "sc-cleanup",       "command": "/sc:cleanup"},
            48: {"name": "sc-improve",       "command": "/sc:improve"},
            49: {"name": "retro",            "command": "/retro"},
            50: {"name": "sc-reflect",       "command": "/sc:reflect"},
            51: {"name": "sc-document",      "command": "/sc:document"},
            52: {"name": "playbook-curator", "command": "@playbook-curator"},
            53: {"name": "prune+evolve",     "command": "/prune + /evolve"},
            54: {"name": "autoresearch",     "command": "/autoresearch"},
            55: {"name": "sc-save",          "command": "/sc:save"},
            56: {"name": "gate-s5-merge",    "command": "/gate stage-5 + MERGE"},
        }
    },
    6: {
        "name": "Iterate",
        "steps": {
            57: {"name": "check-queue",      "command": "Read FORGE.md for QUEUED items → loop or done"},
        }
    }
}

# Output as JSON for other commands to consume
json.dump(PHASES, sys.stdout, indent=2)
PYEOF
}

cmd_check_gate() {
    local phase="${1:?Usage: check-gate <phase_number>}"
    ensure_state_file

    local gate_passed
    gate_passed=$(python3 -c "
import json
with open('$STATE_FILE') as f:
    state = json.load(f)
phase = state.get('phases', {}).get('$phase', {})
print('true' if phase.get('gate_passed', False) else 'false')
")

    if [ "$gate_passed" = "true" ]; then
        log_pass "Phase $phase gate: PASSED"
        return 0
    else
        log_block "Phase $phase gate NOT passed. Cannot proceed to next phase. Run /gate phase-$phase first."
        return 2
    fi
}

cmd_check_trace() {
    local step="${1:?Usage: check-trace <step_number>}"
    local padded
    padded=$(printf "%03d" "$step" 2>/dev/null || echo "$step")
    local trace_path
    trace_path=$(find "$TRACE_DIR" -maxdepth 1 -type d \( -name "${padded}-*" -o -name "${step}-*" \) 2>/dev/null | head -1)

    if [ -z "$trace_path" ]; then
        log_fail "Step $step: No trace directory found"
        return 1
    fi

    local missing=0
    for f in input.md output.md meta.md; do
        if [ ! -f "$trace_path/$f" ]; then
            log_fail "Step $step: Missing $f in $(basename "$trace_path")/"
            missing=$((missing + 1))
        fi
    done

    if [ "$missing" -eq 0 ]; then
        log_pass "Step $step: Trace complete (3/3 files)"
        return 0
    else
        log_fail "Step $step: Trace incomplete ($((3 - missing))/3 files)"
        return 1
    fi
}

cmd_check_agent() {
    local file_path="${1:?Usage: check-agent <file_path>}"

    # Check if file is app code (any framework pattern)
    if echo "$file_path" | grep -qE "^(.*/)?apps/[^/]+/(models|api|schemas|services|views|urls|middleware|serializers|forms|admin)\\.py$"; then
        log_block "AGENT SEPARATION VIOLATION: Writing to $file_path requires a specialist agent (not PM). See .claude/rules/agent-routing.md."
        return 2
    fi

    # Also check src/ pattern for non-Django projects
    if echo "$file_path" | grep -qE "^(.*/)?src/[^/]+/(models|routes|controllers|services|handlers)\\."; then
        log_warn "Writing to $file_path — verify a specialist agent is handling this, not PM."
        return 0
    fi

    return 0
}

cmd_check_docker() {
    # Check if docker-compose.yml exists in project
    if [ ! -f "$PROJECT_ROOT/docker-compose.yml" ] && [ ! -f "$PROJECT_ROOT/docker-compose.yaml" ] && [ ! -f "$PROJECT_ROOT/compose.yml" ]; then
        log_info "No docker-compose file found — skipping Docker check"
        return 0
    fi

    local unhealthy=0

    # Get expected services from compose file
    local compose_file
    for f in docker-compose.yml docker-compose.yaml compose.yml; do
        if [ -f "$PROJECT_ROOT/$f" ]; then
            compose_file="$f"
            break
        fi
    done

    local services
    services=$(cd "$PROJECT_ROOT" && docker compose ps --format '{{.Name}} {{.Health}}' 2>/dev/null || echo "")

    if [ -z "$services" ]; then
        log_fail "Docker: No containers running"
        return 1
    fi

    while IFS= read -r line; do
        local name status
        name=$(echo "$line" | awk '{print $1}')
        status=$(echo "$line" | awk '{print $2}')
        if [ "$status" = "healthy" ] || [ -z "$status" ]; then
            log_pass "Docker $name: ${status:-running}"
        else
            log_warn "Docker $name: $status"
            unhealthy=$((unhealthy + 1))
        fi
    done <<< "$services"

    # Update state file if it exists
    if [ -f "$STATE_FILE" ]; then
        python3 -c "
import json, subprocess, datetime
with open('$STATE_FILE') as f:
    state = json.load(f)
ps = subprocess.run(['docker', 'compose', 'ps', '--format', 'json'], capture_output=True, text=True, cwd='$PROJECT_ROOT')
containers = []
for line in ps.stdout.strip().split('\n'):
    if line.strip():
        try:
            containers.append(json.loads(line))
        except json.JSONDecodeError:
            pass
state['docker'] = {
    'last_checked': datetime.datetime.now(datetime.UTC).isoformat(),
    'containers': [{'name': c.get('Name',''), 'status': c.get('Health', c.get('State',''))} for c in containers],
    'healthy': $( [ "$unhealthy" -eq 0 ] && echo "True" || echo "False" )
}
with open('$STATE_FILE', 'w') as f:
    json.dump(state, f, indent=2)
" 2>/dev/null || true
    fi

    if [ "$unhealthy" -gt 0 ]; then
        log_fail "Docker: $unhealthy unhealthy service(s)"
        return 1
    fi
    log_pass "Docker: All services healthy"
    return 0
}

cmd_check_state() {
    ensure_state_file

    python3 -c "
import json, sys
with open('$STATE_FILE') as f:
    state = json.load(f)

required_keys = ['version', 'project', 'current_phase', 'current_step', 'status', 'phases']
missing = [k for k in required_keys if k not in state]
if missing:
    print(f'FAIL: forge-state.json missing keys: {missing}')
    sys.exit(1)

print(f'Project:    {state[\"project\"]}')
print(f'Phase:      {state[\"current_phase\"]} ({state[\"phases\"].get(str(state[\"current_phase\"]), {}).get(\"name\", \"unknown\")})')
print(f'Step:       {state[\"current_step\"]}')
print(f'Status:     {state[\"status\"]}')

# Count gate status
gates_passed = sum(1 for p in state['phases'].values() if p.get('gate_passed'))
gates_total = len(state['phases'])
print(f'Gates:      {gates_passed}/{gates_total} passed')

violations = state.get('violations', [])
print(f'Violations: {len(violations)}')
for v in violations[-5:]:
    print(f'  - {v[\"type\"]}: {v.get(\"detail\", v.get(\"phase\", \"\"))}')
"
    return 0
}

cmd_check_continuation() {
    ensure_state_file

    python3 << 'PYEOF'
import json, sys

PHASES = {
    0: {"name": "Genesis", "steps": {
        1: "/discover", 2: "/requirements", 3: "/feasibility",
        4: "/generate-spec", 5: "/challenge", 6: "/bootstrap",
        7: "/checkpoint phase-0", 8: "/gate phase-0"
    }},
    1: {"name": "Specify", "steps": {
        9: "/specify", 10: "/checkpoint specify", 11: "/gate stage-1"
    }},
    2: {"name": "Architect", "steps": {
        12: "/plan-review", 13: "@api-architect", 14: "/design-doc",
        15: "/plan-tasks", 16: "/sc:estimate", 17: "/sc:workflow",
        18: "/checkpoint architect", 19: "/gate stage-2"
    }},
    3: {"name": "Implement", "steps": {
        20: "Per-issue implementation (N0-N9 loop)",
        39: "/gate stage-3"
    }},
    4: {"name": "Validate", "steps": {
        40: "/sc:analyze", 41: "/audit-patterns full",
        42: "/sc:test --coverage", 43: "traceability.sh",
        44: "/security-scan", 45: "/design-audit + /critic + e2e tests + unit tests",
        46: "/gate stage-4"
    }},
    5: {"name": "Review+Learn", "steps": {
        47: "/sc:cleanup", 48: "/sc:improve", 49: "/retro",
        50: "/sc:reflect", 51: "/sc:document", 52: "@playbook-curator",
        53: "/prune + /evolve", 54: "/autoresearch", 55: "/sc:save",
        56: "/gate stage-5 + MERGE"
    }},
    6: {"name": "Iterate", "steps": {
        57: "Check FORGE.md queue → loop or done"
    }}
}

STATE_FILE = sys.argv[1] if len(sys.argv) > 1 else "docs/forge-state.json"
with open(STATE_FILE) as f:
    state = json.load(f)

cp = state["current_phase"]
cs = state["current_step"]

print(f"Current:  Phase {cp} ({PHASES.get(cp, {}).get('name', '?')}), Step {cs}")
print()

# Check for skipped gates
ungated = []
for p_num in range(cp + 1):
    p_str = str(p_num)
    if p_str in state.get("phases", {}):
        p_data = state["phases"][p_str]
        if p_data.get("status", "").startswith("DONE") and not p_data.get("gate_passed", False):
            ungated.append(p_num)

if ungated:
    print(f"WARNING:  Phases {ungated} completed but gates NOT passed!")
    print(f"ACTION:   Run gates for skipped phases first:")
    for p in ungated:
        gate_step = max(PHASES[p]["steps"].keys())
        print(f"          Step {gate_step}: {PHASES[p]['steps'][gate_step]}")
    print()

# Find next step across ALL phases
found_next = False
for phase_num in sorted(PHASES.keys()):
    if phase_num < cp:
        continue
    steps = PHASES[phase_num]["steps"]
    for step_num in sorted(steps.keys()):
        if phase_num == cp and step_num <= cs:
            continue
        # Check if step was already done
        p_data = state.get("phases", {}).get(str(phase_num), {})
        s_data = p_data.get("steps", {}).get(str(step_num), {})
        if s_data.get("status") == "DONE":
            continue

        print(f"NEXT:     Phase {phase_num} ({PHASES[phase_num]['name']}), Step {step_num}")
        print(f"COMMAND:  {steps[step_num]}")
        found_next = True
        break
    if found_next:
        break

if not found_next:
    print("NEXT:     All phases complete! Check FORGE.md for queued items.")

# Summary
print()
total_steps = sum(len(p["steps"]) for p in PHASES.values())
done_steps = sum(
    1 for p in state.get("phases", {}).values()
    for s in p.get("steps", {}).values()
    if s.get("status") == "DONE"
)
print(f"Progress: {done_steps}/{total_steps} steps done ({done_steps*100//max(total_steps,1)}%)")
PYEOF
    return 0
}

cmd_update_step() {
    local step="${1:?Usage: update-step <step_number> <status>}"
    local new_status="${2:?Usage: update-step <step_number> <status>}"
    ensure_state_file

    python3 -c "
import json, datetime

with open('$STATE_FILE') as f:
    state = json.load(f)

step = $step
status = '$new_status'

# Find which phase this step belongs to
for phase_num, phase_data in state['phases'].items():
    steps = phase_data.get('steps', {})
    if str(step) in steps:
        steps[str(step)]['status'] = status
        break
else:
    cp = str(state['current_phase'])
    if cp not in state['phases']:
        state['phases'][cp] = {'name': 'Unknown', 'status': 'IN_PROGRESS', 'gate_passed': False, 'steps': {}}
    state['phases'][cp]['steps'][str(step)] = {'name': 'step-$step', 'status': status, 'trace_complete': False}

state['current_step'] = step
state['last_updated'] = datetime.datetime.now(datetime.UTC).isoformat()
state['status'] = 'IN_PROGRESS' if status in ('DONE', 'IN_PROGRESS') else status

with open('$STATE_FILE', 'w') as f:
    json.dump(state, f, indent=2)

print(f'Updated step {step} to {status}')
"
    return 0
}

cmd_update_gate() {
    local phase="${1:?Usage: update-gate <phase_number>}"
    ensure_state_file

    python3 -c "
import json, datetime

with open('$STATE_FILE') as f:
    state = json.load(f)

phase = '$phase'
if phase in state.get('phases', {}):
    state['phases'][phase]['gate_passed'] = True
    state['phases'][phase]['status'] = 'DONE'
    state['last_updated'] = datetime.datetime.now(datetime.UTC).isoformat()
    with open('$STATE_FILE', 'w') as f:
        json.dump(state, f, indent=2)
    print(f'Phase {phase} gate marked as PASSED')
else:
    print(f'Phase {phase} not found in state file')
    exit(1)
"
    return 0
}

cmd_init() {
    local project_name="${1:-$(basename "$PROJECT_ROOT")}"

    mkdir -p "$(dirname "$STATE_FILE")"

    python3 -c "
import json, datetime

state = {
    'version': '1.0.0',
    'project': '$project_name',
    'current_phase': 0,
    'current_step': 0,
    'status': 'NOT_STARTED',
    'last_updated': datetime.datetime.now(datetime.UTC).isoformat(),
    'phases': {
        '0': {'name': 'Genesis',       'status': 'NOT_STARTED', 'gate_passed': False, 'steps': {}},
        '1': {'name': 'Specify',       'status': 'NOT_STARTED', 'gate_passed': False, 'steps': {}},
        '2': {'name': 'Architect',     'status': 'NOT_STARTED', 'gate_passed': False, 'steps': {}},
        '3': {'name': 'Implement',     'status': 'NOT_STARTED', 'gate_passed': False, 'steps': {}},
        '4': {'name': 'Validate',      'status': 'NOT_STARTED', 'gate_passed': False, 'steps': {}},
        '5': {'name': 'Review+Learn',  'status': 'NOT_STARTED', 'gate_passed': False, 'steps': {}},
        '6': {'name': 'Iterate',       'status': 'NOT_STARTED', 'gate_passed': False, 'steps': {}}
    },
    'violations': [],
    'docker': {
        'last_checked': None,
        'containers': [],
        'healthy': False
    }
}

with open('$STATE_FILE', 'w') as f:
    json.dump(state, f, indent=2)

print(f'Initialized forge-state.json for project: $project_name')
print(f'Location: $STATE_FILE')
print(f'Phases: 0-6 (Genesis → Specify → Architect → Implement → Validate → Review+Learn → Iterate)')
"
    return 0
}

cmd_full_audit() {
    echo "========================================="
    echo "  FORGE ENFORCEMENT — FULL AUDIT"
    echo "  Project: $(basename "$PROJECT_ROOT")"
    echo "========================================="
    echo ""

    local failures=0

    echo "--- 1. State File ---"
    if cmd_check_state 2>/dev/null; then
        log_pass "forge-state.json valid"
    else
        log_fail "forge-state.json invalid or missing"
        failures=$((failures + 1))
    fi
    echo ""

    echo "--- 2. Docker Health ---"
    if cmd_check_docker 2>/dev/null; then
        true
    else
        failures=$((failures + 1))
    fi
    echo ""

    echo "--- 3. Trace Completeness ---"
    if [ -d "$TRACE_DIR" ]; then
        local trace_failures=0
        for dir in "$TRACE_DIR"/*/; do
            [ -d "$dir" ] || continue
            step_num=$(basename "$dir" | grep -oP '^\d+' || echo "0")
            if [ "$step_num" != "0" ]; then
                if ! cmd_check_trace "$step_num" 2>/dev/null; then
                    trace_failures=$((trace_failures + 1))
                fi
            fi
        done
        if [ "$trace_failures" -gt 0 ]; then
            log_fail "$trace_failures trace directories incomplete"
            failures=$((failures + 1))
        else
            log_pass "All traces complete"
        fi
    else
        log_info "No trace directory found — skipping"
    fi
    echo ""

    echo "--- 4. Gate Status ---"
    ensure_state_file
    python3 -c "
import json
with open('$STATE_FILE') as f:
    state = json.load(f)
for p_num in sorted(state.get('phases', {}).keys(), key=int):
    p = state['phases'][p_num]
    status = p.get('status', 'NOT_STARTED')
    gated = p.get('gate_passed', False)
    name = p.get('name', '?')
    if status == 'NOT_STARTED':
        print(f'  Phase {p_num} ({name}): not started')
    elif gated:
        print(f'  Phase {p_num} ({name}): DONE + GATED')
    elif status.startswith('DONE'):
        print(f'  Phase {p_num} ({name}): DONE — GATE MISSING!')
    else:
        print(f'  Phase {p_num} ({name}): {status}')
" 2>/dev/null
    echo ""

    echo "--- 5. Traceability ---"
    if [ -f "$PROJECT_ROOT/scripts/traceability.sh" ]; then
        if bash "$PROJECT_ROOT/scripts/traceability.sh" "$PROJECT_ROOT" 2>/dev/null; then
            log_pass "Traceability: PASS"
        else
            log_fail "Traceability: FAIL"
            failures=$((failures + 1))
        fi
    else
        log_info "No traceability.sh found — skipping"
    fi
    echo ""

    echo "--- 6. Next Action ---"
    cmd_check_continuation 2>/dev/null || true
    echo ""

    echo "========================================="
    if [ "$failures" -gt 0 ]; then
        echo -e "${RED}  AUDIT FAILED: $failures issue(s) found${NC}"
        exit 1
    else
        echo -e "${GREEN}  AUDIT PASSED: All checks green${NC}"
        exit 0
    fi
}

# Dispatch
case "${1:-help}" in
    check-gate)         shift; cmd_check_gate "$@" ;;
    check-trace)        shift; cmd_check_trace "$@" ;;
    check-agent)        shift; cmd_check_agent "$@" ;;
    check-docker)       cmd_check_docker ;;
    check-state)        cmd_check_state ;;
    check-continuation) cmd_check_continuation ;;
    update-step)        shift; cmd_update_step "$@" ;;
    update-gate)        shift; cmd_update_gate "$@" ;;
    init)               shift; cmd_init "$@" ;;
    full-audit)         cmd_full_audit ;;
    *)
        echo "Forge Enforcement — NASA-grade build reliability"
        echo ""
        echo "Usage: forge-enforce.sh <command> [args]"
        echo ""
        echo "Commands:"
        echo "  init [project_name]       Initialize forge-state.json for new project"
        echo "  check-state               Show current forge state"
        echo "  check-continuation        Report ALL remaining steps across ALL phases"
        echo "  check-gate <phase>        Verify gate passed for phase (0-6)"
        echo "  check-trace <step>        Verify trace has 3 files (input/output/meta)"
        echo "  check-agent <file_path>   Block PM from writing to app code"
        echo "  check-docker              Verify Docker containers healthy"
        echo "  update-step <step> <stat> Update step status (DONE/SKIPPED/IN_PROGRESS)"
        echo "  update-gate <phase>       Mark phase gate as passed"
        echo "  full-audit                Run all checks, report violations"
        ;;
esac
