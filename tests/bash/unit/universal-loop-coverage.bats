#!/usr/bin/env bats
# Tests for universal loop coverage — must apply to ALL steps (agent + command)
# Related: #196, #197

setup() {
    load '../../test_helper/common-setup'
    _common_setup
    FORGE_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
    export FORGE_DIR
    LOOP="$FORGE_DIR/rules/universal-agent-loop.md"
    HOOKS="$FORGE_DIR/templates/hooks.json"
    PRECOMMIT="$FORGE_DIR/templates/pre-commit"
    README="$FORGE_DIR/README.md"
}

teardown() {
    _common_teardown
}

# ─── UNIVERSAL LOOP SCOPE ───

@test "Universal loop says 'every step' not just 'every agent spawn'" {
    run grep -i "every step" "$LOOP"
    assert_success
}

@test "Universal loop covers agent OR command" {
    run grep -i "agent OR.*command\|command.*OR.*agent\|agent spawn OR.*command\|spawn agent OR run command" "$LOOP"
    assert_success
}

@test "Universal loop does NOT say 'agent only'" {
    # Should not limit to agents only
    run grep -i "agent spawn MUST follow\|Every agent spawn MUST" "$LOOP"
    assert_failure
}

# ─── HOOKS COVERAGE ───

@test "Skill PostToolUse hook has handoff check" {
    # Extract the Skill hook command and check for handoff
    run grep -A5 '"matcher": "Skill"' "$HOOKS"
    assert_success
    echo "$output" | grep -q "forge-handoff-check"
}

@test "Agent PostToolUse hook has handoff check" {
    run grep -A5 '"matcher": "Agent"' "$HOOKS"
    assert_success
    echo "$output" | grep -q "forge-handoff-check"
}

@test "Both Agent and Skill hooks run handoff check" {
    # Count how many PostToolUse hooks reference forge-handoff-check
    run grep -c "forge-handoff-check" "$HOOKS"
    assert_success
    [ "$output" -ge 2 ]
}

# ─── PRE-COMMIT AUTO-TEST ───

@test "Pre-commit hook runs unit tests" {
    run grep "test-fast" "$PRECOMMIT"
    assert_success
}

@test "Pre-commit hook blocks on test failure" {
    run grep "BLOCKED.*test.*fail\|tests failed.*Fix" "$PRECOMMIT"
    assert_success
}

@test "Pre-commit does NOT run integration tests (too slow)" {
    run grep "test-slow" "$PRECOMMIT"
    assert_failure
}

# ─── README ACCURACY ───

@test "README shows universal execution loop in main flow" {
    run grep -i "Universal Execution Loop\|MEASURE.*handoff\|reviewer.*rate" "$README"
    assert_success
}

@test "README shows handoff check for both Agent and Skill hooks" {
    run grep "handoff check" "$README"
    assert_success
    # Should appear for both Agent and Skill rows
    local count
    count=$(grep -c "handoff check" "$README")
    [ "$count" -ge 2 ]
}

# ─── HOOKS JSON STRUCTURE ───

@test "hooks.json is valid JSON" {
    run python3 -c "import json; json.load(open('$HOOKS'))"
    assert_success
}

@test "hooks.json has all 5 event types" {
    for event in SessionStart Stop UserPromptSubmit PreToolUse PostToolUse; do
        run grep "\"$event\"" "$HOOKS"
        assert_success
    done
}

@test "hooks.json PostToolUse has 4 matchers" {
    # Write|Edit, Agent, Skill, Bash
    for matcher in "Write|Edit" "Agent" "Skill" "Bash"; do
        run grep "\"matcher\": \"$matcher\"" "$HOOKS"
        assert_success
    done
}
