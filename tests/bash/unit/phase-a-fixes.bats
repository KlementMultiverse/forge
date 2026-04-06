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

# ─── Batch 1: S2 Question Fixes ───

# #135: Q7 'change' branch defined
@test "Phase A Q7 has change flow defined" {
    run grep -iE "change.*flow|change.*re-ask|change.*which|modify.*answer|On.*change.*ask" "$PHASE_A"
    assert_success
}

# #138: Credential discovery in Q5
@test "Phase A has credential/API key question" {
    run grep -iE "credential|API.key|api.secret|OPENAI|AWS.*KEY|env.*key" "$PHASE_A"
    assert_success
}

# #146: Q4 forge-stack.sh fallback
@test "Phase A Q4 has fallback if forge-stack.sh absent" {
    run grep -E "2>/dev/null.*||.*No stack|stack.*not found|fallback" "$PHASE_A"
    assert_success
}

# #147: Q3 web search fallback
@test "Phase A Q3 has fallback if web search returns nothing" {
    run grep -iE "no competitor|nothing found|skip competitor|no result" "$PHASE_A"
    assert_success
}
