#!/bin/bash
# Test Dispatcher
# Routes test commands to appropriate handlers based on kast architecture

set -euo pipefail

# Source libraries
DISPATCHER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$DISPATCHER_DIR/../lib"
source "$LIB_DIR/utils.sh"
source "$LIB_DIR/discover.sh"

usage() {
    cat << EOF
Kast System Test Dispatcher

Usage:
  make test [MODE] [TYPE] [COMPONENTS...] [FLAGS]

Modes:
  syntax        - Syntax validation only
  comprehensive - Rendering + resource validation (default)
  snapshots     - Snapshot comparison + K8s schema validation
  all           - All of the above

Types:
  glyph         - Test glyphs (via kaster)
  trinket       - Test trinkets
  chart         - Test main charts
  spell         - Test individual spell
  book          - Test book

Components:
  Specific names or "all" for auto-discovery

Examples:
  make test syntax glyph vault
  make test comprehensive glyph vault istio
  make test all glyph
  make test spell example-api --book example-tdd-book
  make test book covenant-tyl

Legacy commands (deprecated):
  make test-comprehensive
  make test-glyphs-all
  make glyphs vault

EOF
    exit 0
}

# Parse arguments
parse_args() {
    MODE=""
    TYPE=""
    COMPONENTS=()
    FLAGS=()

    # If no args, show usage
    if [ $# -eq 0 ]; then
        usage
    fi

    # First arg might be mode or type
    local first="$1"
    shift || true

    case "$first" in
        syntax|comprehensive|snapshots|all)
            MODE="$first"
            # Next should be type
            if [ $# -gt 0 ]; then
                TYPE="$1"
                shift || true
            fi
            ;;
        glyph|glyphs|trinket|trinkets|chart|charts|spell|book)
            # No mode specified, use default
            MODE="comprehensive"
            TYPE="${first%s}"  # Remove trailing 's' if present
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            log_error "Unknown command: $first"
            echo "Run 'make test help' for usage"
            exit 1
            ;;
    esac

    # Remaining args are components or flags
    while [ $# -gt 0 ]; do
        case "$1" in
            --*)
                FLAGS+=("$1")
                if [ $# -gt 1 ] && [[ ! "$2" =~ ^-- ]]; then
                    FLAGS+=("$2")
                    shift
                fi
                ;;
            *)
                COMPONENTS+=("$1")
                ;;
        esac
        shift || true
    done

    # Normalize type (remove plural)
    case "$TYPE" in
        glyphs) TYPE="glyph" ;;
        trinkets) TYPE="trinket" ;;
        charts) TYPE="chart" ;;
    esac

    # If no components specified, default to "all"
    if [ ${#COMPONENTS[@]} -eq 0 ]; then
        COMPONENTS=("all")
    fi
}

# Dispatch to appropriate handler
dispatch() {
    case "$TYPE" in
        glyph)
            bash "$DISPATCHER_DIR/test-glyph.sh" "$MODE" "${COMPONENTS[@]}"
            ;;
        trinket)
            bash "$DISPATCHER_DIR/test-trinket.sh" "$MODE" "${COMPONENTS[@]}"
            ;;
        chart)
            bash "$DISPATCHER_DIR/test-chart.sh" "$MODE" "${COMPONENTS[@]}"
            ;;
        spell)
            # Spell requires special handling with flags
            bash "$DISPATCHER_DIR/test-spell.sh" "${COMPONENTS[0]}" "${FLAGS[@]}"
            ;;
        book)
            # Book also needs flags
            bash "$DISPATCHER_DIR/test-book.sh" "$MODE" "${COMPONENTS[@]}" "${FLAGS[@]}"
            ;;
        "")
            log_error "No type specified"
            echo "Run 'make test help' for usage"
            exit 1
            ;;
        *)
            log_error "Unknown type: $TYPE"
            echo "Valid types: glyph, trinket, chart, spell, book"
            exit 1
            ;;
    esac
}

# Main
main() {
    parse_args "$@"

    log_header "Kast System Testing"
    log_info "Mode: $MODE"
    log_info "Type: $TYPE"
    log_info "Components: ${COMPONENTS[*]}"
    if [ ${#FLAGS[@]} -gt 0 ]; then
        log_info "Flags: ${FLAGS[*]}"
    fi
    echo ""

    dispatch
}

main "$@"
