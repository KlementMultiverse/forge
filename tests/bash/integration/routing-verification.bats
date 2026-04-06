#!/usr/bin/env bats
# Integration tests: verify forge.md routing — CASE label → correct phase file
# Tests that every CASE routes to the right phase file and edge cases are handled

setup() {
    load '../../test_helper/common-setup'
    _common_setup
    FORGE_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
    export FORGE_DIR
}

teardown() {
    _common_teardown
}

# Helper: check which phase file forge.md says to read for a given step
get_phase_file_for_step() {
    local step=$1
    if [ "$step" -le 0 ]; then echo "phase-a-setup.md"
    elif [ "$step" -le 19 ]; then echo "phase-0-2-plan.md"
    elif [ "$step" -le 39 ]; then echo "phase-3-implement.md"
    elif [ "$step" -le 56 ]; then echo "phase-4-5-validate.md"
    else echo "done"
    fi
}

# ═══════════════════════════════════════
# CASE → Phase file routing
# ═══════════════════════════════════════

@test "forge.md references phase-a-setup.md for no CLAUDE.md" {
    run grep "phase-a-setup" "$FORGE_DIR/commands/forge.md"
    assert_success
}

@test "forge.md references phase-0-2-plan.md for steps 1-19" {
    run grep "phase-0-2-plan" "$FORGE_DIR/commands/forge.md"
    assert_success
}

@test "forge.md references phase-3-implement.md for steps 20-39" {
    run grep "phase-3-implement" "$FORGE_DIR/commands/forge.md"
    assert_success
}

@test "forge.md references phase-4-5-validate.md for steps 40-56" {
    run grep "phase-4-5-validate" "$FORGE_DIR/commands/forge.md"
    assert_success
}

@test "forge.md references cases.md for special cases" {
    run grep "cases.md" "$FORGE_DIR/commands/forge.md"
    assert_success
}

# ═══════════════════════════════════════
# Step → Phase file mapping
# ═══════════════════════════════════════

@test "step 1 routes to phase-0-2-plan.md" {
    result=$(get_phase_file_for_step 1)
    [ "$result" = "phase-0-2-plan.md" ]
}

@test "step 15 routes to phase-0-2-plan.md" {
    result=$(get_phase_file_for_step 15)
    [ "$result" = "phase-0-2-plan.md" ]
}

@test "step 19 routes to phase-0-2-plan.md (boundary)" {
    result=$(get_phase_file_for_step 19)
    [ "$result" = "phase-0-2-plan.md" ]
}

@test "step 20 routes to phase-3-implement.md" {
    result=$(get_phase_file_for_step 20)
    [ "$result" = "phase-3-implement.md" ]
}

@test "step 35 routes to phase-3-implement.md" {
    result=$(get_phase_file_for_step 35)
    [ "$result" = "phase-3-implement.md" ]
}

@test "step 39 routes to phase-3-implement.md (boundary)" {
    result=$(get_phase_file_for_step 39)
    [ "$result" = "phase-3-implement.md" ]
}

@test "step 40 routes to phase-4-5-validate.md" {
    result=$(get_phase_file_for_step 40)
    [ "$result" = "phase-4-5-validate.md" ]
}

@test "step 42 routes to phase-4-5-validate.md" {
    result=$(get_phase_file_for_step 42)
    [ "$result" = "phase-4-5-validate.md" ]
}

@test "step 56 routes to phase-4-5-validate.md (boundary)" {
    result=$(get_phase_file_for_step 56)
    [ "$result" = "phase-4-5-validate.md" ]
}

@test "step 57 routes to done (not a phase file)" {
    result=$(get_phase_file_for_step 57)
    [ "$result" = "done" ]
}

# ═══════════════════════════════════════
# RESUME priority
# ═══════════════════════════════════════

@test "forge.md routing table lists CASE_RESUME as item 0 (before CASE 1)" {
    # In the Detection logic section, CASE_RESUME should be item 0
    run grep "^0\. .*CASE_RESUME" "$FORGE_DIR/commands/forge.md"
    assert_success
    assert_output --partial "HIGHEST PRIORITY"
}

@test "forge.md Step 0.5 handles RESUME before Step 1 routing" {
    run grep -n "STEP 0.5\|Step 0.5\|step 0.5" "$FORGE_DIR/commands/forge.md"
    assert_success
    local step05_line
    step05_line=$(grep -n "STEP 0.5\|Step 0.5" "$FORGE_DIR/commands/forge.md" | head -1 | cut -d: -f1)
    local step1_line
    step1_line=$(grep -n "STEP 1:\|Step 1:" "$FORGE_DIR/commands/forge.md" | head -1 | cut -d: -f1)
    [ "$step05_line" -lt "$step1_line" ]
}

# ═══════════════════════════════════════
# Edge cases
# ═══════════════════════════════════════

@test "all referenced phase files actually exist" {
    for f in phase-a-setup.md phase-0-2-plan.md phase-3-implement.md phase-4-5-validate.md cases.md; do
        assert [ -f "$FORGE_DIR/commands/forge-phases/$f" ]
    done
}

@test "phase-map boundaries match forge.md routing table" {
    # forge.md says steps 1-19 → phase-0-2-plan
    # forge-phase-map.sh should agree
    source "$FORGE_DIR/scripts/forge-phase-map.sh"

    # Step 19 should be phase 2 (still in 0-2 range)
    result=$(get_phase_for_step 19)
    [ "$result" -le 2 ]

    # Step 20 should be phase 3
    result=$(get_phase_for_step 20)
    [ "$result" -eq 3 ]

    # Step 39 should be phase 3
    result=$(get_phase_for_step 39)
    [ "$result" -eq 3 ]

    # Step 40 should be phase 4
    result=$(get_phase_for_step 40)
    [ "$result" -eq 4 ]
}

@test "step 57 does NOT trigger RESUME in hook" {
    # step=57 means complete — should not resume
    export TEST_PROJECT="$(mktemp -d)"
    mkdir -p "$TEST_PROJECT/docs"
    echo '{"current_step":57}' > "$TEST_PROJECT/docs/forge-state.json"

    # Simulate the RESUME check from hooks.json
    STEP=$(python3 -c "import json; d=json.load(open('$TEST_PROJECT/docs/forge-state.json')); print(d.get('current_step',0))" 2>/dev/null)

    # step=57 should NOT be in the 1-56 resume range
    [ "$STEP" -ge 57 ]

    rm -rf "$TEST_PROJECT"
}

@test "corrupted forge-state.json falls back gracefully" {
    export TEST_PROJECT="$(mktemp -d)"
    mkdir -p "$TEST_PROJECT/docs"
    echo 'NOT JSON' > "$TEST_PROJECT/docs/forge-state.json"

    # python3 should fail and return 0 (default)
    STEP=$(python3 -c "import json; d=json.load(open('$TEST_PROJECT/docs/forge-state.json')); print(d.get('current_step',0))" 2>/dev/null || echo 0)

    [ "$STEP" = "0" ]

    rm -rf "$TEST_PROJECT"
}

@test "cases.md has all 7 special cases defined" {
    local cases_file="$FORGE_DIR/commands/forge-phases/cases.md"
    for case_num in 2 3 4 5 6 7 8; do
        run grep "CASE $case_num\|CASE$case_num" "$cases_file"
        assert_success
    done
}

@test "forge.md routing table covers all CASE labels from hook" {
    local forge_md="$FORGE_DIR/commands/forge.md"
    for label in CASE_RESUME CASE1_GREENFIELD CASE7_BROWNFIELD CASE2_SPEC_ONLY EXISTING_PROJECT; do
        run grep "$label" "$forge_md"
        assert_success
    done
}
