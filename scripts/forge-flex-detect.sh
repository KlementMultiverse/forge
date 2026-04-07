#!/bin/bash
# forge-flex-detect.sh — Detects FLEX_SIGNAL blocks in agent/command output
#
# Part of the FLEX CHECKPOINT system (Universal Loop Step 11).
# Scans agent output files or stdin for structured FLEX_SIGNAL blocks,
# parses TYPE/TARGET/STEP/WHAT/WHY/PROPOSED/SEVERITY fields, and reports
# them in human-readable or JSON format. Supports severity filtering and
# persists ADVISORY/BLOCKING signals to docs/flex-signals.log.
#
# Called by: PostToolUse Agent/Skill hooks (piped via CLAUDE_TOOL_RESULT)
# Writes to: $PROJECT_DIR/docs/flex-signals.log (ADVISORY + BLOCKING only)
#
# Exit codes:
#   0 = signal(s) found and valid
#   1 = no signal found (clean output)
#   2 = file missing, read error, or invalid arguments
#   3 = signal found but malformed (missing required fields)

set -euo pipefail

USAGE="Usage: forge-flex-detect.sh [OPTIONS] <file|-|--help>

Scans agent output for FLEX_SIGNAL blocks and reports them.

Options:
  --json              Output as JSON array
  --severity-filter   Filter by severity (comma-separated: INFO,ADVISORY,BLOCKING)
  --help, -h          Show this help

Exit codes:
  0 = signal(s) found and valid
  1 = no signal found (clean output)
  2 = file missing or read error
  3 = signal found but malformed (missing required fields)"

# Parse args
JSON_MODE=false
SEVERITY_FILTER=""
INPUT_FILE=""

while [ $# -gt 0 ]; do
    case "$1" in
        --help|-h) echo "$USAGE"; exit 0 ;;
        --json) JSON_MODE=true; shift ;;
        --severity-filter)
            if [ -z "${2:-}" ] || echo "${2:-}" | grep -q "^--"; then
                echo "Error: --severity-filter requires a value (e.g., BLOCKING,ADVISORY)" >&2
                exit 2
            fi
            SEVERITY_FILTER="$2"; shift 2 ;;
        *) INPUT_FILE="$1"; shift ;;
    esac
done

if [ -z "$INPUT_FILE" ]; then
    echo "Error: no input file specified" >&2
    echo "$USAGE" >&2
    exit 2
fi

# Read input
CONTENT=""
if [ "$INPUT_FILE" = "-" ]; then
    CONTENT=$(cat)
else
    if [ ! -f "$INPUT_FILE" ]; then
        echo "Error: file not found: $INPUT_FILE" >&2
        exit 2
    fi
    CONTENT=$(cat "$INPUT_FILE")
fi

# Check for FLEX_SIGNAL presence
if ! echo "$CONTENT" | grep -q "## FLEX_SIGNAL"; then
    exit 1
fi

# Parse all FLEX_SIGNAL blocks
SIGNALS=()
CURRENT_TYPE="" CURRENT_TARGET="" CURRENT_STEP="" CURRENT_WHAT=""
CURRENT_WHY="" CURRENT_PROPOSED="" CURRENT_SEVERITY=""
IN_SIGNAL=false
MALFORMED=false

while IFS= read -r line; do
    if echo "$line" | grep -q "^## FLEX_SIGNAL"; then
        # Save previous signal if exists
        if [ "$IN_SIGNAL" = true ] && [ -n "$CURRENT_TYPE" ]; then
            if [ -z "$CURRENT_TARGET" ] || [ -z "$CURRENT_SEVERITY" ] || [ -z "$CURRENT_STEP" ] || [ -z "$CURRENT_WHAT" ] || [ -z "$CURRENT_WHY" ] || [ -z "$CURRENT_PROPOSED" ]; then
                MALFORMED=true
            fi
            SIGNALS+=("$CURRENT_TYPE|$CURRENT_TARGET|$CURRENT_STEP|$CURRENT_WHAT|$CURRENT_WHY|$CURRENT_PROPOSED|$CURRENT_SEVERITY")
        fi
        IN_SIGNAL=true
        CURRENT_TYPE="" CURRENT_TARGET="" CURRENT_STEP="" CURRENT_WHAT=""
        CURRENT_WHY="" CURRENT_PROPOSED="" CURRENT_SEVERITY=""
        continue
    fi

    if [ "$IN_SIGNAL" = true ]; then
        case "$line" in
            TYPE:*) CURRENT_TYPE=$(echo "$line" | sed 's/^TYPE: *//') ;;
            TARGET:*) CURRENT_TARGET=$(echo "$line" | sed 's/^TARGET: *//') ;;
            STEP:*) CURRENT_STEP=$(echo "$line" | sed 's/^STEP: *//') ;;
            WHAT:*) CURRENT_WHAT=$(echo "$line" | sed 's/^WHAT: *//') ;;
            WHY:*) CURRENT_WHY=$(echo "$line" | sed 's/^WHY: *//') ;;
            PROPOSED:*) CURRENT_PROPOSED=$(echo "$line" | sed 's/^PROPOSED: *//') ;;
            SEVERITY:*) CURRENT_SEVERITY=$(echo "$line" | sed 's/^SEVERITY: *//') ;;
        esac
    fi
done <<< "$CONTENT"

# Save last signal
if [ "$IN_SIGNAL" = true ] && [ -n "$CURRENT_TYPE" ]; then
    if [ -z "$CURRENT_TARGET" ] || [ -z "$CURRENT_SEVERITY" ] || [ -z "$CURRENT_STEP" ] || [ -z "$CURRENT_WHAT" ] || [ -z "$CURRENT_WHY" ] || [ -z "$CURRENT_PROPOSED" ]; then
        MALFORMED=true
    fi
    SIGNALS+=("$CURRENT_TYPE|$CURRENT_TARGET|$CURRENT_STEP|$CURRENT_WHAT|$CURRENT_WHY|$CURRENT_PROPOSED|$CURRENT_SEVERITY")
fi

if [ ${#SIGNALS[@]} -eq 0 ]; then
    exit 1
fi

# Apply severity filter
FILTERED=()
for sig in "${SIGNALS[@]}"; do
    SIG_SEVERITY=$(echo "$sig" | cut -d'|' -f7)
    if [ -n "$SEVERITY_FILTER" ]; then
        MATCH=false
        IFS=',' read -ra FILTERS <<< "$SEVERITY_FILTER"
        for f in "${FILTERS[@]}"; do
            if [ "$f" = "$SIG_SEVERITY" ]; then
                MATCH=true
                break
            fi
        done
        if [ "$MATCH" = false ]; then
            continue
        fi
    fi
    FILTERED+=("$sig")
done

if [ ${#FILTERED[@]} -eq 0 ]; then
    exit 1
fi

# Persistence — write ADVISORY and BLOCKING to flex-signals.log
# NOTE: In hook context, writes to current project directory ($PWD)
PROJECT_DIR="${PROJECT_DIR:-$PWD}"
for sig in "${FILTERED[@]}"; do
    SIG_TYPE=$(echo "$sig" | cut -d'|' -f1)
    SIG_TARGET=$(echo "$sig" | cut -d'|' -f2)
    SIG_SEVERITY=$(echo "$sig" | cut -d'|' -f7)
    if [ "$SIG_SEVERITY" = "ADVISORY" ] || [ "$SIG_SEVERITY" = "BLOCKING" ]; then
        mkdir -p "$PROJECT_DIR/docs"
        STATUS="LOGGED"
        if [ "$SIG_SEVERITY" = "BLOCKING" ]; then
            STATUS="UNRESOLVED"
        fi
        echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) $SIG_SEVERITY $STATUS $SIG_TYPE $SIG_TARGET" >> "$PROJECT_DIR/docs/flex-signals.log"
    fi
done

# Output
if [ "$JSON_MODE" = true ]; then
    # JSON output
    echo "["
    FIRST=true
    for sig in "${FILTERED[@]}"; do
        IFS='|' read -r type target step what why proposed severity <<< "$sig"
        if [ "$FIRST" = true ]; then FIRST=false; else echo ","; fi
        python3 -c "
import json, sys
print(json.dumps({
    'type': sys.argv[1], 'target': sys.argv[2], 'step': sys.argv[3],
    'what': sys.argv[4], 'why': sys.argv[5], 'proposed': sys.argv[6],
    'severity': sys.argv[7]
}), end='')" "$type" "$target" "$step" "$what" "$why" "$proposed" "$severity"
    done
    echo ""
    echo "]"
else
    # Human-readable output
    for sig in "${FILTERED[@]}"; do
        IFS='|' read -r type target step what why proposed severity <<< "$sig"
        echo "FLEX_SIGNAL: $type → $target (severity: $severity)"
        echo "  STEP: $step"
        echo "  WHAT: $what"
        echo "  WHY: $why"
        echo "  PROPOSED: $proposed"
        echo ""
    done
fi

# Exit code
if [ "$MALFORMED" = true ]; then
    exit 3
fi
exit 0
