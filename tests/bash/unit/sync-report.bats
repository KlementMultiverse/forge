#!/usr/bin/env bats
# Tests for scripts/sync-report.sh
# Verifies comprehensive sync reporting

setup() {
    load '../../test_helper/common-setup'
    _common_setup
    export PROJECT_ROOT="$TEST_PROJECT"
}

teardown() {
    _common_teardown
}

@test "sync-report runs without SPEC.md" {
    cd "$TEST_PROJECT"
    run bash "$FORGE_DIR/scripts/sync-report.sh" "$TEST_PROJECT"
    assert_success
    assert_output --partial "SYNC REPORT"
}

@test "sync-report shows traceability section" {
    cd "$TEST_PROJECT"
    echo "REQ-AUTH-001 test" > SPEC.md
    run bash "$FORGE_DIR/scripts/sync-report.sh" "$TEST_PROJECT"
    assert_output --partial "TRACEABILITY"
}

@test "sync-report shows file size section" {
    cd "$TEST_PROJECT"
    run bash "$FORGE_DIR/scripts/sync-report.sh" "$TEST_PROJECT"
    assert_output --partial "FILE SIZE"
}

@test "sync-report shows git status" {
    cd "$TEST_PROJECT"
    setup_mock_git_repo
    run bash "$FORGE_DIR/scripts/sync-report.sh" "$TEST_PROJECT"
    assert_output --partial "GIT STATUS"
}
