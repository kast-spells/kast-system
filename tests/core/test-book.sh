#!/bin/bash
# Book Testing Module
# Tests books (covenant, etc.)

set -euo pipefail

# Source libraries (save SCRIPT_DIR before sourcing, as libraries override it)
BOOK_TEST_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$BOOK_TEST_SCRIPT_DIR/../lib"
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
# Iterates through all chapters and spells in a book, testing each spell individually
# Note: Spell names are read from the YAML 'name' field, not from filename
# This is because librarian generates Applications using the 'name' field
test_regular_book() {
    local book="$1"
    local mode="${2:-comprehensive}"

    log_header "Testing Regular Book: $book"

    local book_path=$(get_book_path "$book")

    if [ ! -d "$book_path" ]; then
        log_error "Book path not found: $book_path"
        increment_failed
        return 1
    fi

    # Get all chapters (directories that don't start with _)
    local chapters=()
    for chapter_dir in "$book_path"/*/; do
        [ -d "$chapter_dir" ] || continue
        local chapter_name=$(basename "$chapter_dir")
        # Skip special directories (lexicon, etc.)
        [[ "$chapter_name" =~ ^_ ]] && continue
        chapters+=("$chapter_name")
    done

    log_info "Found ${#chapters[@]} chapter(s) in book: $book"

    if [ ${#chapters[@]} -eq 0 ]; then
        log_warning "No chapters found in book: $book"
        increment_skipped
        return 0
    fi

    # Test each spell in each chapter
    local total=0
    local passed=0
    local failed=0
    local failed_spells=()

    for chapter in "${chapters[@]}"; do
        log_section "Chapter: $chapter"

        # Find all spell files (*.yaml but not index.yaml)
        local spell_files=()
        for spell_file in "$book_path/$chapter"/*.yaml; do
            [ -f "$spell_file" ] || continue
            local file_name=$(basename "$spell_file" .yaml)

            # Skip index files
            [[ "$file_name" == "index" ]] && continue

            # Read spell name from YAML file (name field)
            local spell_name
            if command -v yq &>/dev/null; then
                spell_name=$(yq eval '.name' "$spell_file" 2>/dev/null)
                if [ -z "$spell_name" ] || [ "$spell_name" = "null" ]; then
                    # Fallback to filename if name field not found
                    spell_name="$file_name"
                fi
            else
                # Fallback to filename if yq not available
                spell_name="$file_name"
            fi

            spell_files+=("$file_name|$spell_name")
        done

        if [ ${#spell_files[@]} -eq 0 ]; then
            log_info "  No spells in chapter: $chapter"
            continue
        fi

        log_info "  Testing ${#spell_files[@]} spell(s)"
        echo ""

        for spell_entry in "${spell_files[@]}"; do
            total=$((total + 1))

            # Split entry into filename and spell name
            local file_name="${spell_entry%%|*}"
            local spell_name="${spell_entry#*|}"

            log_info "  Testing spell: $chapter/$file_name (name: $spell_name)"

            # Call test-spell.sh with book parameter
            local spell_output
            if spell_output=$(bash "$BOOK_TEST_SCRIPT_DIR/test-spell.sh" "$spell_name" --book "$book" 2>&1); then
                log_success "  $chapter/$file_name (PASS)"
                passed=$((passed + 1))
            else
                log_error "  $chapter/$file_name (FAIL)"
                failed=$((failed + 1))
                failed_spells+=("$chapter/$file_name")

                # Show error details in verbose mode
                if [ "$mode" = "debug" ] || [ "$mode" = "verbose" ]; then
                    echo "$spell_output" | head -20
                fi
            fi
            echo ""
        done
    done

    # Print summary
    echo ""
    log_header "Book Test Summary: $book"
    log_info "Total spells tested: $total"
    log_success "Passed: $passed"

    if [ $failed -gt 0 ]; then
        log_error "Failed: $failed"
        log_info "Failed spells:"
        for failed_spell in "${failed_spells[@]}"; do
            log_info "  - $failed_spell"
        done
    else
        log_success "All spells passed!"
    fi

    # Update global counters
    if [ $failed -eq 0 ]; then
        increment_passed
        return 0
    else
        increment_failed
        return 1
    fi
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
