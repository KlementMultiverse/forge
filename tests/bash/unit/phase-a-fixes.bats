#!/usr/bin/env bats
# Tests for Phase A fixes — one test per CR finding
# Each test verifies the fix is present in phase-a-setup.md

setup() {
    load '../../test_helper/common-setup'
    _common_setup
    FORGE_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
    export FORGE_DIR
    PHASE_A="$FORGE_DIR/commands/forge-phases/phase-a-setup.md"
}

teardown() {
    _common_teardown
}

# ─── #129: git init guard in S1 ───

@test "Phase A S1 has git init if .git missing" {
    # S1 ASSESS should check for .git and init if missing
    run grep -A3 "STEP S1" "$PHASE_A"
    assert_success
    # The S1 section should contain git init guard
    run grep "git init" "$PHASE_A"
    assert_success
}
