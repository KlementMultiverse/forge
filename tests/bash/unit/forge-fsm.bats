#!/usr/bin/env bats
# Tests for scripts/forge-fsm.sh
# Verifies state machine transitions, gate readiness, write permissions

setup() {
    load '../../test_helper/common-setup'
    _common_setup
    setup_mock_git_repo
    setup_mock_state '{"version":"1.1.0","project":"test","current_step":8,"current_phase":0,"status":"IN_PROGRESS","phases":{"0":{"status":"IN_PROGRESS","gate_passed":false}}}'
    export PROJECT_ROOT="$TEST_PROJECT"
}

teardown() {
    _common_teardown
}

# ─── next command ───

@test "fsm next runs without crashing" {
    cd "$TEST_PROJECT"
    run bash "$FORGE_DIR/scripts/forge-fsm.sh" next
    # May return 1 if no next action, but should not crash (exit 2+)
    [[ "$status" -le 1 ]]
}

# ─── can-gate ───

@test "fsm can-gate fails when phase not complete" {
    cd "$TEST_PROJECT"
    run bash "$FORGE_DIR/scripts/forge-fsm.sh" can-gate
    assert_failure
}

# ─── can-write ───

@test "fsm can-write allows writing during IN_PROGRESS" {
    cd "$TEST_PROJECT"
    run bash "$FORGE_DIR/scripts/forge-fsm.sh" can-write
    assert_success
}

# ─── help ───

@test "fsm help shows available commands" {
    run bash "$FORGE_DIR/scripts/forge-fsm.sh" help
    assert_output --partial "next"
}
