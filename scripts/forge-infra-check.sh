#!/bin/bash
# Forge Infrastructure Check — ensures forge infrastructure is installed
# Handles: cloned repos (#118), wrong directory (#120), reset (#121)
#
# Usage:
#   forge-infra-check.sh check          — check if infrastructure exists
#   forge-infra-check.sh check-dir <d>  — check if directory is a valid project
#   forge-infra-check.sh --fix          — install missing infrastructure
#   forge-infra-check.sh --reset        — clear forge state for fresh start

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
D="${PROJECT_ROOT:-$PWD}"
CLAUDE_TEMPLATES="${HOME}/.claude/templates"

cmd_check() {
    local missing=0

    # Check required infrastructure
    [ -f "$D/.claude/settings.json" ] || { echo "[INFRA] missing: .claude/settings.json (hooks)"; missing=$((missing+1)); }
    [ -d "$D/.forge" ] || { echo "[INFRA] missing: .forge/ directory"; missing=$((missing+1)); }
    [ -f "$D/.forge/playbook/strategies.md" ] 2>/dev/null || { echo "[INFRA] missing: .forge/playbook/"; missing=$((missing+1)); }
    [ -d "$D/docs" ] || { echo "[INFRA] missing: docs/ directory"; missing=$((missing+1)); }

    if [ "$missing" -gt 0 ]; then
        echo "[INFRA] $missing items missing. Run: forge-infra-check.sh --fix"
        return 1
    else
        echo "[INFRA] All infrastructure present"
        return 0
    fi
}

cmd_check_dir() {
    local dir="${1:?Usage: forge-infra-check.sh check-dir <directory>}"

    # Check if it's a reasonable project directory
    if [ ! -d "$dir/.git" ] && [ ! -f "$dir/CLAUDE.md" ] && [ ! -f "$dir/package.json" ] && [ ! -f "$dir/pyproject.toml" ]; then
        echo "[INFRA] $dir is not a project directory (no .git, CLAUDE.md, package.json, or pyproject.toml)"
        return 1
    fi

    echo "[INFRA] $dir is a valid project directory"
    return 0
}

cmd_fix() {
    echo "[INFRA] Installing forge infrastructure..."

    # 1. Hooks
    mkdir -p "$D/.claude"
    if [ -f "$CLAUDE_TEMPLATES/hooks.json" ]; then
        cp "$CLAUDE_TEMPLATES/hooks.json" "$D/.claude/settings.json"
        echo "  ✅ .claude/settings.json (hooks)"
    else
        echo '{"hooks":{}}' > "$D/.claude/settings.json"
        echo "  ⚠ .claude/settings.json (minimal — templates not found)"
    fi

    # 2. Forge directory
    mkdir -p "$D/.forge/playbook" "$D/.forge/rules" "$D/.forge/agents" "$D/.forge/checkpoints"

    # 3. Playbook files
    [ -f "$D/.forge/playbook/strategies.md" ] || cat > "$D/.forge/playbook/strategies.md" << 'PLAY'
# Playbook — Strategies & Insights
# Format: [str-NNN] helpful=N harmful=N :: insight text
## STRATEGIES & INSIGHTS
## COMMON MISTAKES TO AVOID
## DOMAIN-SPECIFIC
PLAY

    [ -f "$D/.forge/playbook/mistakes.md" ] || cat > "$D/.forge/playbook/mistakes.md" << 'PLAY'
# Playbook — Mistakes
# Format: [mis-NNN] :: description + root cause + prevention
PLAY

    [ -f "$D/.forge/playbook/archived.md" ] || cat > "$D/.forge/playbook/archived.md" << 'PLAY'
# Playbook — Archived
# Pruned entries (harmful > helpful) are moved here.
PLAY

    # 4. Docs structure
    mkdir -p "$D/docs/forge-trace" "$D/docs/proposals" "$D/docs/retrospectives" "$D/docs/checkpoints" "$D/docs/issues"

    # 5. Timeline
    [ -f "$D/docs/forge-timeline.md" ] || cat > "$D/docs/forge-timeline.md" << TIMELINE
# Forge Timeline
This file tracks every step of the development process.
Updated automatically by /forge and all Forge commands.

## Legend
- DONE -- step completed successfully
- NEEDS_REVIEW -- output needs human review
- BLOCKED -- step failed, needs attention
- IN_PROGRESS -- currently running

---
<!-- Timeline entries appear below, newest first -->
TIMELINE

    # 6. Git hooks
    if [ -d "$D/.git/hooks" ]; then
        if [ -f "$CLAUDE_TEMPLATES/commit-msg" ]; then
            cp "$CLAUDE_TEMPLATES/commit-msg" "$D/.git/hooks/commit-msg"
            chmod +x "$D/.git/hooks/commit-msg"
            echo "  ✅ .git/hooks/commit-msg"
        fi
        if [ -f "$CLAUDE_TEMPLATES/pre-commit" ]; then
            cp "$CLAUDE_TEMPLATES/pre-commit" "$D/.git/hooks/pre-commit"
            chmod +x "$D/.git/hooks/pre-commit"
            echo "  ✅ .git/hooks/pre-commit"
        fi
    fi

    # 7. Utility scripts
    mkdir -p "$D/scripts"
    for script in traceability.sh sync-report.sh; do
        if [ -f "$HOME/.claude/scripts/$script" ]; then
            cp "$HOME/.claude/scripts/$script" "$D/scripts/" 2>/dev/null || true
        fi
    done
    chmod +x "$D/scripts/"*.sh 2>/dev/null || true

    echo "[INFRA] Infrastructure installed"
    return 0
}

cmd_reset() {
    echo "[INFRA] Resetting forge state for fresh start..."

    # Remove state files
    rm -f "$D/docs/forge-state.json"
    rm -f "$D/docs/forge-timeline.md"
    rm -f "$D/docs/suspect-reqs.json"
    rm -rf "$D/docs/forge-trace"
    rm -f "$D/docs/.builder-activity.log"
    rm -f "$D/docs/.observer-reviews.log"
    rm -f "$D/docs/.observer-reviewing"
    rm -rf "$D/docs/.approvals"

    # Recreate empty dirs
    mkdir -p "$D/docs/forge-trace"

    echo "[INFRA] State cleared. Run /forge to start fresh."
    return 0
}

case "${1:-help}" in
    check)     cmd_check ;;
    check-dir) shift; cmd_check_dir "$@" ;;
    --fix)     cmd_fix ;;
    --reset)   cmd_reset ;;
    *)
        echo "Forge Infrastructure Check"
        echo ""
        echo "Usage: forge-infra-check.sh <command>"
        echo ""
        echo "Commands:"
        echo "  check          Check if infrastructure exists"
        echo "  check-dir <d>  Check if directory is a valid project"
        echo "  --fix          Install missing infrastructure"
        echo "  --reset        Clear forge state for fresh start"
        ;;
esac
