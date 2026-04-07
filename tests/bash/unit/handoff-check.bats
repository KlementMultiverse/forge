#!/usr/bin/env bats
# Tests for universal agent execution loop and handoff check (#185)

setup() {
    load '../../test_helper/common-setup'
    _common_setup
    FORGE_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
    export FORGE_DIR
    PHASE_A="$FORGE_DIR/commands/forge-phases/phase-a-setup.md"
    SCRIPT="$FORGE_DIR/scripts/forge-handoff-check.sh"
}

teardown() {
    _common_teardown
}

# ─── Universal loop definition in phase-a ───

@test "phase-a has universal agent execution loop definition" {
    run grep "AGENT EXECUTION LOOP" "$PHASE_A"
    assert_success
}

@test "phase-a loop has PREPARE step" {
    run grep -i "PREPARE:.*reads input artifact\|PM reads input artifact" "$PHASE_A"
    assert_success
}

@test "phase-a loop has MEASURE step bounded by discovery notes" {
    run grep -i "MEASURE.*bounded\|SCORE.*COVERED" "$PHASE_A"
    assert_success
}

@test "phase-a loop has ENHANCE step" {
    run grep -i "ENHANCE.*prompt\|YOU MISSED" "$PHASE_A"
    assert_success
}

@test "phase-a loop has 3 attempt max" {
    run grep -i "ATTEMPT 3\|attempt 3\|max 3" "$PHASE_A"
    assert_success
}

@test "phase-a loop has INVENTED check" {
    run grep -i "INVENTED\|Not in input\|not traceable" "$PHASE_A"
    assert_success
}

@test "phase-a loop has REVERSE ENGINEER cross-verify" {
    run grep -i "REVERSE ENGINEER\|CROSS.VERIFY\|bidirectional" "$PHASE_A"
    assert_success
}

@test "phase-a loop has bounded autoresearch constraint" {
    run grep -i "BOUNDED\|discovery notes.*source of truth\|NEVER invent" "$PHASE_A"
    assert_success
}

@test "phase-a loop can raise questions to user" {
    run grep -i "RAISE QUESTION\|raise.*question.*user\|gap.*found" "$PHASE_A"
    assert_success
}

# ─── Handoff metrics per step ───

@test "S3 has HANDOFF METRIC section" {
    run grep -i "HANDOFF METRIC" "$PHASE_A"
    assert_success
}

@test "S3 handoff checks COMPLIANCE propagation" {
    run grep -i "COMPLIANCE.*MUST.*NEVER\|COMPLIANCE.*rule" "$PHASE_A"
    assert_success
}

@test "S3 handoff checks EXCLUDED propagation" {
    run grep -i "EXCLUDED.*What NOT\|EXCLUDED.*anti" "$PHASE_A"
    assert_success
}

@test "S4 has HANDOFF METRIC" {
    # S4 should have HANDOFF METRIC within 15 lines of STEP S4
    run grep -A15 "STEP S4" "$PHASE_A"
    assert_success
    echo "$output" | grep -qi "HANDOFF METRIC"
}

# ─── forge-handoff-check.sh script ───

@test "forge-handoff-check.sh exists and is executable" {
    assert [ -f "$SCRIPT" ]
    assert [ -x "$SCRIPT" ]
}

@test "forge-handoff-check.sh has help" {
    run "$SCRIPT" --help
    assert_success
}

@test "forge-handoff-check.sh check with missing args shows usage" {
    run "$SCRIPT" check 2>&1
    # Should exit 2 (usage error) when args missing
    [ "$status" -eq 2 ]
}

# ─── hooks.json has PostToolUse Agent hook ───

@test "hooks.json has PostToolUse Agent hook for handoff check" {
    run grep -i "forge-handoff-check\|handoff.*check" "$FORGE_DIR/templates/hooks.json"
    assert_success
}
