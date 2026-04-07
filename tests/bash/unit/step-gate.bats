#!/usr/bin/env bats
# Tests for forge-step-gate.sh — blocks if reviewer/trace missing
# Related: #200

setup() {
    load '../../test_helper/common-setup'
    _common_setup
    FORGE_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
    export FORGE_DIR
    SCRIPT="$FORGE_DIR/scripts/forge-step-gate.sh"
    TEST_DIR=$(mktemp -d)
    mkdir -p "$TEST_DIR/docs"
}

teardown() {
    _common_teardown
    rm -rf "$TEST_DIR"
}

# ─── SCRIPT EXISTS ───

@test "forge-step-gate.sh exists and is executable" {
    assert [ -f "$SCRIPT" ]
    assert [ -x "$SCRIPT" ]
}

@test "forge-step-gate.sh has help" {
    run "$SCRIPT" --help
    assert_success
    assert_output --partial "Usage"
}

@test "forge-step-gate.sh check with no args uses PWD" {
    run "$SCRIPT" check "$TEST_DIR"
    # No state file = skip silently
    assert_success
}

# ─── REVIEWER GATE ───

@test "step-gate passes when reviewer ran after agent" {
    echo '{"current_step": 5}' > "$TEST_DIR/docs/forge-state.json"
    printf "10:00:00 AGENT system-architect\n10:05:00 AGENT reviewer\n" > "$TEST_DIR/docs/.builder-activity.log"
    run "$SCRIPT" check "$TEST_DIR"
    assert_success
}

@test "step-gate blocks when reviewer NOT run after agent" {
    echo '{"current_step": 5}' > "$TEST_DIR/docs/forge-state.json"
    printf "10:00:00 AGENT reviewer\n10:05:00 AGENT system-architect\n" > "$TEST_DIR/docs/.builder-activity.log"
    run "$SCRIPT" check "$TEST_DIR"
    assert_failure
    assert_output --partial "BLOCKED"
    assert_output --partial "reviewer"
}

@test "step-gate blocks when reviewer NEVER ran" {
    echo '{"current_step": 5}' > "$TEST_DIR/docs/forge-state.json"
    printf "10:00:00 AGENT system-architect\n10:05:00 SKILL discover\n" > "$TEST_DIR/docs/.builder-activity.log"
    run "$SCRIPT" check "$TEST_DIR"
    assert_failure
    assert_output --partial "BLOCKED"
    assert_output --partial "NEVER"
}

# ─── TRACE GATE ───

@test "step-gate passes when trace files complete" {
    echo '{"current_step": 5}' > "$TEST_DIR/docs/forge-state.json"
    printf "10:00:00 AGENT system-architect\n10:05:00 AGENT reviewer\n" > "$TEST_DIR/docs/.builder-activity.log"
    mkdir -p "$TEST_DIR/docs/forge-trace/005-step/"
    echo "input" > "$TEST_DIR/docs/forge-trace/005-step/input.md"
    echo "output" > "$TEST_DIR/docs/forge-trace/005-step/output.md"
    echo "meta" > "$TEST_DIR/docs/forge-trace/005-step/meta.md"
    run "$SCRIPT" check "$TEST_DIR"
    assert_success
}

@test "step-gate blocks when trace files missing" {
    echo '{"current_step": 5}' > "$TEST_DIR/docs/forge-state.json"
    printf "10:00:00 AGENT system-architect\n10:05:00 AGENT reviewer\n" > "$TEST_DIR/docs/.builder-activity.log"
    mkdir -p "$TEST_DIR/docs/forge-trace/005-step/"
    echo "input" > "$TEST_DIR/docs/forge-trace/005-step/input.md"
    # output.md and meta.md missing
    run "$SCRIPT" check "$TEST_DIR"
    [ "$status" -eq 2 ]
    assert_output --partial "BLOCKED"
    assert_output --partial "Trace file missing"
}

# ─── EDGE CASES ───

@test "step-gate passes when no forge project (no state file)" {
    run "$SCRIPT" check "$TEST_DIR"
    assert_success
}

@test "step-gate passes at step 0" {
    echo '{"current_step": 0}' > "$TEST_DIR/docs/forge-state.json"
    run "$SCRIPT" check "$TEST_DIR"
    assert_success
}

@test "step-gate exits 3 on invalid command" {
    run "$SCRIPT" invalid
    [ "$status" -eq 3 ]
}
