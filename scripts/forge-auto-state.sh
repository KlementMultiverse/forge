#!/bin/bash
# Auto-state updater — called by PostToolUse hooks on Skill and Agent
# Detects which step just completed from the skill/agent name and updates forge-state.json
#
# This replaces 43 manual "update-step" lines in forge.md

set -uo pipefail

# Source shared phase mapping
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/forge-phase-map.sh"

D="$PWD"
STATE="$D/docs/forge-state.json"
[ -f "$STATE" ] || exit 0

ENFORCE="$D/scripts/forge-enforce.sh"
[ -f "$ENFORCE" ] || ENFORCE="$HOME/.claude/scripts/forge-enforce.sh"
[ -f "$ENFORCE" ] || exit 0

SKILL="${1:-}"
AGENT="${2:-}"

# Map skill/agent to step number
step=""
case "$SKILL" in
    discover)       step=1 ;;
    requirements)   step=2 ;;
    feasibility)    step=3 ;;
    generate-spec)  step=4 ;;
    challenge)      step=5 ;;
    bootstrap)      step=6 ;;
    checkpoint)
        # Checkpoint can be for any phase — detect from args
        ARGS="${3:-}"
        case "$ARGS" in
            *phase-0*|*Genesis*)   step=7 ;;
            *specify*|*proposal*)  step=10 ;;
            *architect*|*design*)  step=18 ;;
            *phase-3*|*Implement*) step=38 ;;
            *)                     step="" ;;
        esac
        ;;
    gate)
        ARGS="${3:-}"
        case "$ARGS" in
            *phase-0*) step=8;  bash "$ENFORCE" update-gate 0 2>/dev/null ;;
            *stage-1*) step=11; bash "$ENFORCE" update-gate 1 2>/dev/null ;;
            *stage-2*) step=19; bash "$ENFORCE" update-gate 2 2>/dev/null ;;
            *stage-3*) step=39; bash "$ENFORCE" update-gate 3 2>/dev/null ;;
            *stage-4*) step=46; bash "$ENFORCE" update-gate 4 2>/dev/null ;;
            *stage-5*) step=56; bash "$ENFORCE" update-gate 5 2>/dev/null ;;
        esac
        ;;
    specify)        step=9 ;;
    plan-review)    step=12 ;;
    design-doc)     step=14 ;;
    plan-tasks)     step=15 ;;
    sc:estimate)    step=16 ;;
    sc:workflow)    step=17 ;;
    review)         step=37 ;;
    sc:analyze)     step=40 ;;
    audit-patterns) step=41 ;;
    sc:test)        step=42 ;;
    security-scan)  step=44 ;;
    design-audit|critic) step=45 ;;
    sc:cleanup)     step=47 ;;
    sc:improve)     step=48 ;;
    retro)          step=49 ;;
    sc:reflect)     step=50 ;;
    sc:document)    step=51 ;;
    prune|evolve)   step=53 ;;
    autoresearch)   step=54 ;;
    sc:save)        step=55 ;;
esac

# Map agent types to steps
case "$AGENT" in
    *api-architect*|*api*contract*) step=13 ;;
    *deploy-guide*)                 step=51 ;;
    *playbook-curator*)             step=52 ;;
esac

if [ -n "$step" ]; then
    bash "$ENFORCE" update-step "$step" DONE 2>/dev/null
    echo "[FORGE-STATE] Step $step marked DONE"
fi
