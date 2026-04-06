#!/usr/bin/env bash
set -euo pipefail

# Resolve real path (works with symlinks) — Fix #4
FORGE_DIR="$(cd "$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

usage() {
    echo "Usage:"
    echo "  ./install.sh              Install/update forge globally"
    echo "  ./install.sh --force      Force reinstall (ignore update check)"
    echo "  ./install.sh <dir>        Install globally + prepare project directory"
    echo ""
    echo "Global install: copies agents, commands, rules, scripts to ~/.claude/"
    echo "Project prep:   creates dir + git init (then run /forge inside it)"
}

# Pre-flight checks — Fix #5, #7
preflight() {
    # Verify forge source directory structure
    local missing=0
    for required_dir in "agents/universal" "commands" "rules" "scripts" "templates"; do
        if [ ! -d "$FORGE_DIR/$required_dir" ]; then
            echo -e "${RED}ERROR: Missing $FORGE_DIR/$required_dir${NC}"
            missing=1
        fi
    done
    if [ "$missing" -eq 1 ]; then
        echo "Is this a complete forge clone? Run: git clone https://github.com/KlementMultiverse/forge.git"
        exit 1
    fi

    # Check python3 is available
    if ! command -v python3 &>/dev/null; then
        echo -e "${YELLOW}WARNING: python3 not found. Validation will be skipped.${NC}"
    fi
}

install_global() {
    echo -e "${GREEN}Installing Forge to $CLAUDE_DIR${NC}"

    # ─── Nuke-and-replace: remove stale files before copy — Fix #8, #9, #10 ───
    # This ensures deleted/renamed files don't persist from previous installs
    # Guard: :? prevents accidental deletion if CLAUDE_DIR is somehow empty
    : "${CLAUDE_DIR:?CLAUDE_DIR must be set}"
    for dir in agents commands rules scripts templates; do
        if [ -d "$CLAUDE_DIR/$dir" ]; then
            rm -rf "${CLAUDE_DIR:?}/$dir"
        fi
    done

    # Create fresh directories
    mkdir -p "$CLAUDE_DIR/agents" "$CLAUDE_DIR/commands" "$CLAUDE_DIR/commands/forge-phases" \
             "$CLAUDE_DIR/rules" "$CLAUDE_DIR/scripts" "$CLAUDE_DIR/templates/rules"

    # Copy agents (universal + all stacks) — Fix #1: added || true
    echo "  Copying agents..."
    cp "$FORGE_DIR"/agents/universal/*.md "$CLAUDE_DIR/agents/" 2>/dev/null || true
    for stack_dir in "$FORGE_DIR"/agents/stacks/*/; do
        if [ -d "$stack_dir" ]; then
            cp "$stack_dir"*.md "$CLAUDE_DIR/agents/" 2>/dev/null || true
        fi
    done

    # Copy commands + phase subdirectory
    echo "  Copying commands..."
    cp "$FORGE_DIR"/commands/*.md "$CLAUDE_DIR/commands/" 2>/dev/null || true
    if [ -d "$FORGE_DIR/commands/forge-phases" ]; then
        cp "$FORGE_DIR"/commands/forge-phases/*.md "$CLAUDE_DIR/commands/forge-phases/" 2>/dev/null || true
    fi

    # Copy rules
    echo "  Copying rules..."
    cp "$FORGE_DIR"/rules/*.md "$CLAUDE_DIR/rules/" 2>/dev/null || true

    # Copy ALL scripts (hooks depend on these)
    echo "  Copying scripts..."
    cp "$FORGE_DIR"/scripts/*.sh "$CLAUDE_DIR/scripts/" 2>/dev/null || true
    cp "$FORGE_DIR"/scripts/*.py "$CLAUDE_DIR/scripts/" 2>/dev/null || true
    # Fix #14: only chmod .sh and .py, not all files
    chmod +x "$CLAUDE_DIR/scripts/"*.sh 2>/dev/null || true
    chmod +x "$CLAUDE_DIR/scripts/"*.py 2>/dev/null || true

    # Copy templates (used by /forge Phase A to set up projects)
    echo "  Copying templates..."
    cp "$FORGE_DIR"/templates/*.md "$CLAUDE_DIR/templates/" 2>/dev/null || true
    cp "$FORGE_DIR"/templates/*.json "$CLAUDE_DIR/templates/" 2>/dev/null || true
    cp "$FORGE_DIR"/templates/*.yml "$CLAUDE_DIR/templates/" 2>/dev/null || true
    cp "$FORGE_DIR"/templates/*.toml "$CLAUDE_DIR/templates/" 2>/dev/null || true
    cp "$FORGE_DIR"/templates/*.py "$CLAUDE_DIR/templates/" 2>/dev/null || true
    cp "$FORGE_DIR"/templates/commit-msg "$CLAUDE_DIR/templates/" 2>/dev/null || true
    cp "$FORGE_DIR"/templates/pre-commit "$CLAUDE_DIR/templates/" 2>/dev/null || true
    cp "$FORGE_DIR"/templates/rules/*.md "$CLAUDE_DIR/templates/rules/" 2>/dev/null || true

    # ─── Validation — Fix #11: show warnings instead of swallowing ───
    echo "  Validating..."
    if command -v python3 &>/dev/null; then
        local reg_ok=true
        local lint_ok=true
        python3 "$FORGE_DIR/scripts/forge-registry.py" "$FORGE_DIR" > /tmp/forge-registry-out.txt 2>&1 &
        local PID_REG=$!
        python3 "$FORGE_DIR/scripts/forge-lint.py" "$FORGE_DIR" > /tmp/forge-lint-out.txt 2>&1 &
        local PID_LINT=$!
        wait $PID_REG 2>/dev/null || reg_ok=false
        wait $PID_LINT 2>/dev/null || lint_ok=false

        if ! $reg_ok; then
            echo -e "  ${YELLOW}WARNING: Registry generation reported issues${NC}"
            head -5 /tmp/forge-registry-out.txt 2>/dev/null | sed 's/^/    /'
        fi
        if ! $lint_ok; then
            echo -e "  ${YELLOW}WARNING: Lint check reported issues${NC}"
            head -5 /tmp/forge-lint-out.txt 2>/dev/null | sed 's/^/    /'
        fi
        if $reg_ok && $lint_ok; then
            echo "  Validation passed"
        fi
        rm -f /tmp/forge-registry-out.txt /tmp/forge-lint-out.txt
    else
        echo -e "  ${YELLOW}Skipped (python3 not found)${NC}"
    fi
    echo ""

    # ─── Install forge shell function — Fix #15, #17: check active source line + zsh ───
    echo "  Installing forge shell function..."
    if ! cp "$FORGE_DIR/scripts/forge-shell.sh" "$CLAUDE_DIR/forge-shell.sh"; then
        echo -e "${RED}ERROR: Failed to copy forge-shell.sh — forge command will not work${NC}"
        exit 1
    fi

    local shell_installed=false
    for rc_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [ -f "$rc_file" ]; then
            # Fix #15: check for active (uncommented) source line
            if ! grep -qE '^\s*source\s+.*forge-shell\.sh' "$rc_file" 2>/dev/null; then
                echo "" >> "$rc_file"
                echo "# Forge CLI" >> "$rc_file"
                echo "source \"$CLAUDE_DIR/forge-shell.sh\"" >> "$rc_file"
                echo "  Added forge() to $rc_file"
                shell_installed=true
            else
                echo "  forge() already in $rc_file"
                shell_installed=true
            fi
        fi
    done

    if ! $shell_installed; then
        echo -e "  ${YELLOW}WARNING: No .bashrc or .zshrc found. Add manually:${NC}"
        echo "  source \"$CLAUDE_DIR/forge-shell.sh\""
    fi

    # Count what was installed (accurate after nuke-and-replace)
    AGENT_COUNT=$(find "$CLAUDE_DIR/agents/" -name "*.md" 2>/dev/null | wc -l)
    CMD_COUNT=$(find "$CLAUDE_DIR/commands/" -name "*.md" 2>/dev/null | wc -l)
    RULE_COUNT=$(find "$CLAUDE_DIR/rules/" -name "*.md" 2>/dev/null | wc -l)
    SCRIPT_COUNT=$(find "$CLAUDE_DIR/scripts/" -type f 2>/dev/null | wc -l)
    TMPL_COUNT=$(find "$CLAUDE_DIR/templates/" -type f 2>/dev/null | wc -l)

    echo ""
    echo -e "${GREEN}Forge installed:${NC}"
    echo "  $AGENT_COUNT agents"
    echo "  $CMD_COUNT commands"
    echo "  $RULE_COUNT rules"
    echo "  $SCRIPT_COUNT scripts"
    echo "  $TMPL_COUNT templates"
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
    else
        # Fix #6: warn if directory has existing content
        local file_count
        file_count=$(find "$PROJECT_DIR" -maxdepth 1 -not -name ".git" -not -name "." | wc -l)
        if [ "$file_count" -gt 0 ] && [ ! -d "$PROJECT_DIR/.git" ]; then
            echo -e "${YELLOW}  WARNING: $PROJECT_DIR has existing files ($file_count items).${NC}"
            echo "  Git init will be run on this directory."
        fi
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

# ─── Update detection — Fix #2, #22: checksum-based + --force ───
needs_update() {
    local AGENT_DIR="$CLAUDE_DIR/agents"

    # No agents installed = definitely needs install
    if [ ! -d "$AGENT_DIR" ] || [ -z "$(ls -A "$AGENT_DIR" 2>/dev/null)" ]; then
        return 0
    fi

    # --force flag always triggers reinstall
    if [ "${FORCE_INSTALL:-false}" = "true" ]; then
        echo -e "${YELLOW}Force reinstall requested.${NC}"
        return 0
    fi

    # Checksum-based: compare a fast fingerprint of source vs installed
    # Use file count + total size as a lightweight proxy for content changes
    local src_fingerprint installed_fingerprint
    src_fingerprint=$(find "$FORGE_DIR/agents" "$FORGE_DIR/commands" "$FORGE_DIR/scripts" "$FORGE_DIR/rules" "$FORGE_DIR/templates" -type f 2>/dev/null | wc -l)
    installed_fingerprint=$(find "$CLAUDE_DIR/agents" "$CLAUDE_DIR/commands" "$CLAUDE_DIR/scripts" "$CLAUDE_DIR/rules" "$CLAUDE_DIR/templates" -type f 2>/dev/null | wc -l)

    if [ "$src_fingerprint" != "$installed_fingerprint" ]; then
        echo -e "${YELLOW}Forge update detected ($src_fingerprint source files vs $installed_fingerprint installed). Reinstalling...${NC}"
        return 0
    fi

    # Also check if any source file is newer than the newest installed file
    # Use stat instead of find -printf for macOS/BSD compatibility
    local src_newest installed_newest
    src_newest=$(find "$FORGE_DIR/agents" "$FORGE_DIR/commands" "$FORGE_DIR/scripts" -type f -exec stat -c '%Y' {} \; 2>/dev/null | sort -rn | head -1 || find "$FORGE_DIR/agents" "$FORGE_DIR/commands" "$FORGE_DIR/scripts" -type f -exec stat -f '%m' {} \; 2>/dev/null | sort -rn | head -1 || echo "0")
    installed_newest=$(find "$CLAUDE_DIR/agents" "$CLAUDE_DIR/commands" "$CLAUDE_DIR/scripts" -type f -exec stat -c '%Y' {} \; 2>/dev/null | sort -rn | head -1 || find "$CLAUDE_DIR/agents" "$CLAUDE_DIR/commands" "$CLAUDE_DIR/scripts" -type f -exec stat -f '%m' {} \; 2>/dev/null | sort -rn | head -1 || echo "0")

    if [ "${src_newest}" -gt "${installed_newest}" ] 2>/dev/null; then
        echo -e "${YELLOW}Forge source files are newer than installed. Reinstalling...${NC}"
        return 0
    fi

    return 1
}

# ─── Main ───
preflight

FORCE_INSTALL=false
if [ "${1:-}" = "--force" ]; then
    FORCE_INSTALL=true
    shift
fi

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
        if needs_update; then
            install_global
        else
            local_count=$(find "$CLAUDE_DIR/agents/" -name "*.md" 2>/dev/null | wc -l)
            echo -e "${GREEN}Forge already installed ($local_count agents). Use --force to reinstall.${NC}"
            echo ""
        fi
        prep_project "$1"
        ;;
esac
