#!/bin/bash
# forge-deps.sh — dependency checker for forge scripts
# Sourced by: forge-enforce.sh, forge-fsm.sh, forge-phase-gate.sh
#
# Usage: source ~/.claude/scripts/forge-deps.sh && check_forge_deps

check_forge_deps() {
    local missing=0
    for cmd in python3 git jq; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "[FORGE ERROR] Required tool '$cmd' not found. Install it first."
            missing=1
        fi
    done
    # Optional tools — warn but don't block
    for cmd in gh docker; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "[FORGE WARNING] Optional tool '$cmd' not found. Some features disabled."
        fi
    done
    return $missing
}
