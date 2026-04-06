#!/usr/bin/env bats
# Integration tests: verify all enforcement systems are wired into hooks/gates
# These tests check that the hooks.json template includes all required enforcement

setup() {
    load '../../test_helper/common-setup'
    _common_setup
}

teardown() {
    _common_teardown
}

# ─── hooks.json has required entries ───

@test "hooks.json has PreToolUse Edit hook for --impact advisory" {
    run grep -l "impact\|IMPACT" "$FORGE_DIR/templates/hooks.json"
    assert_success
}

@test "hooks.json has PostToolUse Write hook for forge-trace" {
    run grep -l "forge-trace\|FORGE.TRACE\|trace-update" "$FORGE_DIR/templates/hooks.json"
    assert_success
}

# ─── gate command checks suspect REQs ───

@test "gate command references check-suspect" {
    run grep -rl "check-suspect\|suspect" "$FORGE_DIR/commands/gate.md"
    assert_success
}

# ─── gate command checks review-guard ───

@test "gate command references review-guard" {
    run grep -rl "review-guard\|check-reviewed\|mark-reviewed" "$FORGE_DIR/commands/gate.md"
    assert_success
}

# ─── gate command checks triangle ───

@test "gate command references triangle check" {
    run grep -rl "forge-triangle\|triangle" "$FORGE_DIR/commands/gate.md"
    assert_success
}

# ─── pre-commit includes test-guard ───

@test "pre-commit hook references test-guard for changed scripts" {
    run grep -l "test-guard\|forge-test-guard" "$FORGE_DIR/templates/pre-commit"
    assert_success
}

# ─── Phase 3 N9 creates OWNERS ───

@test "phase-3-implement references OWNERS creation at N9" {
    run grep -l "OWNERS\|forge-ownership" "$FORGE_DIR/commands/forge-phases/phase-3-implement.md"
    assert_success
}
