#!/usr/bin/env bats
# Tests for PM behaviors rules architecture (#173)
# Verifies the "who vs what" separation

setup() {
    load '../../test_helper/common-setup'
    _common_setup
    FORGE_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
    export FORGE_DIR
}

teardown() {
    _common_teardown
}

# ─── rules/pm-behaviors.md exists and has key sections ───

@test "pm-behaviors.md rules file exists" {
    assert [ -f "$FORGE_DIR/rules/pm-behaviors.md" ]
}

@test "pm-behaviors has self-correction rules" {
    run grep -iE "self.correct|max 3|retry|investigate.*before" "$FORGE_DIR/rules/pm-behaviors.md"
    assert_success
}

@test "pm-behaviors has confidence routing" {
    run grep -iE "confidence|80%|LOW.*human|HIGH.*autonomous" "$FORGE_DIR/rules/pm-behaviors.md"
    assert_success
}

@test "pm-behaviors has anti-patterns" {
    run grep -iE "NEVER write.*code|NEVER skip|NEVER bypass" "$FORGE_DIR/rules/pm-behaviors.md"
    assert_success
}

@test "pm-behaviors has handoff protocol" {
    run grep -iE "handoff|Summary.*REQ|Quality.*Tests|Delegation" "$FORGE_DIR/rules/pm-behaviors.md"
    assert_success
}

@test "pm-behaviors has chaos resilience" {
    run grep -iE "chaos|no SPEC.*stop|empty output.*retry|contradictory" "$FORGE_DIR/rules/pm-behaviors.md"
    assert_success
}

@test "pm-behaviors has tool failure handling" {
    run grep -iE "context7.*unavailable|fallback|web search.*training" "$FORGE_DIR/rules/pm-behaviors.md"
    assert_success
}

@test "pm-behaviors is under 200 lines" {
    local lines
    lines=$(wc -l < "$FORGE_DIR/rules/pm-behaviors.md")
    [ "$lines" -le 200 ]
}

# ─── phase-a-setup.md references rules, not duplicates ───

@test "phase-a-setup references pm-behaviors auto-load" {
    run grep -iE "pm-behaviors|auto-load|rules.*pm" "$FORGE_DIR/commands/forge-phases/phase-a-setup.md"
    assert_success
}

@test "phase-a-setup does NOT have duplicated anti-patterns" {
    # The detailed anti-pattern list should be in rules, not phase file
    run grep -c "NEVER write application code" "$FORGE_DIR/commands/forge-phases/phase-a-setup.md"
    # Should be 0 or 1 (brief reference OK, detailed list should be in rules)
    [[ "$output" -le 1 ]]
}

# ─── pm-orchestrator.md references rules file ───

@test "pm-orchestrator references pm-behaviors rules" {
    run grep -iE "pm-behaviors|rules.*pm|auto-load.*behaviors" "$FORGE_DIR/agents/universal/pm-orchestrator.md"
    assert_success
}
