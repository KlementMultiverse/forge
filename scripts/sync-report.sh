#!/bin/bash
# Forge Sync Report
# Comprehensive report on spec/test/code alignment
# Combines traceability check with additional metrics

set -e

PROJECT_ROOT="${1:-.}"
SPEC_FILE="$PROJECT_ROOT/SPEC.md"

echo "╔══════════════════════════════════════╗"
echo "║       FORGE SYNC REPORT              ║"
echo "╚══════════════════════════════════════╝"
echo ""

# 1. Run traceability check
echo "── 1. TRACEABILITY ──"
if [ -f "$SPEC_FILE" ]; then
    SPEC_REQS=$(grep -oP '\[REQ-\d+\]' "$SPEC_FILE" 2>/dev/null | sort -u | wc -l)
    TEST_REQS=$(grep -roPh '\[REQ-\d+\]' "$PROJECT_ROOT/tests/" "$PROJECT_ROOT/apps/*/tests.py" 2>/dev/null | sort -u | wc -l || echo "0")
    CODE_REQS=$(grep -roPh '\[REQ-\d+\]' "$PROJECT_ROOT/apps/" --include="*.py" --exclude="*test*" 2>/dev/null | sort -u | wc -l || echo "0")
    echo "  Spec requirements: $SPEC_REQS"
    echo "  Tested:            $TEST_REQS"
    echo "  Implemented:       $CODE_REQS"
else
    echo "  SPEC.md not found — skipping traceability"
    SPEC_REQS=0
fi

# 2. File size check (300-line limit)
echo ""
echo "── 2. FILE SIZE ──"
OVERSIZED=$(find "$PROJECT_ROOT" -name "*.py" -not -path "*/.venv/*" -not -path "*/__pycache__/*" -not -path "*/.git/*" -exec awk 'END{if(NR>300)print FILENAME": "NR" lines"}' {} \;)
if [ -z "$OVERSIZED" ]; then
    echo "  All files under 300 lines ✓"
else
    echo "  OVERSIZED FILES:"
    echo "$OVERSIZED" | sed 's/^/    /'
fi

# 3. Test count
echo ""
echo "── 3. TESTS ──"
TEST_FILES=$(find "$PROJECT_ROOT" -name "test*.py" -not -path "*/.venv/*" -not -path "*/.git/*" 2>/dev/null | wc -l)
TEST_FUNCS=$(grep -rch "def test_" "$PROJECT_ROOT" --include="test*.py" 2>/dev/null | awk '{s+=$1} END {print s+0}')
echo "  Test files:     $TEST_FILES"
echo "  Test functions: $TEST_FUNCS"

# 4. Playbook health
echo ""
echo "── 4. PLAYBOOK ──"
if [ -f "$PROJECT_ROOT/playbook/strategies.md" ] || [ -f "$HOME/.claude/playbook/strategies.md" ]; then
    PLAYBOOK="${PROJECT_ROOT}/playbook/strategies.md"
    [ ! -f "$PLAYBOOK" ] && PLAYBOOK="$HOME/.claude/playbook/strategies.md"
    TOTAL_STRATS=$(grep -c '\[str-' "$PLAYBOOK" 2>/dev/null || echo "0")
    HIGH_SCORE=$(grep -oP 'helpful=\d+' "$PLAYBOOK" 2>/dev/null | sort -t= -k2 -nr | head -1 || echo "none")
    echo "  Active strategies: $TOTAL_STRATS"
    echo "  Highest score:     $HIGH_SCORE"
else
    echo "  No playbook found"
fi

# 5. Git checkpoint status
echo ""
echo "── 5. GIT STATUS ──"
if [ -d "$PROJECT_ROOT/.git" ]; then
    BRANCH=$(cd "$PROJECT_ROOT" && git branch --show-current 2>/dev/null)
    COMMITS=$(cd "$PROJECT_ROOT" && git rev-list --count HEAD 2>/dev/null || echo "0")
    UNCOMMITTED=$(cd "$PROJECT_ROOT" && git status --porcelain 2>/dev/null | wc -l)
    echo "  Branch:      $BRANCH"
    echo "  Commits:     $COMMITS"
    echo "  Uncommitted: $UNCOMMITTED files"
else
    echo "  Not a git repository"
fi

# Summary
echo ""
echo "══════════════════════════════════════"
if [ "$SPEC_REQS" -gt 0 ]; then
    if [ "$TEST_REQS" -ge "$SPEC_REQS" ] && [ -z "$OVERSIZED" ]; then
        echo "  STATUS: SYNCED ✓"
    else
        echo "  STATUS: GAPS FOUND — review above"
    fi
else
    echo "  STATUS: NO SPEC — run /generate-spec first"
fi
echo "══════════════════════════════════════"
