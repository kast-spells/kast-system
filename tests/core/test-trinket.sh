#!/bin/bash
# Trinket Testing Module
# Tests trinkets (specialized charts like tarot, microspell)

set -euo pipefail

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"
source "$LIB_DIR/utils.sh"
source "$LIB_DIR/discover.sh"
source "$LIB_DIR/validate.sh"

REPO_ROOT="$(get_repo_root)"
OUTPUT_DIR="$REPO_ROOT/output-test"

# Test single trinket
test_trinket() {
    local trinket="$1"
    local mode="${2:-comprehensive}"

    if ! trinket_exists "$trinket"; then
        log_error "Trinket not found: $trinket"
        return 1
    fi

    local trinket_path=$(get_trinket_path "$trinket")

    if ! validate_has_examples "$trinket_path"; then
        log_warning "$trinket: No examples found"
        increment_skipped
        return 2
    fi

    log_section "Testing trinket: $trinket"

    local examples=$(get_trinket_examples "$trinket")
    local example_count=$(echo "$examples" | wc -w)

    log_info "$trinket: Found $example_count examples"

    local failed=0

    for example_file in $examples; do
        local example_name=$(basename "$example_file" .yaml)
        local test_name="test-$trinket-$example_name"

        case "$mode" in
            syntax)
                test_trinket_syntax "$trinket" "$trinket_path" "$example_file" "$test_name"
                ;;
            comprehensive)
                test_trinket_comprehensive "$trinket" "$trinket_path" "$example_file" "$test_name"
                ;;
            snapshots)
                test_trinket_snapshots "$trinket" "$trinket_path" "$example_file" "$test_name"
                ;;
            all)
                test_trinket_all "$trinket" "$trinket_path" "$example_file" "$test_name"
                ;;
            *)
                log_error "Unknown mode: $mode"
                return 1
                ;;
        esac

        if [ $? -ne 0 ]; then
            failed=$((failed + 1))
        fi
    done

    if [ $failed -eq 0 ]; then
        log_success "$trinket: All tests passed ($example_count/$example_count)"
        return 0
    else
        log_error "$trinket: $failed/$example_count tests failed"
        return 1
    fi
}

# Test trinket syntax
test_trinket_syntax() {
    local trinket="$1"
    local trinket_path="$2"
    local example_file="$3"
    local test_name="$4"
    local example_name=$(basename "$example_file" .yaml)

    if validate_syntax "$trinket_path" "$example_file"; then
        log_success "$trinket/$example_name: Syntax valid"
        increment_passed
        return 0
    else
        log_error "$trinket/$example_name: Syntax validation failed"
        increment_failed
        return 1
    fi
}

# Test trinket comprehensive
test_trinket_comprehensive() {
    local trinket="$1"
    local trinket_path="$2"
    local example_file="$3"
    local test_name="$4"
    local example_name=$(basename "$example_file" .yaml)

    local output=$(render_template "$trinket_path" "$example_file" "$test_name")

    if has_errors "$output"; then
        log_error "$trinket/$example_name: Rendering failed"
        get_errors "$output" | while IFS= read -r line; do
            echo "  $line"
        done
        increment_failed
        return 1
    fi

    local resource_count=$(count_resources "$output")

    if [ "$resource_count" -eq 0 ]; then
        log_error "$trinket/$example_name: No resources generated"
        increment_failed
        return 1
    fi

    log_success "$trinket/$example_name: Generated $resource_count resources"
    increment_passed
    return 0
}

# Test trinket with snapshots
test_trinket_snapshots() {
    local trinket="$1"
    local trinket_path="$2"
    local example_file="$3"
    local test_name="$4"
    local example_name=$(basename "$example_file" .yaml)

    mkdir -p "$OUTPUT_DIR/$trinket"

    local actual_file="$OUTPUT_DIR/$trinket/$example_name.yaml"
    local expected_file="$OUTPUT_DIR/$trinket/$example_name.expected.yaml"

    local output=$(render_template "$trinket_path" "$example_file" "$test_name")

    if has_errors "$output"; then
        log_error "$trinket/$example_name: Rendering failed"
        increment_failed
        return 1
    fi

    echo "$output" > "$actual_file"

    local snapshot_result=$(compare_snapshot "$actual_file" "$expected_file")
    local snapshot_exit=$?

    if [ $snapshot_exit -eq 0 ]; then
        log_success "$trinket/$example_name: Snapshot matches"
        increment_passed
        return 0
    elif [ $snapshot_exit -eq 2 ]; then
        log_warning "$trinket/$example_name: No snapshot (run: make generate-snapshots CHART=$trinket)"
        increment_skipped
        return 0
    else
        log_error "$trinket/$example_name: Snapshot differs"
        log_info "  Run: diff $actual_file $expected_file"
        increment_failed
        return 1
    fi
}

# Test trinket with all modes
test_trinket_all() {
    local trinket="$1"
    local trinket_path="$2"
    local example_file="$3"
    local test_name="$4"

    local failed=0

    # Don't triple-count, just run all validations
    local saved_passed=$TESTS_PASSED
    local saved_failed=$TESTS_FAILED
    local saved_skipped=$TESTS_SKIPPED

    test_trinket_syntax "$trinket" "$trinket_path" "$example_file" "$test_name"
    test_trinket_comprehensive "$trinket" "$trinket_path" "$example_file" "$test_name"
    test_trinket_snapshots "$trinket" "$trinket_path" "$example_file" "$test_name"

    # Only count once (use comprehensive result)
    TESTS_PASSED=$((saved_passed + 1))
    TESTS_FAILED=$saved_failed
    TESTS_SKIPPED=$saved_skipped

    return 0
}

# Test multiple trinkets
test_trinkets() {
    local mode="$1"
    shift
    local trinkets=("$@")

    if [ ${#trinkets[@]} -eq 0 ] || [ "${trinkets[0]}" = "all" ]; then
        log_info "Auto-discovering trinkets..."
        trinkets=($(discover_trinkets))

        log_info "Found ${#trinkets[@]} trinkets"
    fi

    if [ ${#trinkets[@]} -eq 0 ]; then
        log_error "No trinkets found to test"
        return 1
    fi

    log_header "Testing Trinkets (mode: $mode)"

    local failed_trinkets=()

    for trinket in "${trinkets[@]}"; do
        if ! test_trinket "$trinket" "$mode"; then
            if [ $? -eq 1 ]; then
                failed_trinkets+=("$trinket")
            fi
        fi
    done

    print_summary

    if [ ${#failed_trinkets[@]} -gt 0 ]; then
        log_error "Failed trinkets: ${failed_trinkets[*]}"
        return 1
    fi

    return 0
}

# Main entry point
main() {
    local mode="${1:-comprehensive}"
    shift || true

    check_required_commands helm || exit 1

    test_trinkets "$mode" "$@"
}

# Only run main if executed directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
