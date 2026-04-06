#!/bin/bash
# Forge Auto-Sync — keeps all forge artifacts in sync automatically
# Called by pre-commit hook to sync everything before commit.
#
# Usage:
#   forge-auto-sync.sh queue <file>     — mark file as needing sync (called by PostToolUse)
#   forge-auto-sync.sh run              — execute all pending syncs (called by pre-commit)
#   forge-auto-sync.sh status           — show what's pending
#   forge-auto-sync.sh clear            — clear pending queue

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORGE_DIR="${FORGE_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"
D="${PROJECT_ROOT:-$PWD}"
SYNC_FILE="$D/docs/.forge-sync-pending"

cmd_queue() {
    local file="${1:?Usage: forge-auto-sync.sh queue <file>}"
    mkdir -p "$(dirname "$SYNC_FILE")"

    # Determine what syncs are needed based on file location
    local rel_file
    rel_file=$(python3 -c "import os; print(os.path.relpath('$file', '$FORGE_DIR'))" 2>/dev/null || basename "$file")

    case "$rel_file" in
        scripts/*|commands/*|agents/*|templates/*|rules/*)
            echo "readme_sync" >> "$SYNC_FILE"
            echo "registry_update" >> "$SYNC_FILE"
            ;;
    esac

    # If file has REQ tags, queue triangle check
    if [ -f "$file" ] && grep -qP '(?:\[REQ-\d+\]|REQ-[A-Z]+-\d+)' "$file" 2>/dev/null; then
        echo "triangle_check" >> "$SYNC_FILE"
    fi

    # Deduplicate
    if [ -f "$SYNC_FILE" ]; then
        sort -u "$SYNC_FILE" -o "$SYNC_FILE"
    fi
}

cmd_run() {
    if [ ! -f "$SYNC_FILE" ]; then
        return 0
    fi

    local syncs
    syncs=$(cat "$SYNC_FILE" 2>/dev/null | sort -u)

    if [ -z "$syncs" ]; then
        return 0
    fi

    echo "[FORGE-SYNC] Running pending syncs..."

    for sync in $syncs; do
        case "$sync" in
            readme_sync)
                echo "[FORGE-SYNC] Syncing README counts..."
                if [ -f "$FORGE_DIR/scripts/forge-readme-sync.sh" ]; then
                    bash "$FORGE_DIR/scripts/forge-readme-sync.sh" --fix 2>/dev/null | grep -E "PASS|Fix" | sed 's/^/  /'
                    # Stage the updated README if it changed
                    git add "$FORGE_DIR/README.md" 2>/dev/null || true
                fi
                ;;
            registry_update)
                echo "[FORGE-SYNC] Regenerating registry..."
                if [ -f "$FORGE_DIR/scripts/forge-registry.py" ]; then
                    python3 "$FORGE_DIR/scripts/forge-registry.py" "$FORGE_DIR" 2>/dev/null | head -3 | sed 's/^/  /'
                    git add "$FORGE_DIR/forge-registry.json" "$FORGE_DIR/docs/dependency-graph.md" 2>/dev/null || true
                fi
                ;;
            triangle_check)
                echo "[FORGE-SYNC] Checking triangle sync..."
                if [ -f "$D/SPEC.md" ] && [ -f "$FORGE_DIR/scripts/forge-triangle.sh" ]; then
                    bash "$FORGE_DIR/scripts/forge-triangle.sh" check 2>/dev/null | tail -2 | sed 's/^/  /'
                fi
                ;;
        esac
    done

    # Clear pending
    rm -f "$SYNC_FILE"
    echo "[FORGE-SYNC] All syncs complete"
}

cmd_status() {
    if [ ! -f "$SYNC_FILE" ]; then
        echo "[FORGE-SYNC] No pending syncs"
        return 0
    fi

    echo "[FORGE-SYNC] Pending syncs:"
    cat "$SYNC_FILE" | sort -u | sed 's/^/  - /'
}

cmd_clear() {
    rm -f "$SYNC_FILE"
    echo "[FORGE-SYNC] Cleared pending syncs"
}

case "${1:-help}" in
    queue)   shift; cmd_queue "$@" ;;
    run)     cmd_run ;;
    status)  cmd_status ;;
    clear)   cmd_clear ;;
    *)
        echo "Forge Auto-Sync — keeps artifacts in sync automatically"
        echo ""
        echo "Usage: forge-auto-sync.sh <command> [args]"
        echo ""
        echo "Commands:"
        echo "  queue <file>   Mark file for sync (called by PostToolUse)"
        echo "  run            Execute pending syncs (called by pre-commit)"
        echo "  status         Show pending syncs"
        echo "  clear          Clear pending queue"
        ;;
esac
