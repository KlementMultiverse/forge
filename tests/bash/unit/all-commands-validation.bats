#!/usr/bin/env bats
# Tests for all 45 command files — structure validation

setup() {
    load '../../test_helper/common-setup'
    _common_setup
}

teardown() {
    _common_teardown
}

@test "all commands have header line starting with # (after frontmatter)" {
    local missing=0
    for cmd in "$FORGE_DIR"/commands/*.md; do
        # Skip past YAML frontmatter — find first line starting with # after ---...---
        local has_heading
        if head -1 "$cmd" | grep -q "^---"; then
            has_heading=$(awk '/^---/{n++; next} n>=1 && /^# /{print "yes"; exit}' "$cmd")
        else
            has_heading=$(head -1 "$cmd" | grep -q "^# " && echo "yes")
        fi
        if [ "$has_heading" != "yes" ]; then
            echo "BAD HEADER: $(basename "$cmd")"
            missing=$((missing + 1))
        fi
    done
    [ "$missing" -eq 0 ]
}

@test "command count is at least 44" {
    local count
    count=$(ls "$FORGE_DIR"/commands/*.md 2>/dev/null | wc -l)
    [ "$count" -ge 44 ]
}

@test "no command file is empty" {
    local empty=0
    for cmd in "$FORGE_DIR"/commands/*.md; do
        local lines
        lines=$(wc -l < "$cmd")
        if [ "$lines" -lt 5 ]; then
            echo "TOO SHORT: $(basename "$cmd") ($lines lines)"
            empty=$((empty + 1))
        fi
    done
    [ "$empty" -eq 0 ]
}

@test "enforcement-critical commands have system-reminder" {
    local critical="bootstrap generate-spec gate"
    local missing=0
    for cmd in $critical; do
        if ! grep -q "system-reminder" "$FORGE_DIR/commands/$cmd.md" 2>/dev/null; then
            echo "MISSING system-reminder: $cmd.md"
            missing=$((missing + 1))
        fi
    done
    [ "$missing" -eq 0 ]
}

@test "context:fork commands have YAML frontmatter" {
    local fork_cmds="design-doc review audit-patterns critic retro security-scan checkpoint"
    local missing=0
    for cmd in $fork_cmds; do
        if [ -f "$FORGE_DIR/commands/$cmd.md" ] && ! head -1 "$FORGE_DIR/commands/$cmd.md" | grep -q "^---"; then
            echo "MISSING frontmatter: $cmd.md"
            missing=$((missing + 1))
        fi
    done
    [ "$missing" -eq 0 ]
}

@test "all phase files exist" {
    assert [ -f "$FORGE_DIR/commands/forge-phases/phase-a-setup.md" ]
    assert [ -f "$FORGE_DIR/commands/forge-phases/phase-0-2-plan.md" ]
    assert [ -f "$FORGE_DIR/commands/forge-phases/phase-3-implement.md" ]
    assert [ -f "$FORGE_DIR/commands/forge-phases/phase-4-5-validate.md" ]
    assert [ -f "$FORGE_DIR/commands/forge-phases/cases.md" ]
}
