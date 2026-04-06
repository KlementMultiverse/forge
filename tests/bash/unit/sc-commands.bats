#!/usr/bin/env bats
# Tests for sc:* namespace commands (#61)
# Verifies all 9 SuperClaude-derived commands exist with proper format

setup() {
    load '../../test_helper/common-setup'
    _common_setup
}

teardown() {
    _common_teardown
}

# ─── File existence ───

@test "sc-analyze command exists" {
    assert [ -f "$FORGE_DIR/commands/sc-analyze.md" ]
}

@test "sc-cleanup command exists" {
    assert [ -f "$FORGE_DIR/commands/sc-cleanup.md" ]
}

@test "sc-document command exists" {
    assert [ -f "$FORGE_DIR/commands/sc-document.md" ]
}

@test "sc-estimate command exists" {
    assert [ -f "$FORGE_DIR/commands/sc-estimate.md" ]
}

@test "sc-improve command exists" {
    assert [ -f "$FORGE_DIR/commands/sc-improve.md" ]
}

@test "sc-reflect command exists" {
    assert [ -f "$FORGE_DIR/commands/sc-reflect.md" ]
}

@test "sc-save command exists" {
    assert [ -f "$FORGE_DIR/commands/sc-save.md" ]
}

@test "sc-test command exists" {
    assert [ -f "$FORGE_DIR/commands/sc-test.md" ]
}

@test "sc-workflow command exists" {
    assert [ -f "$FORGE_DIR/commands/sc-workflow.md" ]
}

# ─── Header format ───

@test "all sc-* commands have YAML frontmatter" {
    for cmd in "$FORGE_DIR"/commands/sc-*.md; do
        run head -1 "$cmd"
        assert_output "---"
    done
}

@test "all sc-* commands have name in frontmatter" {
    for cmd in "$FORGE_DIR"/commands/sc-*.md; do
        run grep "^name:" "$cmd"
        assert_success
    done
}

@test "all sc-* commands have description in frontmatter" {
    for cmd in "$FORGE_DIR"/commands/sc-*.md; do
        run grep "^description:" "$cmd"
        assert_success
    done
}

# ─── Content quality ───

@test "all sc-* commands have Behavioral Flow section" {
    for cmd in "$FORGE_DIR"/commands/sc-*.md; do
        run grep -l "Behavioral Flow\|## What It Does\|## Usage" "$cmd"
        assert_success
    done
}

@test "all sc-* commands have Boundaries section" {
    for cmd in "$FORGE_DIR"/commands/sc-*.md; do
        run grep -l "Boundaries\|## Rules\|Will Not" "$cmd"
        assert_success
    done
}

# ─── Phase file references resolve ───

@test "sc:estimate referenced in phase-0-2-plan resolves" {
    assert [ -f "$FORGE_DIR/commands/sc-estimate.md" ]
    run grep "sc:estimate\|sc-estimate" "$FORGE_DIR/commands/forge-phases/phase-0-2-plan.md"
    assert_success
}

@test "sc:workflow referenced in phase-0-2-plan resolves" {
    assert [ -f "$FORGE_DIR/commands/sc-workflow.md" ]
    run grep "sc:workflow\|sc-workflow" "$FORGE_DIR/commands/forge-phases/phase-0-2-plan.md"
    assert_success
}

@test "sc:analyze referenced in phase-4-5-validate resolves" {
    assert [ -f "$FORGE_DIR/commands/sc-analyze.md" ]
    run grep "sc:analyze\|sc-analyze" "$FORGE_DIR/commands/forge-phases/phase-4-5-validate.md"
    assert_success
}

@test "sc:test referenced in phase-4-5-validate resolves" {
    assert [ -f "$FORGE_DIR/commands/sc-test.md" ]
    run grep "sc:test\|sc-test" "$FORGE_DIR/commands/forge-phases/phase-4-5-validate.md"
    assert_success
}
