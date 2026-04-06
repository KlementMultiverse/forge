#!/usr/bin/env bats
# Tests: observer fallback when no observer configured (#119)

setup() {
    load '../../test_helper/common-setup'
    _common_setup
    setup_mock_git_repo
    setup_mock_state '{"version":"1.1.0","current_step":8,"current_phase":0,"phases":{"0":{"status":"IN_PROGRESS"}},"gate_circuit":{"state":"CLOSED","poll_count":0,"cooldown_count":0,"last_poll_at":null,"cooldown_until":null,"last_response":null}}'
    export PROJECT_ROOT="$TEST_PROJECT"
    export D="$TEST_PROJECT"
}

teardown() {
    _common_teardown
}

@test "phase-gate check without observer does not hang" {
    cd "$TEST_PROJECT"
    # No .observer-reviews.log, no .observer-reviewing
    run timeout 10 bash "$FORGE_DIR/scripts/forge-phase-gate.sh" check
    # Must complete within 10s, return 1 (WAIT) not hang
    [[ "$status" -le 2 ]]
}

@test "phase-gate shows observer not configured message" {
    cd "$TEST_PROJECT"
    run bash "$FORGE_DIR/scripts/forge-phase-gate.sh" check
    assert_output --partial "Observer"
}

@test "phase-gate allows manual observer approval via approve-cr" {
    cd "$TEST_PROJECT"
    run bash "$FORGE_DIR/scripts/forge-phase-gate.sh" approve-cr 0
    assert_success
}
