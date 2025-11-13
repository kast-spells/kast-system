#!/bin/bash
# Book Testing Module
# Tests books (covenant, etc.)

set -euo pipefail

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"
source "$LIB_DIR/utils.sh"
source "$LIB_DIR/discover.sh"
source "$LIB_DIR/validate.sh"

REPO_ROOT="$(get_repo_root)"

# Detect book type
detect_book_type() {
    local book="$1"
    local book_path=$(get_book_path "$book")

    if [ ! -f "$book_path/index.yaml" ]; then
        # Try covenant path
        local covenant_path="${COVENANT_BOOKRACK_PATH:-$HOME/_home/the.yaml.life/proto-the-yaml-life/bookrack}"
        if [ -f "$covenant_path/$book/index.yaml" ]; then
            if grep -q "realm:" "$covenant_path/$book/index.yaml" 2>/dev/null; then
                echo "covenant"
                return 0
            fi
        fi

        echo "unknown"
        return 1
    fi

    # Check if it's a covenant book (has realm config)
    if grep -q "realm:" "$book_path/index.yaml" 2>/dev/null; then
        echo "covenant"
        return 0
    fi

    # Default to regular book
    echo "regular"
    return 0
}

# Test covenant book
test_covenant_book() {
    local book="$1"
    local mode="${2:-comprehensive}"
    shift 2 || true

    local legacy_script="$REPO_ROOT/tests/scripts/test-covenant-book.sh"

    if [ ! -f "$legacy_script" ]; then
        log_error "Covenant book testing requires: $legacy_script"
        return 1
    fi

    log_header "Testing Covenant Book: $book"

    # Parse flags
    local chapter=""
    local type_filter=""
    local debug_mode=""

    chapter=$(get_flag_value "chapter" "$@") || chapter=""
    type_filter=$(get_flag_value "type" "$@") || type_filter=""

    if parse_flag "debug" "$@"; then
        debug_mode="--debug"
    fi

    # Build arguments for legacy script
    local args=("$book")

    if [ -n "$chapter" ]; then
        args+=("--chapter-filter" "$chapter")
    fi

    if [ -n "$type_filter" ]; then
        args+=("--type" "$type_filter")
    fi

    if [ -n "$debug_mode" ]; then
        args+=("$debug_mode")
    fi

    # Run legacy covenant testing
    if bash "$legacy_script" "${args[@]}"; then
        log_success "Covenant book test passed: $book"
        increment_passed
        return 0
    else
        log_error "Covenant book test failed: $book"
        increment_failed
        return 1
    fi
}

# Test regular book
test_regular_book() {
    local book="$1"
    local mode="${2:-comprehensive}"

    log_header "Testing Regular Book: $book"

    log_warning "Regular book testing not yet fully implemented"
    log_info "Book structure:"

    local book_path=$(get_book_path "$book")

    if [ -f "$book_path/index.yaml" ]; then
        log_info "  index.yaml: exists"
    fi

    # List chapters
    local chapters=($(find "$book_path" -mindepth 1 -maxdepth 1 -type d ! -name "_*" 2>/dev/null))
    if [ ${#chapters[@]} -gt 0 ]; then
        log_info "  chapters: ${#chapters[@]}"
        for chapter_dir in "${chapters[@]}"; do
            local chapter_name=$(basename "$chapter_dir")
            local spells=$(find "$chapter_dir" -name "*.yaml" -type f ! -name "index.yaml" 2>/dev/null | wc -l)
            log_info "    - $chapter_name: $spells spells"
        done
    fi

    increment_skipped
    return 0
}

# Test book
test_book() {
    local book="$1"
    local mode="${2:-comprehensive}"
    shift 2 || true

    local book_type=$(detect_book_type "$book")

    case "$book_type" in
        covenant)
            test_covenant_book "$book" "$mode" "$@"
            ;;
        regular)
            test_regular_book "$book" "$mode"
            ;;
        unknown)
            log_error "Book not found: $book"
            log_info "Searched in:"
            log_info "  - ${BOOKRACK_PATH:-$REPO_ROOT/bookrack}"
            log_info "  - ${COVENANT_BOOKRACK_PATH:-$HOME/_home/the.yaml.life/proto-the-yaml-life/bookrack}"
            increment_failed
            return 1
            ;;
        *)
            log_error "Unknown book type: $book_type"
            increment_failed
            return 1
            ;;
    esac
}

# Test multiple books
test_books() {
    local mode="$1"
    shift
    local books=("$@")

    # Extract flags before books
    local flags=()
    local book_names=()

    for arg in "${books[@]}"; do
        if [[ "$arg" =~ ^-- ]]; then
            flags+=("$arg")
        else
            book_names+=("$arg")
        fi
    done

    if [ ${#book_names[@]} -eq 0 ] || [ "${book_names[0]}" = "all" ]; then
        log_info "Auto-discovering books..."

        # Discover both regular and covenant books
        local regular_books=($(discover_books))
        local covenant_books=($(discover_covenant_books))

        book_names=("${regular_books[@]}" "${covenant_books[@]}")

        log_info "Found ${#book_names[@]} books total"
        if [ ${#regular_books[@]} -gt 0 ]; then
            log_info "  Regular: ${#regular_books[@]}"
        fi
        if [ ${#covenant_books[@]} -gt 0 ]; then
            log_info "  Covenant: ${#covenant_books[@]}"
        fi
    fi

    if [ ${#book_names[@]} -eq 0 ]; then
        log_error "No books found to test"
        return 1
    fi

    log_header "Testing Books (mode: $mode)"

    local failed_books=()

    for book in "${book_names[@]}"; do
        if ! test_book "$book" "$mode" "${flags[@]}"; then
            if [ $? -eq 1 ]; then
                failed_books+=("$book")
            fi
        fi
        echo ""
    done

    print_summary

    if [ ${#failed_books[@]} -gt 0 ]; then
        log_error "Failed books: ${failed_books[*]}"
        return 1
    fi

    return 0
}

# Main entry point
main() {
    local mode="${1:-comprehensive}"
    shift || true

    check_required_commands helm yq || exit 1

    test_books "$mode" "$@"
}

# Only run main if executed directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
