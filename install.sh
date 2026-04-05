#!/usr/bin/env bash
set -euo pipefail

FORGE_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

usage() {
    echo "Usage:"
    echo "  ./install.sh              Install/update forge globally"
    echo "  ./install.sh <dir>        Install globally + prepare project directory"
    echo ""
    echo "Global install: copies agents, commands, rules, scripts to ~/.claude/"
    echo "Project prep:   creates dir + git init (then run /forge inside it)"
}

install_global() {
    echo -e "${GREEN}Installing Forge to $CLAUDE_DIR${NC}"

    # Create directories
    mkdir -p "$CLAUDE_DIR/agents" "$CLAUDE_DIR/commands" "$CLAUDE_DIR/rules" "$CLAUDE_DIR/scripts"

    # Copy agents (all stacks)
    echo "  Copying agents..."
    cp "$FORGE_DIR"/agents/universal/*.md "$CLAUDE_DIR/agents/"
    for stack_dir in "$FORGE_DIR"/agents/stacks/*/; do
        if [ -d "$stack_dir" ]; then
            cp "$stack_dir"*.md "$CLAUDE_DIR/agents/" 2>/dev/null || true
        fi
    done

    # Copy commands (includes /forge and all phase files)
    echo "  Copying commands..."
    cp "$FORGE_DIR"/commands/*.md "$CLAUDE_DIR/commands/" 2>/dev/null || true
    # Copy phase subdirectory
    if [ -d "$FORGE_DIR/commands/forge-phases" ]; then
        mkdir -p "$CLAUDE_DIR/commands/forge-phases"
        cp "$FORGE_DIR"/commands/forge-phases/*.md "$CLAUDE_DIR/commands/forge-phases/" 2>/dev/null || true
    fi

    # Copy rules
    echo "  Copying rules..."
    cp "$FORGE_DIR"/rules/*.md "$CLAUDE_DIR/rules/" 2>/dev/null || true

    # Copy ALL scripts (hooks depend on these)
    echo "  Copying scripts..."
    cp "$FORGE_DIR"/scripts/*.sh "$CLAUDE_DIR/scripts/" 2>/dev/null || true
    cp "$FORGE_DIR"/scripts/*.py "$CLAUDE_DIR/scripts/" 2>/dev/null || true
    chmod +x "$CLAUDE_DIR/scripts/"* 2>/dev/null || true

    # Copy templates (used by /forge Phase A to set up projects)
    echo "  Copying templates..."
    mkdir -p "$CLAUDE_DIR/templates/rules"
    cp "$FORGE_DIR"/templates/*.md "$CLAUDE_DIR/templates/" 2>/dev/null || true
    cp "$FORGE_DIR"/templates/*.json "$CLAUDE_DIR/templates/" 2>/dev/null || true
    cp "$FORGE_DIR"/templates/*.yml "$CLAUDE_DIR/templates/" 2>/dev/null || true
    cp "$FORGE_DIR"/templates/*.toml "$CLAUDE_DIR/templates/" 2>/dev/null || true
    cp "$FORGE_DIR"/templates/*.py "$CLAUDE_DIR/templates/" 2>/dev/null || true
    cp "$FORGE_DIR"/templates/rules/*.md "$CLAUDE_DIR/templates/rules/" 2>/dev/null || true

    # Install forge shell function
    echo "  Installing forge shell function..."
    cp "$FORGE_DIR/scripts/forge-shell.sh" "$CLAUDE_DIR/forge-shell.sh"
    # Add source line to .bashrc if not already there
    if ! grep -q "forge-shell.sh" "$HOME/.bashrc" 2>/dev/null; then
        echo "" >> "$HOME/.bashrc"
        echo "# Forge CLI" >> "$HOME/.bashrc"
        echo "source \"$CLAUDE_DIR/forge-shell.sh\"" >> "$HOME/.bashrc"
        echo "  Added forge() to ~/.bashrc"
    else
        echo "  forge() already in ~/.bashrc"
    fi

    # Count what was installed
    AGENT_COUNT=$(ls "$CLAUDE_DIR/agents/"*.md 2>/dev/null | wc -l)
    CMD_COUNT=$(ls "$CLAUDE_DIR/commands/"*.md 2>/dev/null | wc -l)
    RULE_COUNT=$(ls "$CLAUDE_DIR/rules/"*.md 2>/dev/null | wc -l)
    SCRIPT_COUNT=$(ls "$CLAUDE_DIR/scripts/"* 2>/dev/null | wc -l)

    echo ""
    echo -e "${GREEN}Forge installed:${NC}"
    echo "  $AGENT_COUNT agents"
    echo "  $CMD_COUNT commands"
    echo "  $RULE_COUNT rules"
    echo "  $SCRIPT_COUNT scripts"
    echo "  forge command available (restart shell or run: source ~/.bashrc)"
    echo ""
}

prep_project() {
    local PROJECT_DIR="$1"

    # Convert to absolute path
    if [[ "$PROJECT_DIR" != /* ]]; then
        PROJECT_DIR="$(pwd)/$PROJECT_DIR"
    fi

    if [ ! -d "$PROJECT_DIR" ]; then
        echo "  Creating $PROJECT_DIR"
        mkdir -p "$PROJECT_DIR"
    fi

    # Git init if needed
    if [ ! -d "$PROJECT_DIR/.git" ]; then
        git -C "$PROJECT_DIR" init -b main
        echo "  Initialized git repository"
    fi

    echo ""
    echo -e "${GREEN}Project ready: $PROJECT_DIR${NC}"
    echo "  Type /forge at the prompt to start building."
}

# Main
case "${1:-}" in
    -h|--help|help)
        usage
        ;;
    "")
        install_global
        echo "To start a new project:"
        echo -e "  ${YELLOW}./install.sh ~/projects/my-app${NC}"
        ;;
    *)
        # Argument given — install globally first (if needed), then prep project
        AGENT_DIR="$CLAUDE_DIR/agents"
        if [ ! -d "$AGENT_DIR" ] || [ -z "$(ls -A "$AGENT_DIR" 2>/dev/null)" ]; then
            install_global
        else
            # Check if forge needs updating (compare agent count)
            LOCAL_COUNT=$(ls "$FORGE_DIR"/agents/universal/*.md 2>/dev/null | wc -l)
            INSTALLED_COUNT=$(ls "$AGENT_DIR/"*.md 2>/dev/null | wc -l)
            if [ "$LOCAL_COUNT" -gt "$INSTALLED_COUNT" ] 2>/dev/null; then
                echo -e "${YELLOW}Forge update available. Reinstalling...${NC}"
                install_global
            else
                echo -e "${GREEN}Forge already installed (${INSTALLED_COUNT} agents). Skipping global install.${NC}"
                echo ""
            fi
        fi
        prep_project "$1"
        ;;
esac
