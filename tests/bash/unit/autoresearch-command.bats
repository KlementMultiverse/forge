#!/usr/bin/env bats
# Tests for /autoresearch command (#60)
# Verifies command exists and has proper format

setup() {
    load '../../test_helper/common-setup'
    _common_setup
}

teardown() {
    _common_teardown
}

@test "autoresearch command file exists" {
    assert [ -f "$FORGE_DIR/commands/autoresearch.md" ]
}

@test "autoresearch has proper header format" {
    run head -1 "$FORGE_DIR/commands/autoresearch.md"
    assert_output --partial "# /autoresearch"
}

@test "autoresearch is referenced in phase-4-5-validate.md" {
    run grep -c "autoresearch" "$FORGE_DIR/commands/forge-phases/phase-4-5-validate.md"
    assert [ "$output" -gt 0 ]
}
