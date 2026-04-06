#!/usr/bin/env bats
# Tests for scripts/forge-grow.sh

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

@test "forge-grow.sh exists and is executable" {
    assert [ -f "$FORGE_DIR/scripts/forge-grow.sh" ]
    assert [ -x "$FORGE_DIR/scripts/forge-grow.sh" ]
}

@test "forge-grow help shows commands" {
    run bash "$FORGE_DIR/scripts/forge-grow.sh" help
    assert_output --partial "scan"
}

@test "forge-grow scan runs without error" {
    cd "$TEST_PROJECT"
    run bash "$FORGE_DIR/scripts/forge-grow.sh" scan
    [[ "$status" -le 1 ]]
}
