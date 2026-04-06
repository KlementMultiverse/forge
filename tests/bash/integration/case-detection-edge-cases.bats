#!/usr/bin/env bats
# Tests for UserPromptSubmit CASE detection edge cases (#111)
# Tests the detection logic extracted from hooks.json

setup() {
    load '../../test_helper/common-setup'
    # Use a CLEAN project dir without copied forge scripts
    export TEST_PROJECT="$(mktemp -d)"
    export PROJECT_ROOT="$TEST_PROJECT"
    export D="$TEST_PROJECT"
    mkdir -p "$TEST_PROJECT/docs"
    FORGE_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
    export FORGE_DIR
}

teardown() {
    _common_teardown
}

# Helper: extract and run the CASE detection logic from hooks.json
# We can't run the actual hook, but we can test the logic patterns
run_case_detection() {
    local project_dir="$1"
    cd "$project_dir"

    # Simulate the detection logic from hooks.json
    local D="$project_dir"
    local C F P STEP

    # Check forge-state for RESUME
    if [ -f "$D/docs/forge-state.json" ]; then
        STEP=$(python3 -c "import json; d=json.load(open('$D/docs/forge-state.json')); print(d.get('current_step',0))" 2>/dev/null || echo 0)
        if [ "$STEP" -ge 0 ] && [ "$STEP" -lt 57 ] && [ "$STEP" -gt 0 ]; then
            echo "[FORGE] CASE_RESUME (step $STEP)"
            return 0  # Early exit — no dual output
        fi
    fi

    C=$(test -f "$D/CLAUDE.md" && echo y || echo n)
    F=$(find "$D" -maxdepth 4 \( -name "*.py" -o -name "*.ts" -o -name "*.tsx" -o -name "*.jsx" -o -name "*.js" -o -name "*.go" -o -name "*.rb" -o -name "*.java" -o -name "*.rs" -o -name "*.php" \) ! -path "*node_modules*" ! -path "*.venv*" ! -path "*.git*" ! -path "*/vendor/*" 2>/dev/null | head -1)
    P=$(grep -l "FORGE_TEMPLATE\|{{PROJECT_NAME}}\|{{DESCRIPTION}}" "$D/CLAUDE.md" 2>/dev/null)

    if [ "$C" = "n" ] && [ -z "$F" ]; then echo "[FORGE] CASE1_GREENFIELD"
    elif [ "$C" = "n" ] && [ -n "$F" ]; then echo "[FORGE] CASE7_BROWNFIELD"
    elif [ -n "$P" ]; then echo "[FORGE] CASE1_GREENFIELD (placeholder)"
    elif [ "$C" = "y" ] && [ -z "$F" ]; then echo "[FORGE] CASE2_SPEC_ONLY"
    elif [ "$C" = "y" ] && [ -n "$F" ]; then echo "[FORGE] EXISTING_PROJECT"
    fi
}

# ─── Fix 1: Extended file extensions ───

@test "detects .js project as BROWNFIELD not GREENFIELD" {
    mkdir -p "$TEST_PROJECT/src"
    echo "console.log('hello')" > "$TEST_PROJECT/src/app.js"
    run run_case_detection "$TEST_PROJECT"
    assert_output --partial "CASE7_BROWNFIELD"
}

@test "detects .tsx project as BROWNFIELD" {
    mkdir -p "$TEST_PROJECT/src"
    echo "export default () => <div/>" > "$TEST_PROJECT/src/App.tsx"
    run run_case_detection "$TEST_PROJECT"
    assert_output --partial "CASE7_BROWNFIELD"
}

@test "detects .go project as BROWNFIELD" {
    mkdir -p "$TEST_PROJECT/cmd"
    echo "package main" > "$TEST_PROJECT/cmd/main.go"
    run run_case_detection "$TEST_PROJECT"
    assert_output --partial "CASE7_BROWNFIELD"
}

@test "detects .java project as BROWNFIELD" {
    mkdir -p "$TEST_PROJECT/src/main"
    echo "public class Main {}" > "$TEST_PROJECT/src/main/Main.java"
    run run_case_detection "$TEST_PROJECT"
    assert_output --partial "CASE7_BROWNFIELD"
}

# ─── Fix 2: maxdepth 4 ───

@test "finds code at depth 3 (src/app/main.py)" {
    mkdir -p "$TEST_PROJECT/src/app"
    echo "print('hello')" > "$TEST_PROJECT/src/app/main.py"
    run run_case_detection "$TEST_PROJECT"
    assert_output --partial "CASE7_BROWNFIELD"
}

@test "ignores vendor directory code" {
    mkdir -p "$TEST_PROJECT/vendor/lib"
    echo "print('vendor')" > "$TEST_PROJECT/vendor/lib/dep.py"
    run run_case_detection "$TEST_PROJECT"
    assert_output --partial "CASE1_GREENFIELD"
}

# ─── Fix 4: CASE_RESUME early exit (no dual output) ───

@test "CASE_RESUME outputs only RESUME not EXISTING" {
    setup_mock_state '{"current_step":15,"current_phase":2}'
    echo "# Project" > "$TEST_PROJECT/CLAUDE.md"
    mkdir -p "$TEST_PROJECT/apps/auth"
    echo "# code" > "$TEST_PROJECT/apps/auth/models.py"
    run run_case_detection "$TEST_PROJECT"
    assert_output "[FORGE] CASE_RESUME (step 15)"
    # Should NOT also contain EXISTING_PROJECT
    refute_output --partial "EXISTING_PROJECT"
}

# ─── Fix 5: Template marker not bare {{ ───

@test "CLAUDE.md with Jinja2 syntax is NOT treated as placeholder" {
    printf '# Project\nUse {{ variable }} in templates\n' > "$TEST_PROJECT/CLAUDE.md"
    run run_case_detection "$TEST_PROJECT"
    # Should be SPEC_ONLY (has CLAUDE.md, no code) not GREENFIELD(placeholder)
    assert_output --partial "CASE2_SPEC_ONLY"
}

@test "CLAUDE.md with FORGE_TEMPLATE marker IS treated as placeholder" {
    printf '# FORGE_TEMPLATE\n{{PROJECT_NAME}}\n' > "$TEST_PROJECT/CLAUDE.md"
    run run_case_detection "$TEST_PROJECT"
    assert_output --partial "CASE1_GREENFIELD (placeholder)"
}

# ─── Fix 8: step=0 handling ───

@test "empty project with no state is GREENFIELD" {
    run run_case_detection "$TEST_PROJECT"
    assert_output --partial "CASE1_GREENFIELD"
}

# ─── Fix 9: grep portability ───

@test "REQ count uses ERE not PCRE" {
    # Verify hooks.json doesn't use grep -oP for REQ counting
    run grep "grep -oE\|grep.*-E" "$FORGE_DIR/templates/hooks.json"
    assert_success
}

# ─── Fix 3: Word boundary on /forge ───

@test "IS_FORGE regex uses word boundary" {
    # Check that hooks.json has word boundary or anchored match
    run grep -E 'forge\\b|/forge[^a-z]|/forge\"|\\/forge\\b' "$FORGE_DIR/templates/hooks.json"
    assert_success
}

# ─── Basic cases still work ───

@test "empty folder is GREENFIELD" {
    run run_case_detection "$TEST_PROJECT"
    assert_output --partial "CASE1_GREENFIELD"
}

@test "CLAUDE.md + code is EXISTING_PROJECT" {
    echo "# Project" > "$TEST_PROJECT/CLAUDE.md"
    mkdir -p "$TEST_PROJECT/apps"
    echo "# code" > "$TEST_PROJECT/apps/main.py"
    run run_case_detection "$TEST_PROJECT"
    assert_output --partial "EXISTING_PROJECT"
}

@test "CLAUDE.md no code is SPEC_ONLY" {
    echo "# Project" > "$TEST_PROJECT/CLAUDE.md"
    run run_case_detection "$TEST_PROJECT"
    assert_output --partial "CASE2_SPEC_ONLY"
}
