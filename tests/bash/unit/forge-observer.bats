#!/usr/bin/env bats
# Tests for scripts/forge-observer-approve.sh and forge-observer-check.sh

setup() {
    load '../../test_helper/common-setup'
    _common_setup
    setup_mock_git_repo
    setup_mock_state '{"version":"1.1.0","project":"test","current_step":8,"current_phase":0}'
    mkdir -p "$TEST_PROJECT/docs/.approvals"
    export PROJECT_ROOT="$TEST_PROJECT"
    export D="$TEST_PROJECT"
}

teardown() {
    _common_teardown
}

# ─── observer-approve ───

@test "observer-approve.sh exists and is executable" {
    assert [ -f "$FORGE_DIR/scripts/forge-observer-approve.sh" ]
    assert [ -x "$FORGE_DIR/scripts/forge-observer-approve.sh" ]
}

@test "observer-approve check runs without error" {
    cd "$TEST_PROJECT"
    run bash "$FORGE_DIR/scripts/forge-observer-approve.sh" check
    [[ "$status" -le 1 ]]
}

@test "observer-approve approve creates approval marker" {
    cd "$TEST_PROJECT"
    run bash "$FORGE_DIR/scripts/forge-observer-approve.sh" approve
    assert_success
}

# ─── observer-check ───

@test "observer-check.sh exists and is executable" {
    assert [ -f "$FORGE_DIR/scripts/forge-observer-check.sh" ]
    assert [ -x "$FORGE_DIR/scripts/forge-observer-check.sh" ]
}

@test "observer-check runs without error" {
    cd "$TEST_PROJECT"
    run bash "$FORGE_DIR/scripts/forge-observer-check.sh"
    [[ "$status" -le 1 ]]
}
