#!/bin/bash
# Forge README Sync — automatically updates component counts in README.md
# Run after any component is added/removed to keep README accurate.
#
# Usage:
#   forge-readme-sync.sh          # check if README is in sync
#   forge-readme-sync.sh --fix    # auto-update counts in README

set -uo pipefail

FORGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
README="$FORGE_DIR/README.md"

# Count actual components
AGENTS=$(find "$FORGE_DIR/agents" -name "*.md" -not -name "README.md" | wc -l)
COMMANDS=$(find "$FORGE_DIR/commands" -maxdepth 1 -name "*.md" | wc -l)
RULES=$(find "$FORGE_DIR/rules" -name "*.md" | wc -l)
SCRIPTS=$(find "$FORGE_DIR/scripts" -name "*.sh" -o -name "*.py" | wc -l)
TEMPLATES=$(find "$FORGE_DIR/templates" -type f | wc -l)
BATS_TESTS=$(grep -rh '@test ' "$FORGE_DIR/tests/bash/" 2>/dev/null | wc -l)
PY_TESTS=$(grep -rh 'def test_' "$FORGE_DIR/tests/python/" 2>/dev/null | wc -l)
TOTAL_TESTS=$((BATS_TESTS + PY_TESTS))

# Check hooks
HOOK_EVENTS=$(python3 -c "import json; d=json.load(open('$FORGE_DIR/templates/hooks.json')); print(len(d['hooks']))" 2>/dev/null || echo "?")
HOOK_GROUPS=$(python3 -c "import json; d=json.load(open('$FORGE_DIR/templates/hooks.json')); print(sum(len(v) for v in d['hooks'].values()))" 2>/dev/null || echo "?")

echo "=== Forge Component Counts ==="
echo "  Agents:     $AGENTS"
echo "  Commands:   $COMMANDS"
echo "  Rules:      $RULES"
echo "  Scripts:    $SCRIPTS"
echo "  Templates:  $TEMPLATES"
echo "  Tests:      $TOTAL_TESTS ($BATS_TESTS BATS + $PY_TESTS pytest)"
echo "  Hooks:      $HOOK_GROUPS groups across $HOOK_EVENTS events"
echo ""

# Check README matches
DRIFT=0
check_count() {
    local name="$1"
    local actual="$2"
    local readme_val
    readme_val=$(grep -oP "\\| $name \\| \\K\\d+" "$README" 2>/dev/null | head -1)
    if [ -z "$readme_val" ]; then
        echo "  ⚠ $name: not found in README"
        DRIFT=$((DRIFT + 1))
    elif [ "$readme_val" != "$actual" ]; then
        echo "  ❌ $name: README says $readme_val, actual is $actual"
        DRIFT=$((DRIFT + 1))
    else
        echo "  ✅ $name: $actual"
    fi
}

echo "--- README Sync Check ---"
check_count "Agents" "$AGENTS"
check_count "Commands" "$COMMANDS"
check_count "Rules" "$RULES"
check_count "Scripts" "$SCRIPTS"
check_count "Templates" "$TEMPLATES"
check_count "Tests" "$TOTAL_TESTS"
echo ""

if [ "$DRIFT" -eq 0 ]; then
    echo "PASS: README is in sync"
    exit 0
fi

if [ "${1:-}" = "--fix" ]; then
    echo "Fixing README counts..."
    sed -i "s/| Agents | [0-9]*/| Agents | $AGENTS/" "$README"
    sed -i "s/| Commands | [0-9]*/| Commands | $COMMANDS/" "$README"
    sed -i "s/| Rules | [0-9]*/| Rules | $RULES/" "$README"
    sed -i "s/| Scripts | [0-9]*/| Scripts | $SCRIPTS/" "$README"
    sed -i "s/| Templates | [0-9]*/| Templates | $TEMPLATES/" "$README"
    sed -i "s/| Tests | [0-9]*/| Tests | $TOTAL_TESTS/" "$README"
    echo "Done. Verify with: forge-readme-sync.sh"
else
    echo "DRIFT: $DRIFT counts out of sync"
    echo "Run: forge-readme-sync.sh --fix"
    exit 1
fi
