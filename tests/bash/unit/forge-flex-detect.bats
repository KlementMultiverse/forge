#!/usr/bin/env bats
# Tests for forge-flex-detect.sh — FLEX_SIGNAL detection in agent output
# Related: #202, CR plan Phase 2 Task 2.1
# Exit codes: 0=signal found, 1=no signal, 2=file missing, 3=malformed signal

setup() {
    load '../../test_helper/common-setup'
    _common_setup
    FORGE_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
    export FORGE_DIR
    SCRIPT="$FORGE_DIR/scripts/forge-flex-detect.sh"
    TEST_DIR=$(mktemp -d)
}

teardown() {
    _common_teardown
    rm -rf "$TEST_DIR"
}

# ─── SCRIPT EXISTS ───

@test "forge-flex-detect.sh exists and is executable" {
    assert [ -f "$SCRIPT" ]
    assert [ -x "$SCRIPT" ]
}

@test "forge-flex-detect.sh has help" {
    run "$SCRIPT" --help
    assert_success
    assert_output --partial "Usage"
}

# ─── SIGNAL DETECTION ───

@test "detects FLEX_SIGNAL in output file" {
    cat > "$TEST_DIR/output.md" <<'SIGNAL'
Some agent output here.

## FLEX_SIGNAL
TYPE: AMEND_RULES
TARGET: CLAUDE.md
STEP: S3
WHAT: Rule contradicts FastAPI choice
WHY: CLAUDE.md says "use Django Ninja" but stack is FastAPI
PROPOSED: Remove Django Ninja reference
SEVERITY: BLOCKING
SIGNAL
    run "$SCRIPT" "$TEST_DIR/output.md"
    assert_success
    assert_output --partial "AMEND_RULES"
    assert_output --partial "BLOCKING"
}

@test "returns exit 1 when no FLEX_SIGNAL present" {
    echo "Clean agent output, no issues found." > "$TEST_DIR/output.md"
    run "$SCRIPT" "$TEST_DIR/output.md"
    [ "$status" -eq 1 ]
}

@test "returns exit 2 on missing file" {
    run "$SCRIPT" "$TEST_DIR/nonexistent.md"
    [ "$status" -eq 2 ]
}

# ─── ALL SIGNAL TYPES ───

@test "detects all 10 TYPE values" {
    for type in AMEND_RULES UPDATE_SPEC FIX_DESIGN FIX_ROUTING FIX_SCAFFOLD ADD_SECURITY SPAWN_AGENT UPDATE_TESTS LOOP_BACK DEEP_REVIEW; do
        cat > "$TEST_DIR/output.md" <<SIGNAL
## FLEX_SIGNAL
TYPE: $type
TARGET: test.md
STEP: N0
WHAT: test
WHY: test
PROPOSED: test
SEVERITY: INFO
SIGNAL
        run "$SCRIPT" "$TEST_DIR/output.md"
        assert_success
        assert_output --partial "$type"
    done
}

# ─── SEVERITY LEVELS ───

@test "detects INFO severity" {
    cat > "$TEST_DIR/output.md" <<'SIGNAL'
## FLEX_SIGNAL
TYPE: AMEND_RULES
TARGET: CLAUDE.md
STEP: N4
WHAT: Minor style inconsistency
WHY: Not critical
PROPOSED: Adjust later
SEVERITY: INFO
SIGNAL
    run "$SCRIPT" "$TEST_DIR/output.md"
    assert_success
    assert_output --partial "INFO"
}

@test "detects ADVISORY severity" {
    cat > "$TEST_DIR/output.md" <<'SIGNAL'
## FLEX_SIGNAL
TYPE: UPDATE_SPEC
TARGET: SPEC.md
STEP: N3
WHAT: Missing edge case
WHY: Test revealed gap
PROPOSED: Add REQ
SEVERITY: ADVISORY
SIGNAL
    run "$SCRIPT" "$TEST_DIR/output.md"
    assert_success
    assert_output --partial "ADVISORY"
}

@test "detects BLOCKING severity" {
    cat > "$TEST_DIR/output.md" <<'SIGNAL'
## FLEX_SIGNAL
TYPE: FIX_DESIGN
TARGET: docs/design-doc.md
STEP: N0
WHAT: API contract wrong
WHY: Endpoint returns 404
PROPOSED: Fix contract
SEVERITY: BLOCKING
SIGNAL
    run "$SCRIPT" "$TEST_DIR/output.md"
    assert_success
    assert_output --partial "BLOCKING"
}

# ─── JSON OUTPUT ───

@test "supports --json flag with valid JSON" {
    cat > "$TEST_DIR/output.md" <<'SIGNAL'
## FLEX_SIGNAL
TYPE: AMEND_RULES
TARGET: CLAUDE.md
STEP: S3
WHAT: Rule conflict
WHY: Evidence here
PROPOSED: Fix it
SEVERITY: BLOCKING
SIGNAL
    run "$SCRIPT" --json "$TEST_DIR/output.md"
    assert_success
    echo "$output" | python3 -c "import json,sys; json.load(sys.stdin)"
}

@test "--json output contains all required FLEX_SIGNAL fields" {
    cat > "$TEST_DIR/output.md" <<'SIGNAL'
## FLEX_SIGNAL
TYPE: AMEND_RULES
TARGET: CLAUDE.md
STEP: S3
WHAT: Rule conflict
WHY: Evidence here
PROPOSED: Fix it
SEVERITY: BLOCKING
SIGNAL
    run "$SCRIPT" --json "$TEST_DIR/output.md"
    assert_success
    echo "$output" | python3 -c "
import json, sys
data = json.load(sys.stdin)
sigs = data if isinstance(data, list) else [data]
required = {'type','target','severity','step','what','why','proposed'}
for s in sigs:
    missing = required - set(k.lower() for k in s.keys())
    assert not missing, f'Missing fields: {missing}'
"
}

@test "--json with multiple signals returns a JSON array" {
    cat > "$TEST_DIR/output.md" <<'SIGNAL'
## FLEX_SIGNAL
TYPE: AMEND_RULES
TARGET: CLAUDE.md
STEP: S3
WHAT: A
WHY: B
PROPOSED: C
SEVERITY: BLOCKING

## FLEX_SIGNAL
TYPE: UPDATE_SPEC
TARGET: SPEC.md
STEP: S4
WHAT: D
WHY: E
PROPOSED: F
SEVERITY: ADVISORY
SIGNAL
    run "$SCRIPT" --json "$TEST_DIR/output.md"
    assert_success
    echo "$output" | python3 -c "import json,sys; d=json.load(sys.stdin); assert isinstance(d,list) and len(d)==2, f'Expected list of 2, got {type(d)} len {len(d) if isinstance(d,list) else \"N/A\"}'"
}

# ─── SEVERITY FILTER ───

@test "supports --severity-filter single value" {
    cat > "$TEST_DIR/output.md" <<'SIGNAL'
## FLEX_SIGNAL
TYPE: AMEND_RULES
TARGET: CLAUDE.md
STEP: S3
WHAT: Rule conflict
WHY: Evidence
PROPOSED: Fix
SEVERITY: INFO
SIGNAL
    run "$SCRIPT" --severity-filter BLOCKING "$TEST_DIR/output.md"
    # INFO signal filtered out when asking for BLOCKING only
    [ "$status" -eq 1 ]
}

@test "severity-filter BLOCKING,ADVISORY includes both, filters INFO" {
    cat > "$TEST_DIR/output.md" <<'SIGNAL'
## FLEX_SIGNAL
TYPE: AMEND_RULES
TARGET: CLAUDE.md
STEP: S3
WHAT: Info thing
WHY: Not important
PROPOSED: Skip
SEVERITY: INFO

## FLEX_SIGNAL
TYPE: UPDATE_SPEC
TARGET: SPEC.md
STEP: S4
WHAT: Advisory thing
WHY: Should review
PROPOSED: Check
SEVERITY: ADVISORY
SIGNAL
    run "$SCRIPT" --severity-filter BLOCKING,ADVISORY "$TEST_DIR/output.md"
    assert_success
    assert_output --partial "ADVISORY"
    refute_output --partial "INFO"
}

# ─── MULTIPLE SIGNALS ───

@test "detects multiple FLEX_SIGNALs in one output" {
    cat > "$TEST_DIR/output.md" <<'SIGNAL'
Agent output here.

## FLEX_SIGNAL
TYPE: AMEND_RULES
TARGET: CLAUDE.md
STEP: S3
WHAT: Rule 1 wrong
WHY: Evidence 1
PROPOSED: Fix 1
SEVERITY: BLOCKING

More output.

## FLEX_SIGNAL
TYPE: UPDATE_SPEC
TARGET: SPEC.md
STEP: S4
WHAT: Missing REQ
WHY: Evidence 2
PROPOSED: Add REQ
SEVERITY: ADVISORY
SIGNAL
    run "$SCRIPT" "$TEST_DIR/output.md"
    assert_success
    assert_output --partial "AMEND_RULES"
    assert_output --partial "UPDATE_SPEC"
}

# ─── MALFORMED SIGNALS ───

@test "malformed signal returns exit 3" {
    cat > "$TEST_DIR/output.md" <<'SIGNAL'
## FLEX_SIGNAL
TYPE: AMEND_RULES
TARGET:
SEVERITY:
SIGNAL
    run "$SCRIPT" "$TEST_DIR/output.md"
    # Exit 3 = signal found but malformed (missing required fields)
    [ "$status" -eq 3 ]
    assert_output --partial "AMEND_RULES"
}

# ─── STDIN / PIPE SUPPORT ───

@test "reads from stdin when no file argument" {
    cat > "$TEST_DIR/output.md" <<'SIGNAL'
## FLEX_SIGNAL
TYPE: ADD_SECURITY
TARGET: CLAUDE.md
STEP: N7
WHAT: New pattern
WHY: Found in scan
PROPOSED: Add rule
SEVERITY: ADVISORY
SIGNAL
    run bash -c "cat '$TEST_DIR/output.md' | '$SCRIPT' -"
    assert_success
    assert_output --partial "ADD_SECURITY"
}

# ─── PERSISTENCE ───

@test "ADVISORY signal writes to docs/flex-signals.log" {
    mkdir -p "$TEST_DIR/docs"
    cat > "$TEST_DIR/output.md" <<'SIGNAL'
## FLEX_SIGNAL
TYPE: UPDATE_SPEC
TARGET: SPEC.md
STEP: N3
WHAT: Gap found
WHY: Evidence
PROPOSED: Add REQ
SEVERITY: ADVISORY
SIGNAL
    FORGE_DIR="$TEST_DIR" run "$SCRIPT" "$TEST_DIR/output.md"
    assert_success
    assert [ -f "$TEST_DIR/docs/flex-signals.log" ]
    run grep "ADVISORY" "$TEST_DIR/docs/flex-signals.log"
    assert_success
}

@test "BLOCKING signal writes to docs/flex-signals.log as UNRESOLVED" {
    mkdir -p "$TEST_DIR/docs"
    cat > "$TEST_DIR/output.md" <<'SIGNAL'
## FLEX_SIGNAL
TYPE: FIX_DESIGN
TARGET: docs/design-doc.md
STEP: N0
WHAT: Bad contract
WHY: Evidence
PROPOSED: Fix
SEVERITY: BLOCKING
SIGNAL
    FORGE_DIR="$TEST_DIR" run "$SCRIPT" "$TEST_DIR/output.md"
    assert_success
    run grep "UNRESOLVED" "$TEST_DIR/docs/flex-signals.log"
    assert_success
}

@test "INFO signal does NOT write to docs/flex-signals.log" {
    mkdir -p "$TEST_DIR/docs"
    cat > "$TEST_DIR/output.md" <<'SIGNAL'
## FLEX_SIGNAL
TYPE: AMEND_RULES
TARGET: CLAUDE.md
STEP: N4
WHAT: Style
WHY: Minor
PROPOSED: Adjust
SEVERITY: INFO
SIGNAL
    FORGE_DIR="$TEST_DIR" run "$SCRIPT" "$TEST_DIR/output.md"
    assert_success
    if [ -f "$TEST_DIR/docs/flex-signals.log" ]; then
        run grep "INFO" "$TEST_DIR/docs/flex-signals.log"
        assert_failure
    fi
}

# ─── HOOKS WIRING ───

@test "hooks.json has FLEX_SIGNAL detection in hooks" {
    run grep -E "FLEX_SIGNAL|forge-flex-detect" "$FORGE_DIR/templates/hooks.json"
    assert_success
}

@test "hooks use CLAUDE_TOOL_RESULT for FLEX_SIGNAL detection" {
    run grep "CLAUDE_TOOL_RESULT" "$FORGE_DIR/templates/hooks.json"
    assert_success
}

@test "Stop hook checks for unresolved BLOCKING signals in forge-state.json" {
    run grep "flex_checkpoints" "$FORGE_DIR/templates/hooks.json"
    assert_success
}

# ─── DESIGN RULES IN LOOP FILE ───

@test "universal-agent-loop.md has 13 steps" {
    run grep -E "^[0-9]+\." "$FORGE_DIR/rules/universal-agent-loop.md"
    assert_success
    run grep "13\\. PROCEED" "$FORGE_DIR/rules/universal-agent-loop.md"
    assert_success
}

@test "step 11 is FLEX CHECKPOINT" {
    run grep "11\\. FLEX CHECKPOINT" "$FORGE_DIR/rules/universal-agent-loop.md"
    assert_success
}

@test "FLEX_SIGNAL format defined in loop file" {
    run grep "## FLEX_SIGNAL" "$FORGE_DIR/rules/universal-agent-loop.md"
    assert_success
}

@test "decision authority table has all 10 types" {
    for type in AMEND_RULES UPDATE_SPEC FIX_DESIGN FIX_ROUTING FIX_SCAFFOLD ADD_SECURITY SPAWN_AGENT UPDATE_TESTS LOOP_BACK DEEP_REVIEW; do
        run grep "$type" "$FORGE_DIR/rules/universal-agent-loop.md"
        assert_success
    done
}

@test "safety limits defined" {
    run grep -E "5.*per signal|10.*per step|30.*per phase" "$FORGE_DIR/rules/universal-agent-loop.md"
    assert_success
}

@test "Gate 3 is FLAT (no recursive step 11)" {
    run grep -Ei "FLAT.*loop|NO recursive" "$FORGE_DIR/rules/universal-agent-loop.md"
    assert_success
}

@test "signal identity is TYPE + TARGET" {
    run grep -E "Signal identity.*TYPE.*TARGET|identity.*TYPE.*TARGET" "$FORGE_DIR/rules/universal-agent-loop.md"
    assert_success
}
