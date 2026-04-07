#!/usr/bin/env bash
# forge-handoff-check.sh — Universal agent handoff verification
# Checks if agent output faithfully represents discovery notes (Tier 1: structural)
# Part of the Universal Agent Execution Loop (#185)
#
# Usage:
#   forge-handoff-check.sh check <discovery-notes> <agent-output>
#   forge-handoff-check.sh --help
#
# Exit codes:
#   0 = all items covered
#   1 = missing items found (handoff incomplete)
#   2 = usage error or malformed input

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

show_help() {
    cat <<EOF
$SCRIPT_NAME — Universal agent handoff verification (Tier 1: structural)

USAGE:
  $SCRIPT_NAME check <discovery-notes-file> <agent-output-file>
  $SCRIPT_NAME dimensions <discovery-notes-file>
  $SCRIPT_NAME --help

COMMANDS:
  check       Compare discovery notes FINAL DIMENSIONS against agent output
  dimensions  Extract and display FINAL DIMENSIONS from discovery notes

DESCRIPTION:
  Reads the FINAL DIMENSIONS section from discovery notes and checks if
  each dimension appears in the agent output. Reports COVERED, MISSING,
  and INCOMPLETE items.

  This is Tier 1 (structural) verification — checks keyword presence.
  Tier 2 (semantic) verification requires LLM calls and is not implemented here.

  Discovery notes are the SINGLE SOURCE OF TRUTH:
  - NEVER invents new requirements
  - NEVER overrides user decisions
  - Only measures: "did output faithfully represent discovery notes?"

EXIT CODES:
  0  All items COVERED
  1  MISSING items found (handoff incomplete — agent must retry)
  2  Usage error

EXAMPLES:
  $SCRIPT_NAME check docs/forge-trace/A02_phase-a_step-s2_discovery-notes.md CLAUDE.md
  $SCRIPT_NAME dimensions docs/forge-trace/A02_phase-a_step-s2_discovery-notes.md
EOF
}

# Extract FINAL DIMENSIONS from discovery notes
extract_dimensions() {
    local notes_file="$1"
    if [ ! -f "$notes_file" ]; then
        echo "ERROR: Discovery notes not found: $notes_file" >&2
        return 1
    fi

    # Extract lines between "FINAL DIMENSIONS" and next "```" or EOF
    local in_dimensions=false
    while IFS= read -r line; do
        if echo "$line" | grep -qi "FINAL DIMENSIONS"; then
            in_dimensions=true
            continue
        fi
        if [ "$in_dimensions" = true ]; then
            # Stop at closing fence or empty section
            if echo "$line" | grep -q '```'; then
                break
            fi
            # Extract dimension: VALUE pairs
            if echo "$line" | grep -qE "^[A-Z0-9_]+:"; then
                echo "$line"
            fi
        fi
    done < "$notes_file"
}

# Check if a dimension value appears in agent output
check_dimension() {
    local dimension="$1"
    local value="$2"
    local output_file="$3"

    # Skip empty values
    if [ -z "$value" ] || [ "$value" = "[]" ] || [ "$value" = "none" ]; then
        echo "SKIP"
        return 0
    fi

    # Check if value keywords appear in output
    # Split value by commas and check each part
    local covered=0
    local total=0
    local IFS=','
    for item in $value; do
        item="$(echo "$item" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        # Remove brackets
        item="$(echo "$item" | sed 's/\[//g;s/\]//g')"
        if [ -z "$item" ]; then continue; fi
        total=$((total + 1))
        if grep -qFi "$item" "$output_file" 2>/dev/null; then
            covered=$((covered + 1))
        fi
    done

    if [ "$total" -eq 0 ]; then
        echo "SKIP"
    elif [ "$covered" -eq "$total" ]; then
        echo "COVERED"
    elif [ "$covered" -gt 0 ]; then
        echo "INCOMPLETE"
    else
        echo "MISSING"
    fi
}

# Main check command
do_check() {
    local notes_file="$1"
    local output_file="$2"

    if [ ! -f "$notes_file" ]; then
        echo "ERROR: Discovery notes not found: $notes_file" >&2
        exit 2
    fi
    if [ ! -f "$output_file" ]; then
        echo "ERROR: Agent output not found: $output_file" >&2
        exit 2
    fi

    echo "=== HANDOFF CHECK ==="
    echo "Source: $notes_file"
    echo "Target: $output_file"
    echo ""

    local missing=0
    local incomplete=0
    local covered=0
    local skipped=0

    while IFS=':' read -r dimension value; do
        dimension="$(echo "$dimension" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        value="$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

        result="$(check_dimension "$dimension" "$value" "$output_file")"

        case "$result" in
            COVERED)
                echo "  COVERED:    $dimension: $value"
                covered=$((covered + 1))
                ;;
            MISSING)
                echo "  MISSING:    $dimension: $value"
                missing=$((missing + 1))
                ;;
            INCOMPLETE)
                echo "  INCOMPLETE: $dimension: $value"
                incomplete=$((incomplete + 1))
                ;;
            SKIP)
                echo "  SKIP:       $dimension: (empty/none)"
                skipped=$((skipped + 1))
                ;;
        esac
    done < <(extract_dimensions "$notes_file")

    local total=$((covered + missing + incomplete))
    echo ""
    echo "=== SCORE ==="
    if [ "$total" -eq 0 ]; then
        echo "ERROR: No dimensions found in discovery notes — cannot verify handoff"
        echo "FAIL CLOSED: Malformed discovery notes or missing FINAL DIMENSIONS section"
        exit 2
    fi
    local score=$((covered * 100 / total))
    echo "COVERED: $covered / $total ($score%)"
    echo "MISSING: $missing"
    echo "INCOMPLETE: $incomplete"
    echo "SKIPPED: $skipped"

    if [ "$missing" -gt 0 ]; then
        echo ""
        echo "HANDOFF INCOMPLETE — agent must retry with enhanced prompt"
        echo "Add to prompt: YOU MISSED: [list missing items above]"
        exit 1
    fi

    if [ "$incomplete" -gt 0 ]; then
        echo ""
        echo "HANDOFF PARTIAL — some items need more detail"
        exit 1  # Partial handoff is incomplete — should trigger retry
    fi

    echo ""
    echo "HANDOFF COMPLETE — all dimensions propagated"
    exit 0
}

# Dispatch
case "${1:-}" in
    check)
        shift
        if [ $# -lt 2 ]; then
            echo "Usage: $SCRIPT_NAME check <discovery-notes> <agent-output>" >&2
            exit 2
        fi
        do_check "$1" "$2"
        ;;
    dimensions)
        shift
        if [ $# -lt 1 ]; then
            echo "Usage: $SCRIPT_NAME dimensions <discovery-notes>" >&2
            exit 2
        fi
        extract_dimensions "$1"
        ;;
    --help|-h|help)
        show_help
        ;;
    *)
        show_help
        exit 2
        ;;
esac
