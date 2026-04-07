#!/usr/bin/env bats
# Tests for forge-handoff-targets.sh — maps step to expected output artifacts
# Related: #200

setup() {
    load '../../test_helper/common-setup'
    _common_setup
    FORGE_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
    export FORGE_DIR
    SCRIPT="$FORGE_DIR/scripts/forge-handoff-targets.sh"
    TEST_DIR=$(mktemp -d)
    mkdir -p "$TEST_DIR/docs"
}

teardown() {
    _common_teardown
    rm -rf "$TEST_DIR"
}

# ─── SCRIPT EXISTS ───

@test "forge-handoff-targets.sh exists and is executable" {
    assert [ -f "$SCRIPT" ]
    assert [ -x "$SCRIPT" ]
}

# ─── SKILL TARGETS ───

@test "handoff-targets maps /discover to trace output" {
    echo '{"current_step": 1}' > "$TEST_DIR/docs/forge-state.json"
    echo "10:00:00 SKILL discover" > "$TEST_DIR/docs/.builder-activity.log"
    run "$SCRIPT" "$TEST_DIR"
    assert_success
    assert_output --partial "discover"
}

@test "handoff-targets maps /requirements to SPEC.md" {
    echo '{"current_step": 2}' > "$TEST_DIR/docs/forge-state.json"
    echo "10:00:00 SKILL requirements" > "$TEST_DIR/docs/.builder-activity.log"
    run "$SCRIPT" "$TEST_DIR"
    assert_success
    assert_output --partial "SPEC.md"
}

@test "handoff-targets maps /generate-spec to SPEC.md" {
    echo '{"current_step": 4}' > "$TEST_DIR/docs/forge-state.json"
    echo "10:00:00 SKILL generate-spec" > "$TEST_DIR/docs/.builder-activity.log"
    run "$SCRIPT" "$TEST_DIR"
    assert_success
    assert_output --partial "SPEC.md"
}

# ─── AGENT TARGETS ───

@test "handoff-targets maps system-architect to CLAUDE.md" {
    echo '{"current_step": 3}' > "$TEST_DIR/docs/forge-state.json"
    echo "10:00:00 AGENT system-architect" > "$TEST_DIR/docs/.builder-activity.log"
    run "$SCRIPT" "$TEST_DIR"
    assert_success
    assert_output --partial "CLAUDE.md"
}

@test "handoff-targets maps requirements-analyst to SPEC.md" {
    echo '{"current_step": 4}' > "$TEST_DIR/docs/forge-state.json"
    echo "10:00:00 AGENT requirements-analyst" > "$TEST_DIR/docs/.builder-activity.log"
    run "$SCRIPT" "$TEST_DIR"
    assert_success
    assert_output --partial "SPEC.md"
}

@test "handoff-targets maps devops-architect to Dockerfile" {
    echo '{"current_step": 7}' > "$TEST_DIR/docs/forge-state.json"
    echo "10:00:00 AGENT devops-architect" > "$TEST_DIR/docs/.builder-activity.log"
    run "$SCRIPT" "$TEST_DIR"
    assert_success
    assert_output --partial "Dockerfile"
}

# ─── SKIP TARGETS ───

@test "handoff-targets skips reviewer (exit 1)" {
    echo '{"current_step": 9}' > "$TEST_DIR/docs/forge-state.json"
    echo "10:00:00 AGENT reviewer" > "$TEST_DIR/docs/.builder-activity.log"
    run "$SCRIPT" "$TEST_DIR"
    [ "$status" -eq 1 ]
}

@test "handoff-targets skips gate (exit 1)" {
    echo '{"current_step": 8}' > "$TEST_DIR/docs/forge-state.json"
    echo "10:00:00 SKILL gate" > "$TEST_DIR/docs/.builder-activity.log"
    run "$SCRIPT" "$TEST_DIR"
    [ "$status" -eq 1 ]
}

@test "handoff-targets skips /cr (exit 1)" {
    echo '{"current_step": 10}' > "$TEST_DIR/docs/forge-state.json"
    echo "10:00:00 SKILL cr" > "$TEST_DIR/docs/.builder-activity.log"
    run "$SCRIPT" "$TEST_DIR"
    [ "$status" -eq 1 ]
}

@test "handoff-targets skips checkpoint (exit 1)" {
    echo '{"current_step": 7}' > "$TEST_DIR/docs/forge-state.json"
    echo "10:00:00 SKILL checkpoint" > "$TEST_DIR/docs/.builder-activity.log"
    run "$SCRIPT" "$TEST_DIR"
    [ "$status" -eq 1 ]
}

# ─── NO STATE ───

@test "handoff-targets exits 1 when no state and no log" {
    local EMPTY_DIR=$(mktemp -d)
    run "$SCRIPT" "$EMPTY_DIR"
    [ "$status" -eq 1 ]
    rm -rf "$EMPTY_DIR"
}
