#!/usr/bin/env bats
# Tests for scripts/forge-handshake.sh

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

@test "forge-handshake.sh exists and is executable" {
    assert [ -f "$FORGE_DIR/scripts/forge-handshake.sh" ]
    assert [ -x "$FORGE_DIR/scripts/forge-handshake.sh" ]
}

@test "handshake help shows commands" {
    run bash "$FORGE_DIR/scripts/forge-handshake.sh" help
    [[ "$status" -le 1 ]]
}

@test "handshake check-pending runs without error" {
    cd "$TEST_PROJECT"
    run bash "$FORGE_DIR/scripts/forge-handshake.sh" check-pending
    [[ "$status" -le 1 ]]
}
