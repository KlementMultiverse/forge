#!/usr/bin/env bats
# Tests for scripts/forge-change-validator.sh

setup() {
    load '../../test_helper/common-setup'
    _common_setup
    export FORGE_DIR="$FORGE_DIR"
}

teardown() {
    _common_teardown
}

@test "forge-change-validator.sh exists and is executable" {
    assert [ -f "$FORGE_DIR/scripts/forge-change-validator.sh" ]
    assert [ -x "$FORGE_DIR/scripts/forge-change-validator.sh" ]
}

@test "change-validator help shows all commands" {
    run bash "$FORGE_DIR/scripts/forge-change-validator.sh" help
    assert_output --partial "pre-edit"
    assert_output --partial "post-edit"
    assert_output --partial "pre-commit"
    assert_output --partial "post-merge"
    assert_output --partial "full-check"
}

@test "change-validator pre-edit runs without error" {
    run bash "$FORGE_DIR/scripts/forge-change-validator.sh" pre-edit "$FORGE_DIR/scripts/forge-enforce.sh"
    assert_success
    assert_output --partial "Pre-edit"
}

@test "change-validator post-edit detects missing test" {
    mkdir -p "$TEST_PROJECT/scripts" "$TEST_PROJECT/tests"
    echo "# new script" > "$TEST_PROJECT/scripts/new-untested.sh"
    cp "$FORGE_DIR/scripts/forge-change-validator.sh" "$TEST_PROJECT/scripts/"
    chmod +x "$TEST_PROJECT/scripts/forge-change-validator.sh"
    run env FORGE_DIR="$TEST_PROJECT" bash "$TEST_PROJECT/scripts/forge-change-validator.sh" post-edit "scripts/new-untested.sh"
    assert_output --partial "No test found"
}

@test "change-validator full-check runs all checks" {
    run bash "$FORGE_DIR/scripts/forge-change-validator.sh" full-check
    assert_output --partial "README Sync"
    assert_output --partial "Test Coverage"
}

@test "meta-protocol document exists" {
    assert [ -f "$FORGE_DIR/docs/protocols/forge-meta-protocol.md" ]
}

@test "meta-protocol has all 3 protocol sections" {
    local file="$FORGE_DIR/docs/protocols/forge-meta-protocol.md"
    run grep -c "## [0-9]" "$file"
    [[ "$output" -ge 3 ]]
}

@test "meta-protocol has enforcement section" {
    run grep "Mechanical Enforcement" "$FORGE_DIR/docs/protocols/forge-meta-protocol.md"
    assert_success
}
