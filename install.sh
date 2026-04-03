#!/usr/bin/env bash
set -euo pipefail

FORGE_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
    echo "Usage:"
    echo "  ./install.sh              Install forge globally to ~/.claude/"
    echo "  ./install.sh init <dir>   Initialize forge in a project directory"
    echo ""
    echo "Global install: copies agents, commands, rules, hooks, templates to ~/.claude/"
    echo "Project init:   creates .forge/ in the project with local playbook + rules"
}

install_global() {
    echo -e "${GREEN}Installing Forge globally to $CLAUDE_DIR${NC}"

    # Create directories
    mkdir -p "$CLAUDE_DIR/agents" "$CLAUDE_DIR/commands" "$CLAUDE_DIR/rules" "$CLAUDE_DIR/hooks"

    # Copy agents (all stacks)
    echo "  Copying agents..."
    cp "$FORGE_DIR"/agents/universal/*.md "$CLAUDE_DIR/agents/"
    for stack_dir in "$FORGE_DIR"/agents/stacks/*/; do
        if [ -d "$stack_dir" ]; then
            cp "$stack_dir"*.md "$CLAUDE_DIR/agents/" 2>/dev/null || true
        fi
    done

    # Copy commands
    echo "  Copying commands..."
    cp "$FORGE_DIR"/commands/*.md "$CLAUDE_DIR/commands/" 2>/dev/null || true

    # Copy rules
    echo "  Copying rules..."
    mkdir -p "$CLAUDE_DIR/rules"
    cp "$FORGE_DIR"/rules/*.md "$CLAUDE_DIR/rules/" 2>/dev/null || true

    # Copy hooks
    echo "  Copying hooks..."
    cp "$FORGE_DIR"/hooks/hooks.json "$CLAUDE_DIR/hooks/" 2>/dev/null || true

    # Count what was installed
    AGENT_COUNT=$(ls "$CLAUDE_DIR/agents/"*.md 2>/dev/null | wc -l)
    CMD_COUNT=$(ls "$CLAUDE_DIR/commands/"*.md 2>/dev/null | wc -l)
    RULE_COUNT=$(ls "$CLAUDE_DIR/rules/"*.md 2>/dev/null | wc -l)

    echo ""
    echo -e "${GREEN}Forge installed globally:${NC}"
    echo "  $AGENT_COUNT agents"
    echo "  $CMD_COUNT commands"
    echo "  $RULE_COUNT rule files"
    echo ""
    echo "Run '/forge \"describe your app\"' in any project to start."
}

init_project() {
    local PROJECT_DIR="$1"

    if [ ! -d "$PROJECT_DIR" ]; then
        echo "Creating project directory: $PROJECT_DIR"
        mkdir -p "$PROJECT_DIR"
    fi

    echo -e "${GREEN}Initializing Forge in $PROJECT_DIR${NC}"

    # Create .forge directory structure
    local FORGE_LOCAL="$PROJECT_DIR/.forge"
    mkdir -p "$FORGE_LOCAL/playbook" "$FORGE_LOCAL/rules" "$FORGE_LOCAL/agents" "$FORGE_LOCAL/checkpoints"

    # Copy templates
    if [ -d "$FORGE_DIR/templates" ]; then
        echo "  Copying templates..."
        # CLAUDE.md template → project root
        if [ -f "$FORGE_DIR/templates/CLAUDE.template.md" ] && [ ! -f "$PROJECT_DIR/CLAUDE.md" ]; then
            cp "$FORGE_DIR/templates/CLAUDE.template.md" "$PROJECT_DIR/CLAUDE.md"
            echo "  Created CLAUDE.md (edit to match your project)"
        fi
        # SPEC template
        if [ -f "$FORGE_DIR/templates/SPEC.template.md" ] && [ ! -f "$PROJECT_DIR/SPEC.md" ]; then
            cp "$FORGE_DIR/templates/SPEC.template.md" "$PROJECT_DIR/SPEC.md"
            echo "  Created SPEC.md (fill in your requirements)"
        fi
    fi

    # Initialize local playbook
    cat > "$FORGE_LOCAL/playbook/strategies.md" << 'PLAYBOOK'
# Playbook — Strategies & Insights
# This file grows as the project learns from builds.
# Format: [str-NNN] helpful=N harmful=N :: insight text

## STRATEGIES & INSIGHTS
# (populated by /learn and /retro)

## COMMON MISTAKES TO AVOID
# (populated by /retro)

## DOMAIN-SPECIFIC
# (populated by agents during implementation)
PLAYBOOK

    cat > "$FORGE_LOCAL/playbook/mistakes.md" << 'MISTAKES'
# Playbook — Mistakes
# Errors encountered during builds. Each entry prevents repeat failures.
# Format: [mis-NNN] :: description + root cause + prevention
MISTAKES

    cat > "$FORGE_LOCAL/playbook/archived.md" << 'ARCHIVED'
# Playbook — Archived
# Pruned entries (harmful > helpful) are moved here.
ARCHIVED

    # Initialize local rules (project can override global rules)
    cat > "$FORGE_LOCAL/rules/project.md" << 'RULES'
# Project-Specific Rules
# Rules that apply ONLY to this project. Global rules are in ~/.claude/rules/
# Add rules here as the project evolves.
RULES

    # Create .gitignore for forge local (keep playbook, ignore checkpoints)
    cat > "$FORGE_LOCAL/.gitignore" << 'GITIGNORE'
# Checkpoints are ephemeral — don't commit
checkpoints/
GITIGNORE

    # Initialize git if not already
    if [ ! -d "$PROJECT_DIR/.git" ]; then
        cd "$PROJECT_DIR" && git init && cd -
        echo "  Initialized git repository"
    fi

    # Create docs structure
    mkdir -p "$PROJECT_DIR/docs/proposals" "$PROJECT_DIR/docs/retrospectives" "$PROJECT_DIR/docs/checkpoints"

    # Count
    echo ""
    echo -e "${GREEN}Forge initialized in $PROJECT_DIR:${NC}"
    echo "  .forge/playbook/     — local learning (strategies, mistakes)"
    echo "  .forge/rules/        — project-specific rules"
    echo "  .forge/agents/       — project-specific agent tweaks"
    echo "  CLAUDE.md            — project brain (edit this)"
    echo "  SPEC.md              — project requirements (fill this)"
    echo "  docs/                — proposals, retros, checkpoints"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. Edit CLAUDE.md with your tech stack and rules"
    echo "  2. Edit SPEC.md with your project description"
    echo "  3. Run: /forge \"describe your app in one sentence\""
}

# Export learnings helper
export_learnings() {
    echo "TODO: forge export-learnings will scan .forge/playbook/ and categorize entries as global vs project-specific"
    echo "For now, manually review .forge/playbook/strategies.md and copy global entries to the master forge repo."
}

# Main
case "${1:-}" in
    init)
        if [ -z "${2:-}" ]; then
            echo "Error: project directory required"
            echo "Usage: ./install.sh init <project-dir>"
            exit 1
        fi
        init_project "$2"
        ;;
    export)
        export_learnings
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        install_global
        ;;
esac
