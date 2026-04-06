#!/usr/bin/env bats
# Tests for scripts/forge-phase-map.sh
# Verifies phase boundary mapping and gate step identification

setup() {
    load '../../test_helper/common-setup'
    _common_setup
    source "$FORGE_DIR/scripts/forge-phase-map.sh"
}

teardown() {
    _common_teardown
}

# ─── get_phase_for_step ───

@test "step 1 maps to phase 0" {
    result=$(get_phase_for_step 1)
    [ "$result" -eq 0 ]
}

@test "step 8 maps to phase 0 (gate boundary)" {
    result=$(get_phase_for_step 8)
    [ "$result" -eq 0 ]
}

@test "step 9 maps to phase 1" {
    result=$(get_phase_for_step 9)
    [ "$result" -eq 1 ]
}

@test "step 11 maps to phase 1 (gate boundary)" {
    result=$(get_phase_for_step 11)
    [ "$result" -eq 1 ]
}

@test "step 12 maps to phase 2" {
    result=$(get_phase_for_step 12)
    [ "$result" -eq 2 ]
}

@test "step 19 maps to phase 2 (gate boundary)" {
    result=$(get_phase_for_step 19)
    [ "$result" -eq 2 ]
}

@test "step 20 maps to phase 3" {
    result=$(get_phase_for_step 20)
    [ "$result" -eq 3 ]
}

@test "step 39 maps to phase 3 (gate boundary)" {
    result=$(get_phase_for_step 39)
    [ "$result" -eq 3 ]
}

@test "step 40 maps to phase 4" {
    result=$(get_phase_for_step 40)
    [ "$result" -eq 4 ]
}

@test "step 46 maps to phase 4 (gate boundary)" {
    result=$(get_phase_for_step 46)
    [ "$result" -eq 4 ]
}

@test "step 47 maps to phase 5" {
    result=$(get_phase_for_step 47)
    [ "$result" -eq 5 ]
}

@test "step 56 maps to phase 5 (gate boundary)" {
    result=$(get_phase_for_step 56)
    [ "$result" -eq 5 ]
}

@test "step 57 maps to phase 6" {
    result=$(get_phase_for_step 57)
    [ "$result" -eq 6 ]
}

# ─── GATE_STEPS ───

@test "GATE_STEPS contains all 6 gate boundaries" {
    [[ "$GATE_STEPS" == *"8"* ]]
    [[ "$GATE_STEPS" == *"11"* ]]
    [[ "$GATE_STEPS" == *"19"* ]]
    [[ "$GATE_STEPS" == *"39"* ]]
    [[ "$GATE_STEPS" == *"46"* ]]
    [[ "$GATE_STEPS" == *"56"* ]]
}

# ─── PHASE_NAMES ───

@test "phase 0 is named Genesis" {
    [ "${PHASE_NAMES[0]}" = "Genesis" ]
}

@test "phase 3 is named Implement" {
    [ "${PHASE_NAMES[3]}" = "Implement" ]
}

@test "phase 5 is named Review+Learn" {
    [ "${PHASE_NAMES[5]}" = "Review+Learn" ]
}

# ─── PHASE_LAST_STEP ───

@test "phase 0 last step is 8" {
    [ "${PHASE_LAST_STEP[0]}" -eq 8 ]
}

@test "phase 3 last step is 39" {
    [ "${PHASE_LAST_STEP[3]}" -eq 39 ]
}

@test "phase 6 last step is 57" {
    [ "${PHASE_LAST_STEP[6]}" -eq 57 ]
}
