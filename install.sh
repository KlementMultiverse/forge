#!/bin/bash
# Forge Installer — copies commands, agents, rules, hooks to ~/.claude/
set -e

FORGE_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "=== Installing Forge ==="
echo "Source: $FORGE_DIR"
echo "Target: $CLAUDE_DIR"
echo ""

# Commands
echo "Installing commands..."
cp "$FORGE_DIR/commands/"*.md "$CLAUDE_DIR/commands/" 2>/dev/null || true
echo "  Copied $(ls "$FORGE_DIR/commands/"*.md 2>/dev/null | wc -l) commands"

# Agents (universal)
echo "Installing universal agents..."
cp "$FORGE_DIR/agents/universal/"*.md "$CLAUDE_DIR/agents/" 2>/dev/null || true
echo "  Copied $(ls "$FORGE_DIR/agents/universal/"*.md 2>/dev/null | wc -l) agents"

# Agents (stacks)
echo "Installing stack agents..."
for stack_dir in "$FORGE_DIR/agents/stacks/"*/; do
    stack_name=$(basename "$stack_dir")
    mkdir -p "$CLAUDE_DIR/agents/stacks/$stack_name"
    cp "$stack_dir"*.md "$CLAUDE_DIR/agents/stacks/$stack_name/" 2>/dev/null || true
    count=$(ls "$stack_dir"*.md 2>/dev/null | wc -l)
    if [ "$count" -gt 0 ]; then
        echo "  $stack_name: $count agents"
    fi
done

# Rules
echo "Installing rules..."
mkdir -p "$CLAUDE_DIR/rules"
cp "$FORGE_DIR/rules/"*.md "$CLAUDE_DIR/rules/" 2>/dev/null || true
echo "  Copied $(ls "$FORGE_DIR/rules/"*.md 2>/dev/null | wc -l) rule files"

# Hooks
echo "Installing hooks..."
mkdir -p "$CLAUDE_DIR/hooks"
cp "$FORGE_DIR/hooks/hooks.json" "$CLAUDE_DIR/hooks/" 2>/dev/null || true
echo "  Copied hooks.json"

# Playbook
echo "Installing playbook..."
mkdir -p "$CLAUDE_DIR/playbook"
cp "$FORGE_DIR/playbook/"*.md "$CLAUDE_DIR/playbook/" 2>/dev/null || true
echo "  Copied $(ls "$FORGE_DIR/playbook/"*.md 2>/dev/null | wc -l) playbook files"

# Scripts
echo "Installing scripts..."
mkdir -p "$CLAUDE_DIR/scripts"
cp "$FORGE_DIR/scripts/"*.sh "$CLAUDE_DIR/scripts/" 2>/dev/null || true
chmod +x "$CLAUDE_DIR/scripts/"*.sh 2>/dev/null || true
echo "  Copied $(ls "$FORGE_DIR/scripts/"*.sh 2>/dev/null | wc -l) scripts"

echo ""
echo "=== Forge installed successfully ==="
echo ""
echo "Usage:"
echo "  /forge \"I want to build [your idea]\""
