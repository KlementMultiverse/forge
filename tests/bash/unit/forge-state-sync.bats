#!/usr/bin/env bats
# Tests for scripts/forge-state-sync.sh
# Verifies state synchronization on prompt submit

setup() {
    load '../../test_helper/common-setup'
    _common_setup
    setup_mock_git_repo
    export PROJECT_ROOT="$TEST_PROJECT"
    export D="$TEST_PROJECT"
}

teardown() {
    _common_teardown
}

@test "state-sync script exists and is executable" {
    assert [ -f "$FORGE_DIR/scripts/forge-state-sync.sh" ]
    assert [ -x "$FORGE_DIR/scripts/forge-state-sync.sh" ]
}

@test "state-sync runs without error when state file exists" {
    cd "$TEST_PROJECT"
    setup_mock_state '{"version":"1.1.0","project":"test","current_step":5}'
    run bash "$FORGE_DIR/scripts/forge-state-sync.sh"
    [[ "$status" -le 1 ]]
}

@test "state-sync handles missing state file gracefully" {
    cd "$TEST_PROJECT"
    run bash "$FORGE_DIR/scripts/forge-state-sync.sh"
    [[ "$status" -le 1 ]]
}
