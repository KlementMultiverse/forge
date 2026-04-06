#!/usr/bin/env bats
# Tests for all 54 agent files — schema validation
# Verifies frontmatter, heading, structure

setup() {
    load '../../test_helper/common-setup'
    _common_setup
}

teardown() {
    _common_teardown
}

# ─── Frontmatter validation ───

@test "all universal agents have YAML frontmatter" {
    local missing=0
    for agent in "$FORGE_DIR"/agents/universal/*.md; do
        [ "$(basename "$agent")" = "README.md" ] && continue
        if ! head -1 "$agent" | grep -q "^---"; then
            echo "MISSING FRONTMATTER: $(basename "$agent")"
            missing=$((missing + 1))
        fi
    done
    [ "$missing" -eq 0 ]
}

@test "all stack agents have YAML frontmatter" {
    local missing=0
    for agent in "$FORGE_DIR"/agents/stacks/*/*.md; do
        [ "$(basename "$agent")" = "README.md" ] && continue
        if ! head -1 "$agent" | grep -q "^---"; then
            echo "MISSING FRONTMATTER: $(basename "$agent")"
            missing=$((missing + 1))
        fi
    done
    [ "$missing" -eq 0 ]
}

@test "all agents have 'name' in frontmatter" {
    local missing=0
    for agent in "$FORGE_DIR"/agents/universal/*.md "$FORGE_DIR"/agents/stacks/*/*.md; do
        [ "$(basename "$agent")" = "README.md" ] && continue
        if ! grep -q "^name:" "$agent" 2>/dev/null; then
            echo "MISSING name: $(basename "$agent")"
            missing=$((missing + 1))
        fi
    done
    [ "$missing" -eq 0 ]
}

@test "all agents have 'description' in frontmatter" {
    local missing=0
    for agent in "$FORGE_DIR"/agents/universal/*.md "$FORGE_DIR"/agents/stacks/*/*.md; do
        [ "$(basename "$agent")" = "README.md" ] && continue
        if ! grep -q "^description:" "$agent" 2>/dev/null; then
            echo "MISSING description: $(basename "$agent")"
            missing=$((missing + 1))
        fi
    done
    [ "$missing" -eq 0 ]
}

@test "all agents have 'tools' in frontmatter" {
    local missing=0
    for agent in "$FORGE_DIR"/agents/universal/*.md "$FORGE_DIR"/agents/stacks/*/*.md; do
        [ "$(basename "$agent")" = "README.md" ] && continue
        if ! grep -q "^tools:" "$agent" 2>/dev/null; then
            echo "MISSING tools: $(basename "$agent")"
            missing=$((missing + 1))
        fi
    done
    [ "$missing" -eq 0 ]
}

# ─── Content validation ───

@test "all agents have a heading (# Agent Name)" {
    local missing=0
    for agent in "$FORGE_DIR"/agents/universal/*.md "$FORGE_DIR"/agents/stacks/*/*.md; do
        [ "$(basename "$agent")" = "README.md" ] && continue
        if ! grep -q "^# " "$agent" 2>/dev/null; then
            echo "MISSING HEADING: $(basename "$agent")"
            missing=$((missing + 1))
        fi
    done
    [ "$missing" -eq 0 ]
}

@test "no agent file is empty" {
    local empty=0
    for agent in "$FORGE_DIR"/agents/universal/*.md "$FORGE_DIR"/agents/stacks/*/*.md; do
        [ "$(basename "$agent")" = "README.md" ] && continue
        local lines
        lines=$(wc -l < "$agent")
        if [ "$lines" -lt 10 ]; then
            echo "TOO SHORT ($lines lines): $(basename "$agent")"
            empty=$((empty + 1))
        fi
    done
    [ "$empty" -eq 0 ]
}

@test "agent count matches expected (51+ agents)" {
    local count=0
    for agent in "$FORGE_DIR"/agents/universal/*.md "$FORGE_DIR"/agents/stacks/*/*.md; do
        [ "$(basename "$agent")" = "README.md" ] && continue
        count=$((count + 1))
    done
    [ "$count" -ge 50 ]
}

# ─── Cross-reference: agents referenced in phases exist ───

@test "all subagent_type references resolve to agent files" {
    local missing=0
    for agent in $(grep -ohP 'subagent_type="(\K[^"]+)' "$FORGE_DIR/commands/forge-phases/"*.md 2>/dev/null | sort -u); do
        [ "$agent" = "{domain-agent}" ] && continue
        local found=false
        # Check exact match and -agent suffix variant
        for f in "$FORGE_DIR/agents/universal/${agent}.md" "$FORGE_DIR"/agents/stacks/*/"${agent}.md" "$FORGE_DIR/agents/universal/${agent}-agent.md" "$FORGE_DIR"/agents/stacks/*/"${agent}-agent.md"; do
            if [ -f "$f" ] 2>/dev/null; then
                found=true
                break
            fi
        done
        if ! $found; then
            echo "MISSING: $agent"
            missing=$((missing + 1))
        fi
    done
    [ "$missing" -eq 0 ]
}
