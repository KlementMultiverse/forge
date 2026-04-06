#!/usr/bin/env bats
# Tests for forge.md frontmatter (#175)

setup() {
    load '../../test_helper/common-setup'
    _common_setup
    FORGE_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
    export FORGE_DIR
}

teardown() {
    _common_teardown
}

@test "forge.md has YAML frontmatter" {
    run head -1 "$FORGE_DIR/commands/forge.md"
    assert_output "---"
}

@test "forge.md has description field" {
    run grep "^description:" "$FORGE_DIR/commands/forge.md"
    assert_success
}

@test "forge.md has argument-hint field" {
    run grep "^argument-hint:" "$FORGE_DIR/commands/forge.md"
    assert_success
}

@test "forge.md does NOT use context: fork" {
    run grep "context: fork" "$FORGE_DIR/commands/forge.md"
    assert_failure
}
