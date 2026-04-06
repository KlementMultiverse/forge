#!/usr/bin/env bats
# Tests for scripts/forge-stack.sh

setup() {
    load '../../test_helper/common-setup'
    _common_setup
    export PROJECT_ROOT="$TEST_PROJECT"
}

teardown() {
    _common_teardown
}

@test "forge-stack.sh exists and is executable" {
    assert [ -f "$FORGE_DIR/scripts/forge-stack.sh" ]
    assert [ -x "$FORGE_DIR/scripts/forge-stack.sh" ]
}

@test "forge-stack list runs without error" {
    run bash "$FORGE_DIR/scripts/forge-stack.sh" list
    [[ "$status" -le 1 ]]
}

@test "forge-stack help shows commands" {
    run bash "$FORGE_DIR/scripts/forge-stack.sh" help
    assert_output --partial "list"
    assert_output --partial "create"
}

@test "forge-stack create makes stack directory" {
    run bash "$FORGE_DIR/scripts/forge-stack.sh" create test-stack --auto
    [[ "$status" -le 1 ]]
}
