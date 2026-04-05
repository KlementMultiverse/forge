#!/bin/bash
# Forge Growth Engine — deterministic flow + non-deterministic growth
# Detects gaps, proposes new agents/steps/groups, goes through review
#
# Usage:
#   forge-grow.sh scan              — detect gaps in current project
#   forge-grow.sh propose <type>    — generate a growth proposal
#   forge-grow.sh create-agent <name> <domain> <desc> — create agent from template
#   forge-grow.sh add-step <phase> <name> <agent> <artifact> — add step to manifest
#   forge-grow.sh add-group <name>  — register new agent group
#   forge-grow.sh status            — show growth metrics
#   forge-grow.sh auto              — scan + propose + create (fully autonomous)

set -euo pipefail

find_root() {
    local d="${1:-$PWD}"
    while [ "$d" != "/" ]; do
        [ -f "$d/CLAUDE.md" ] || [ -d "$d/.git" ] && echo "$d" && return
        d=$(dirname "$d")
    done
    echo "$PWD"
}

D="${PROJECT_ROOT:-$(find_root)}"
MANIFEST="$D/docs/forge-manifest.json"
AGENTS_DIR="$HOME/.claude/agents"
GROWTH_LOG="$D/docs/forge-growth.log"

touch "$GROWTH_LOG" 2>/dev/null || true

log_growth() {
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) | $1" >> "$GROWTH_LOG"
}

# ═══════════════════════════════════════════════
# SCAN — detect what's missing
# ═══════════════════════════════════════════════
cmd_scan() {
    echo "=== Forge Growth Scan ==="
    echo ""

    local gaps=0

    # 1. Check for domains without specialized agents
    echo "--- Agent Coverage ---"
    if [ -f "$D/CLAUDE.md" ]; then
        python3 << 'PYEOF'
import os, glob, json

D = os.environ.get("D", os.getcwd())
AGENTS_DIR = os.environ.get("AGENTS_DIR", os.path.expanduser("~/.claude/agents"))

# Detect project domains from app directories
apps = []
for d in glob.glob(os.path.join(D, "apps", "*")):
    if os.path.isdir(d) and not d.endswith("__pycache__"):
        apps.append(os.path.basename(d))

# Check agent routing
routing_file = os.path.join(D, ".claude/rules/agent-routing.md")
covered_domains = set()
if os.path.exists(routing_file):
    content = open(routing_file).read()
    for app in apps:
        if app in content.lower():
            covered_domains.add(app)

uncovered = set(apps) - covered_domains
if uncovered:
    print(f"  GAP: {len(uncovered)} app(s) without agent routing: {', '.join(sorted(uncovered))}")
    for app in sorted(uncovered):
        print(f"    → Suggest: create agent for '{app}' domain")
else:
    print(f"  OK: All {len(apps)} apps have agent routing")

# Check for tech that might need new agents
tech_gaps = []
try:
    pyproject = open(os.path.join(D, "pyproject.toml")).read()
    if "celery" in pyproject.lower() and not os.path.exists(os.path.join(AGENTS_DIR, "celery-agent.md")):
        tech_gaps.append("celery (background jobs) → needs @celery-agent")
    if "channels" in pyproject.lower() and not os.path.exists(os.path.join(AGENTS_DIR, "websocket-agent.md")):
        tech_gaps.append("channels (websockets) → needs @websocket-agent")
    if "stripe" in pyproject.lower() and not os.path.exists(os.path.join(AGENTS_DIR, "payments-agent.md")):
        tech_gaps.append("stripe (payments) → needs @payments-agent")
    if "elasticsearch" in pyproject.lower() and not os.path.exists(os.path.join(AGENTS_DIR, "search-infra-agent.md")):
        tech_gaps.append("elasticsearch → needs @search-infra-agent")
except FileNotFoundError:
    pass

if tech_gaps:
    print(f"\n  GAP: {len(tech_gaps)} tech stack(s) without specialist agents:")
    for g in tech_gaps:
        print(f"    → {g}")
PYEOF
    fi

    # 2. Check manifest completeness
    echo ""
    echo "--- Manifest Coverage ---"
    if [ -f "$MANIFEST" ]; then
        local step_count
        step_count=$(python3 -c "import json; print(len(json.load(open('$MANIFEST')).get('steps', {})))")
        echo "  Steps defined: $step_count"

        # Check for phases without steps
        python3 -c "
import json
m = json.load(open('$MANIFEST'))
steps = m.get('steps', {})
phases_with_steps = set()
for s in steps.values():
    phases_with_steps.add(s.get('phase', -1))
for p in range(7):
    if p not in phases_with_steps:
        print(f'  GAP: Phase {p} has no steps in manifest')
"
    else
        echo "  GAP: No forge-manifest.json found"
        gaps=$((gaps + 1))
    fi

    # 3. Check verification metrics
    echo ""
    echo "--- Verification Metrics ---"
    local verify_script="$D/scripts/forge-verify.sh"
    [ ! -f "$verify_script" ] && verify_script="$HOME/.claude/scripts/forge-verify.sh"
    if [ -f "$verify_script" ]; then
        local rate
        rate=$(bash "$verify_script" verify-all 2>/dev/null | grep "Execution rate" | grep -oP '\d+')
        echo "  Execution rate: ${rate:-?}%"
        if [ "${rate:-0}" -lt 100 ]; then
            echo "  GAP: Execution rate below 100%"
            gaps=$((gaps + 1))
        fi
    fi

    local triangle_script="$D/scripts/forge-triangle.sh"
    [ ! -f "$triangle_script" ] && triangle_script="$HOME/.claude/scripts/forge-triangle.sh"
    if [ -f "$triangle_script" ]; then
        local sync
        sync=$(D="$D" bash "$triangle_script" check 2>/dev/null | grep "Sync rate" | grep -oP '\d+')
        echo "  Triangle sync: ${sync:-?}%"
        if [ "${sync:-0}" -lt 100 ]; then
            echo "  GAP: Triangle sync below 100%"
            gaps=$((gaps + 1))
        fi
    fi

    echo ""
    if [ "$gaps" -eq 0 ]; then
        echo "=== No gaps found. System is healthy. ==="
    else
        echo "=== $gaps gap(s) found. Run 'forge-grow.sh auto' to fix. ==="
    fi
}

# ═══════════════════════════════════════════════
# CREATE-AGENT — from template
# ═══════════════════════════════════════════════
cmd_create_agent() {
    local name="${1:?Usage: create-agent <name> <domain> <description>}"
    local domain="${2:?Usage: create-agent <name> <domain> <description>}"
    local desc="${3:?Usage: create-agent <name> <domain> <description>}"

    local agent_file="$AGENTS_DIR/${name}.md"

    if [ -f "$agent_file" ]; then
        echo "Agent $name already exists at $agent_file"
        return 0
    fi

    cat > "$agent_file" << AGENTEOF
---
name: $name
description: $desc
tools: ["Read", "Edit", "Write", "Bash", "Glob", "Grep", "Agent"]
---

# ${name} Agent

You are the specialist for the **${domain}** domain.

## Your Responsibilities
- All code changes in the ${domain} domain
- Tests for ${domain} functionality
- Architecture decisions for ${domain}

## Rules
1. Read SPEC.md for requirements tagged with your domain
2. Read .claude/rules/ for project-specific rules
3. Write tests FIRST (TDD), then implementation
4. Every function has [REQ-xxx] comment
5. Keep files under 300 lines
6. Run tests after every change

## Handoff
Return structured JSON:
\`\`\`json
{
  "agent": "${name}",
  "domain": "${domain}",
  "files_changed": [],
  "tests_pass": true,
  "reqs_addressed": []
}
\`\`\`
AGENTEOF

    echo "Created agent: $agent_file"
    log_growth "AGENT_CREATED: $name for domain $domain"

    # Auto-register in agent routing if it exists
    local routing="$D/.claude/rules/agent-routing.md"
    if [ -f "$routing" ]; then
        echo "| ${domain} | @${name} | — |" >> "$routing"
        echo "Registered in agent-routing.md"
    fi
}

# ═══════════════════════════════════════════════
# ADD-STEP — to manifest
# ═══════════════════════════════════════════════
cmd_add_step() {
    local phase="${1:?Usage: add-step <phase> <name> <agent> <artifact>}"
    local name="${2:?}"
    local agent="${3:?}"
    local artifact="${4:?}"

    if [ ! -f "$MANIFEST" ]; then
        echo "ERROR: forge-manifest.json not found"
        exit 1
    fi

    local ts
    ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    python3 -c "
import json

with open('$MANIFEST') as f:
    m = json.load(f)

steps = m.get('steps', {})
existing = [int(k) for k, v in steps.items() if v.get('phase') == $phase]
next_num = max(existing) + 1 if existing else $phase * 10

steps[str(next_num)] = {
    'phase': $phase,
    'name': '$name',
    'agent': '$agent',
    'skill': None,
    'artifact': '$artifact',
    'min_bytes': 100,
    'precondition': 'previous step done',
    'postcondition': 'artifact exists'
}

m['steps'] = steps
m.setdefault('change_log', []).append({
    'timestamp': '$ts',
    'change': f'Added step {next_num} ($name) to phase $phase',
    'agent': '$agent'
})

with open('$MANIFEST', 'w') as f:
    json.dump(m, f, indent=2)

print(f'Added step {next_num}: $name (phase $phase, agent $agent)')
"

    log_growth "STEP_ADDED: $name in phase $phase by $agent"
}

# ═══════════════════════════════════════════════
# ADD-GROUP — register new agent group
# ═══════════════════════════════════════════════
cmd_add_group() {
    local name="${1:?Usage: add-group <group_name>}"

    local readme="$AGENTS_DIR/README.md"
    if [ -f "$readme" ] && grep -q "## GROUP.*$name" "$readme" 2>/dev/null; then
        echo "Group $name already exists"
        return 0
    fi

    # Count existing groups
    local count
    count=$(grep -c "^## GROUP" "$readme" 2>/dev/null || echo "0")
    local next=$((count + 1))

    echo "" >> "$readme"
    echo "## GROUP $next: $(echo "$name" | tr '[:lower:]' '[:upper:]') (auto-created)" >> "$readme"
    echo "" >> "$readme"
    echo "| Agent | Role | When Used |" >> "$readme"
    echo "|-------|------|-----------|" >> "$readme"

    echo "Created group $next: $name in README.md"
    log_growth "GROUP_CREATED: $name (group $next)"
}

# ═══════════════════════════════════════════════
# AUTO — fully autonomous scan + fix
# ═══════════════════════════════════════════════
cmd_auto() {
    echo "=== Forge Auto-Growth ==="
    echo ""
    cmd_scan
    echo ""

    # If all metrics at 100%, check for tech suggestions
    echo "--- Tech Radar ---"
    python3 << 'PYEOF'
import os, glob

D = os.environ.get("D", os.getcwd())

suggestions = []

# Check for common patterns that suggest new capabilities
for pattern, suggestion in [
    ("**/celery*.py", "Background job processing → consider adding Celery + @celery-agent"),
    ("**/websocket*.py", "WebSocket support → consider adding Channels + @websocket-agent"),
    ("**/graphql*.py", "GraphQL API → consider adding Strawberry + @graphql-agent"),
    ("**/tasks.py", "Task queue detected → ensure background processing is properly handled"),
]:
    if glob.glob(os.path.join(D, pattern), recursive=True):
        suggestions.append(suggestion)

# Check SPEC for unimplemented features
try:
    spec = open(os.path.join(D, "SPEC.md")).read()
    if "webhook" in spec.lower() and not glob.glob(os.path.join(D, "**/webhook*.py"), recursive=True):
        suggestions.append("SPEC mentions webhooks but no implementation found")
    if "notification" in spec.lower() and not glob.glob(os.path.join(D, "**/notification*.py"), recursive=True):
        suggestions.append("SPEC mentions notifications but no implementation found")
    if "background" in spec.lower() and not glob.glob(os.path.join(D, "**/tasks.py"), recursive=True):
        suggestions.append("SPEC mentions background processing but no task runner found")
except FileNotFoundError:
    pass

if suggestions:
    print(f"  {len(suggestions)} suggestion(s):")
    for s in suggestions:
        print(f"    → {s}")
else:
    print("  No new tech suggestions. Stack is complete for current requirements.")
PYEOF

    echo ""
    echo "=== Growth cycle complete ==="
}

# ═══════════════════════════════════════════════
# STATUS — growth metrics
# ═══════════════════════════════════════════════
cmd_status() {
    echo "=== Forge Growth Status ==="

    local agent_count
    agent_count=$(ls "$AGENTS_DIR"/*.md 2>/dev/null | grep -v README | wc -l)
    local group_count
    group_count=$(grep -c "^## GROUP" "$AGENTS_DIR/README.md" 2>/dev/null || echo "0")

    echo "  Agents: $agent_count"
    echo "  Groups: $group_count"

    if [ -f "$MANIFEST" ]; then
        local step_count
        step_count=$(python3 -c "import json; print(len(json.load(open('$MANIFEST')).get('steps', {})))")
        echo "  Steps: $step_count"
    fi

    if [ -f "$GROWTH_LOG" ]; then
        local log_entries
        log_entries=$(wc -l < "$GROWTH_LOG")
        echo "  Growth log: $log_entries entries"
        echo ""
        echo "  Recent growth:"
        tail -5 "$GROWTH_LOG" | while read -r line; do
            echo "    $line"
        done
    fi
}

case "${1:-help}" in
    scan)         cmd_scan ;;
    create-agent) shift; cmd_create_agent "$@" ;;
    add-step)     shift; cmd_add_step "$@" ;;
    add-group)    shift; cmd_add_group "$@" ;;
    auto)         cmd_auto ;;
    status)       cmd_status ;;
    *)
        echo "Forge Growth Engine — self-evolving build system"
        echo "  scan              Detect gaps (missing agents, low metrics)"
        echo "  create-agent      Create agent from template"
        echo "  add-step          Add step to manifest"
        echo "  add-group         Register new agent group"
        echo "  auto              Full autonomous scan + suggest + create"
        echo "  status            Growth metrics"
        ;;
esac
