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
    run grep -Ei "agent OR.*command|command.*OR.*agent|agent spawn OR.*command|spawn agent OR run command" "$LOOP"
    assert_success
}

@test "Universal loop does NOT say 'agent only'" {
    # Should not limit to agents only
    run grep -Ei "agent spawn MUST follow|Every agent spawn MUST" "$LOOP"
    assert_failure
}

# ─── HOOKS COVERAGE ───

@test "Skill PostToolUse hook has handoff check" {
    run grep -A5 '"matcher": "Skill"' "$HOOKS"
    assert_success
    assert_output --partial "forge-handoff-check"
}

@test "Agent PostToolUse hook has handoff check" {
    run grep -A5 '"matcher": "Agent"' "$HOOKS"
    assert_success
    assert_output --partial "forge-handoff-check"
}

@test "Both Agent and Skill hooks run handoff check" {
    # Count how many PostToolUse hooks reference forge-handoff-check
    run grep -c "forge-handoff-check" "$HOOKS"
    assert_success
    [ "$output" -ge 2 ]
}

# ─── PRE-COMMIT AUTO-TEST ───

@test "Pre-commit hook runs unit tests" {
    run grep -E "make.*test-fast" "$PRECOMMIT"
    assert_success
}

@test "Pre-commit hook blocks on test failure" {
    run grep -E "BLOCKED.*test.*fail|tests failed.*Fix" "$PRECOMMIT"
    assert_success
}

@test "Pre-commit does NOT run integration tests (too slow)" {
    run grep -E "test-slow|tests/bash/integration" "$PRECOMMIT"
    assert_failure
}

# ─── README ACCURACY ───

@test "README shows universal execution loop in main flow" {
    run grep -Ei "Universal Execution Loop|MEASURE.*handoff|reviewer.*rate" "$README"
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

# ─── BASH HOOK CR DETECTION ───

@test "Bash PostToolUse hook detects git push" {
    run grep "git push" "$HOOKS"
    assert_success
}

@test "Bash PostToolUse hook mentions /cr review" {
    run grep -E "/cr review" "$HOOKS"
    assert_success
}

# ─── GATE CR INTEGRATION ───

@test "Gate command requires /cr approve" {
    run grep "/cr approve" "$FORGE_DIR/commands/gate.md"
    assert_success
}

@test "Gate blocks without CR approval" {
    run grep -E "GATE BLOCKS without CR|NON-NEGOTIABLE" "$FORGE_DIR/commands/gate.md"
    assert_success
}

# ─── MECHANICAL ENFORCEMENT ───

@test "Stop hook runs forge-step-gate.sh" {
    run grep "forge-step-gate" "$HOOKS"
    assert_success
}

@test "Agent hook has reviewer reminder" {
    run grep "REMINDER.*reviewer" "$HOOKS"
    assert_success
}

@test "Skill hook has reviewer reminder" {
    run grep -A10 '"matcher": "Skill"' "$HOOKS"
    assert_success
    assert_output --partial "REMINDER"
}

@test "Agent hook uses forge-handoff-targets.sh" {
    run grep "forge-handoff-targets" "$HOOKS"
    assert_success
}

@test "Both Agent and Skill hooks use forge-handoff-targets.sh" {
    run grep -c "forge-handoff-targets" "$HOOKS"
    assert_success
    [ "$output" -ge 2 ]
}

# ─── FLEX CHECKPOINT ───

@test "Universal loop has 13 steps" {
    run grep "13\\. PROCEED" "$LOOP"
    assert_success
}

@test "Step 11 is FLEX CHECKPOINT" {
    run grep "11\\. FLEX CHECKPOINT" "$LOOP"
    assert_success
}

@test "Agent hook has FLEX_SIGNAL detection" {
    run grep -A20 '"matcher": "Agent"' "$HOOKS"
    assert_success
    assert_output --partial "forge-flex-detect"
}

@test "Skill hook has FLEX_SIGNAL detection" {
    run grep -A20 '"matcher": "Skill"' "$HOOKS"
    assert_success
    assert_output --partial "forge-flex-detect"
}

# ─── SCRIPTS EXIST ───

@test "forge-step-gate.sh exists and is executable" {
    assert [ -f "$FORGE_DIR/scripts/forge-step-gate.sh" ]
    assert [ -x "$FORGE_DIR/scripts/forge-step-gate.sh" ]
}

@test "forge-handoff-targets.sh exists and is executable" {
    assert [ -f "$FORGE_DIR/scripts/forge-handoff-targets.sh" ]
    assert [ -x "$FORGE_DIR/scripts/forge-handoff-targets.sh" ]
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
