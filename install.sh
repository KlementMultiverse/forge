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

    # Copy hooks to global settings (where Claude Code actually reads them)
    echo "  Copying hooks..."
    # Claude Code reads hooks from settings.json, not hooks/ directory
    if [ -f "$FORGE_DIR/templates/hooks.json" ]; then
        # Merge hooks into user settings if settings.json exists
        if [ -f "$CLAUDE_DIR/settings.json" ]; then
            echo "  Note: ~/.claude/settings.json already exists. Hooks are per-project via forge init."
        else
            cp "$FORGE_DIR/templates/hooks.json" "$CLAUDE_DIR/settings.json"
            echo "  Created ~/.claude/settings.json with forge hooks"
        fi
    fi

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
            echo "  Created CLAUDE.md (placeholder — run /setup to fill)"
        fi
        # SPEC template
        if [ -f "$FORGE_DIR/templates/SPEC.template.md" ] && [ ! -f "$PROJECT_DIR/SPEC.md" ]; then
            cp "$FORGE_DIR/templates/SPEC.template.md" "$PROJECT_DIR/SPEC.md"
            echo "  Created SPEC.md (placeholder — run /setup to fill)"
        fi
    fi

    # Create .claude/rules/ directory and copy rule templates
    local CLAUDE_RULES="$PROJECT_DIR/.claude/rules"
    mkdir -p "$CLAUDE_RULES"
    if [ -d "$FORGE_DIR/templates/rules" ]; then
        echo "  Copying rule templates..."
        cp "$FORGE_DIR/templates/rules/sdlc-flow.md" "$CLAUDE_RULES/" 2>/dev/null || true
        cp "$FORGE_DIR/templates/rules/agent-routing.md" "$CLAUDE_RULES/" 2>/dev/null || true
        echo "  Created .claude/rules/ (SDLC flow + agent routing)"
    fi

    # Copy hooks template
    if [ -f "$FORGE_DIR/templates/hooks.json" ]; then
        mkdir -p "$PROJECT_DIR/.claude"
        cp "$FORGE_DIR/templates/hooks.json" "$PROJECT_DIR/.claude/settings.json"
        # Replace placeholder with actual project dir
        sed -i "s|{{PROJECT_DIR}}|$PROJECT_DIR|g" "$PROJECT_DIR/.claude/settings.json"
        echo "  Created .claude/settings.json (hooks for lint + safety)"
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

    # Create .env.example
    if [ ! -f "$PROJECT_DIR/.env.example" ]; then
        cat > "$PROJECT_DIR/.env.example" << 'ENVEXAMPLE'
# Django
SECRET_KEY=change-me-to-random-string
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1

# Database
DATABASE_URL=postgres://postgres:postgres@localhost:5432/myapp

# Redis
REDIS_URL=redis://localhost:6379/0

# AWS (if needed)
# AWS_ACCESS_KEY_ID=
# AWS_SECRET_ACCESS_KEY=
# AWS_S3_BUCKET_NAME=
# AWS_LAMBDA_FUNCTION_NAME=

# AI/LLM (if needed)
# OPENAI_API_KEY=
# ANTHROPIC_API_KEY=
ENVEXAMPLE
        echo "  Created .env.example"
    fi

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

    # Copy scripts (traceability + sync report)
    if [ -d "$FORGE_DIR/scripts" ]; then
        echo "  Copying scripts..."
        mkdir -p "$PROJECT_DIR/scripts"
        cp "$FORGE_DIR/scripts/traceability.sh" "$PROJECT_DIR/scripts/" 2>/dev/null || true
        cp "$FORGE_DIR/scripts/sync-report.sh" "$PROJECT_DIR/scripts/" 2>/dev/null || true
        chmod +x "$PROJECT_DIR/scripts/"*.sh 2>/dev/null || true
    fi

    # Create trace directory
    mkdir -p "$PROJECT_DIR/docs/forge-trace"
    if [ -f "$FORGE_DIR/templates/forge-trace-index.template.md" ]; then
        sed "s/{{PROJECT_NAME}}/$(basename $PROJECT_DIR)/g" \
            "$FORGE_DIR/templates/forge-trace-index.template.md" \
            > "$PROJECT_DIR/docs/forge-trace/INDEX.md"
        echo "  Created docs/forge-trace/ (execution trace)"
    fi

    # Create docs structure
    mkdir -p "$PROJECT_DIR/docs/proposals" "$PROJECT_DIR/docs/retrospectives" "$PROJECT_DIR/docs/checkpoints" "$PROJECT_DIR/docs/issues" "$PROJECT_DIR/docs/retros"

    # Create forge timeline from template
    if [ -f "$FORGE_DIR/templates/forge-timeline.template.md" ] && [ ! -f "$PROJECT_DIR/docs/forge-timeline.md" ]; then
        cp "$FORGE_DIR/templates/forge-timeline.template.md" "$PROJECT_DIR/docs/forge-timeline.md"
        # Replace placeholder with project name (dirname)
        local PROJECT_NAME
        PROJECT_NAME=$(basename "$PROJECT_DIR")
        sed -i "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" "$PROJECT_DIR/docs/forge-timeline.md"
        echo "  Created docs/forge-timeline.md (audit trail)"
    fi

    # Count
    echo ""
    echo -e "${GREEN}Forge initialized in $PROJECT_DIR:${NC}"
    echo "  .forge/playbook/     — local learning (strategies, mistakes)"
    echo "  .forge/rules/        — project-specific rules"
    echo "  .forge/agents/       — project-specific agent tweaks"
    echo "  CLAUDE.md            — project brain (edit this)"
    echo "  SPEC.md              — project requirements (fill this)"
    echo "  docs/                — proposals, retros, checkpoints"
    echo "  .env.example         — environment variable template"
    echo ""
    echo "  Note: Dockerfile and docker-compose.yml will be created by /forge during scaffolding"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. cd into your project"
    echo "  2. Open Claude Code: claude"
    echo "  3. Type: /forge"
    echo "  4. That's it. Forge handles everything."
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
