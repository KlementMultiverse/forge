#!/usr/bin/env bats
# Tests for scripts/forge-shell.sh

setup() {
    load '../../test_helper/common-setup'
    _common_setup
}

teardown() {
    _common_teardown
}

@test "forge-shell.sh exists" {
    assert [ -f "$FORGE_DIR/scripts/forge-shell.sh" ]
}

@test "forge-shell.sh defines forge function" {
    source "$FORGE_DIR/scripts/forge-shell.sh"
    run type forge
    assert_success
    assert_output --partial "function"
}

@test "forge function shows help without args" {
    source "$FORGE_DIR/scripts/forge-shell.sh"
    run forge help
    [[ "$status" -le 1 ]]
}
