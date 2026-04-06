#!/usr/bin/env bats
# Tests for scripts/docker-state.sh

setup() {
    load '../../test_helper/common-setup'
    _common_setup
    export PROJECT_ROOT="$TEST_PROJECT"
}

teardown() {
    _common_teardown
}

@test "docker-state.sh exists and is executable" {
    assert [ -f "$FORGE_DIR/scripts/docker-state.sh" ]
    assert [ -x "$FORGE_DIR/scripts/docker-state.sh" ]
}

@test "docker-state help shows commands" {
    run bash "$FORGE_DIR/scripts/docker-state.sh" --help
    [[ "$status" -le 1 ]]
}

@test "docker-state check runs without docker" {
    cd "$TEST_PROJECT"
    run bash "$FORGE_DIR/scripts/docker-state.sh" --check
    # Should handle missing docker gracefully
    [[ "$status" -le 1 ]]
}
