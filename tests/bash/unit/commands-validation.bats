#!/usr/bin/env bats
# Tests for command file validation
# Verifies all commands referenced in phase files exist and have proper format

setup() {
    load '../../test_helper/common-setup'
    _common_setup
}

teardown() {
    _common_teardown
}

# ─── /autoresearch command exists (#60) ───

@test "autoresearch command file exists" {
    assert [ -f "$FORGE_DIR/commands/autoresearch.md" ]
}

@test "autoresearch has proper header format" {
    head -5 "$FORGE_DIR/commands/autoresearch.md" | grep -q "# /autoresearch"
}

# ─── sc:* namespace commands exist (#61) ───

@test "sc-analyze command file exists" {
    assert [ -f "$FORGE_DIR/commands/sc-analyze.md" ]
}

@test "sc-cleanup command file exists" {
    assert [ -f "$FORGE_DIR/commands/sc-cleanup.md" ]
}

@test "sc-document command file exists" {
    assert [ -f "$FORGE_DIR/commands/sc-document.md" ]
}

@test "sc-estimate command file exists" {
    assert [ -f "$FORGE_DIR/commands/sc-estimate.md" ]
}

@test "sc-improve command file exists" {
    assert [ -f "$FORGE_DIR/commands/sc-improve.md" ]
}

@test "sc-reflect command file exists" {
    assert [ -f "$FORGE_DIR/commands/sc-reflect.md" ]
}

@test "sc-save command file exists" {
    assert [ -f "$FORGE_DIR/commands/sc-save.md" ]
}

@test "sc-test command file exists" {
    assert [ -f "$FORGE_DIR/commands/sc-test.md" ]
}

@test "sc-workflow command file exists" {
    assert [ -f "$FORGE_DIR/commands/sc-workflow.md" ]
}

# ─── All sc:* commands have proper headers ───

@test "all sc-* commands have proper header format" {
    for cmd in "$FORGE_DIR"/commands/sc-*.md; do
        local name
        name=$(basename "$cmd" .md)
        # Should have # /sc:name or # /sc-name header
        run head -5 "$cmd"
        assert_output --partial "# /sc"
    done
}

# ─── All commands referenced in phase files exist ───

@test "all skill references in phase-0-2-plan resolve to files" {
    local missing=0
    for skill in $(grep -oP 'skill:\s*"(\K[^"]+)' "$FORGE_DIR/commands/forge-phases/phase-0-2-plan.md" 2>/dev/null); do
        # Convert sc:name to sc-name for file lookup
        local filename="${skill//:/-}"
        if [ ! -f "$FORGE_DIR/commands/${filename}.md" ]; then
            echo "MISSING: $skill → commands/${filename}.md"
            missing=$((missing + 1))
        fi
    done
    [ "$missing" -eq 0 ]
}

@test "all skill references in phase-4-5-validate resolve to files" {
    local missing=0
    for skill in $(grep -oP 'skill:\s*"(\K[^"]+)' "$FORGE_DIR/commands/forge-phases/phase-4-5-validate.md" 2>/dev/null); do
        local filename="${skill//:/-}"
        if [ ! -f "$FORGE_DIR/commands/${filename}.md" ]; then
            echo "MISSING: $skill → commands/${filename}.md"
            missing=$((missing + 1))
        fi
    done
    [ "$missing" -eq 0 ]
}

@test "all subagent_type references in phase files resolve to agents" {
    local missing=0
    for agent in $(grep -oP 'subagent_type="(\K[^"]+)' "$FORGE_DIR/commands/forge-phases/"*.md 2>/dev/null | sort -u); do
        # Skip placeholder
        [ "$agent" = "{domain-agent}" ] && continue
        local found=false
        for f in "$FORGE_DIR/agents/universal/${agent}.md" "$FORGE_DIR/agents/stacks/*/${agent}.md"; do
            if ls $f 2>/dev/null | head -1 > /dev/null; then
                found=true
                break
            fi
        done
        if ! $found; then
            echo "MISSING AGENT: $agent"
            missing=$((missing + 1))
        fi
    done
    [ "$missing" -eq 0 ]
}
