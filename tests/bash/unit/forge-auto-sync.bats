#!/usr/bin/env bats
# Tests for scripts/forge-auto-sync.sh

setup() {
    load '../../test_helper/common-setup'
    _common_setup
    export FORGE_DIR="$FORGE_DIR"
    export PROJECT_ROOT="$TEST_PROJECT"
    export D="$TEST_PROJECT"
}

teardown() {
    _common_teardown
}

@test "forge-auto-sync.sh exists and is executable" {
    assert [ -f "$FORGE_DIR/scripts/forge-auto-sync.sh" ]
    assert [ -x "$FORGE_DIR/scripts/forge-auto-sync.sh" ]
}

@test "auto-sync help shows commands" {
    run bash "$FORGE_DIR/scripts/forge-auto-sync.sh" help
    assert_output --partial "queue"
    assert_output --partial "run"
    assert_output --partial "status"
}

@test "auto-sync queue creates pending file for component" {
    run bash "$FORGE_DIR/scripts/forge-auto-sync.sh" queue "$FORGE_DIR/scripts/forge-enforce.sh"
    assert_success
    assert [ -f "$TEST_PROJECT/docs/.forge-sync-pending" ]
    run cat "$TEST_PROJECT/docs/.forge-sync-pending"
    assert_output --partial "readme_sync"
    assert_output --partial "registry_update"
}

@test "auto-sync status shows pending syncs" {
    bash "$FORGE_DIR/scripts/forge-auto-sync.sh" queue "$FORGE_DIR/scripts/forge-enforce.sh"
    run bash "$FORGE_DIR/scripts/forge-auto-sync.sh" status
    assert_output --partial "Pending"
}

@test "auto-sync clear removes pending" {
    bash "$FORGE_DIR/scripts/forge-auto-sync.sh" queue "$FORGE_DIR/scripts/forge-enforce.sh"
    bash "$FORGE_DIR/scripts/forge-auto-sync.sh" clear
    run bash "$FORGE_DIR/scripts/forge-auto-sync.sh" status
    assert_output --partial "No pending"
}

@test "auto-sync run executes and clears pending" {
    bash "$FORGE_DIR/scripts/forge-auto-sync.sh" queue "$FORGE_DIR/scripts/forge-enforce.sh"
    run bash "$FORGE_DIR/scripts/forge-auto-sync.sh" run
    assert_success
    assert_output --partial "FORGE-SYNC"
    # Pending should be cleared
    run bash "$FORGE_DIR/scripts/forge-auto-sync.sh" status
    assert_output --partial "No pending"
}

@test "pre-commit hook references auto-sync" {
    run grep "auto-sync\|forge-auto-sync" "$FORGE_DIR/templates/pre-commit"
    assert_success
}

@test "PostToolUse Write hook queues auto-sync" {
    run grep "forge-auto-sync.*queue" "$FORGE_DIR/templates/hooks.json"
    assert_success
}
