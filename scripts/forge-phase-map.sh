#!/bin/bash
# forge-phase-map.sh — single source of truth for step->phase mapping
# Sourced by: forge-enforce.sh, forge-fsm.sh, forge-auto-state.sh,
#             forge-triangle.sh, forge-phase-gate.sh
#
# Usage: source ~/.claude/scripts/forge-phase-map.sh

get_phase_for_step() {
    local step=$1
    if [ "$step" -le 8 ]; then echo 0
    elif [ "$step" -le 11 ]; then echo 1
    elif [ "$step" -le 19 ]; then echo 2
    elif [ "$step" -le 39 ]; then echo 3
    elif [ "$step" -le 46 ]; then echo 4
    elif [ "$step" -le 56 ]; then echo 5
    else echo 6; fi
}

# Steps that are gate boundaries
GATE_STEPS="8 11 19 39 46 56"

# Phase names indexed by number
PHASE_NAMES=(
    [0]="Genesis"
    [1]="Specify"
    [2]="Architect"
    [3]="Implement"
    [4]="Validate"
    [5]="Review+Learn"
    [6]="Iterate"
)

# Last step in each phase
PHASE_LAST_STEP=(
    [0]=8
    [1]=11
    [2]=19
    [3]=39
    [4]=46
    [5]=56
    [6]=57
)
