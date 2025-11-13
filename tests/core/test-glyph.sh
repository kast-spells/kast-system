#!/bin/bash
# Glyph Testing Module
# Tests glyphs through kaster orchestration

set -euo pipefail

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"
source "$LIB_DIR/utils.sh"
source "$LIB_DIR/discover.sh"
source "$LIB_DIR/validate.sh"

REPO_ROOT="$(get_repo_root)"
KASTER_DIR="$REPO_ROOT/charts/kaster"
OUTPUT_DIR="$REPO_ROOT/output-test"

# Test single glyph
test_glyph() {
    local glyph="$1"
    local mode="${2:-comprehensive}"

    if ! glyph_exists "$glyph"; then
        log_error "Glyph not found: $glyph"
        return 1
    fi

    local glyph_path=$(get_glyph_path "$glyph")

    if ! validate_has_examples "$glyph_path"; then
        log_warning "$glyph: No examples found"
        increment_skipped
        return 2
    fi

    log_section "Testing glyph: $glyph"

    local examples=$(get_glyph_examples "$glyph")
    local example_count=$(echo "$examples" | wc -w)

    log_info "$glyph: Found $example_count examples"

    local failed=0

    for example_file in $examples; do
        local example_name=$(basename "$example_file" .yaml)
        local test_name="test-$glyph-$example_name"

        case "$mode" in
            syntax)
                test_glyph_syntax "$glyph" "$example_file" "$test_name"
                ;;
            comprehensive)
                test_glyph_comprehensive "$glyph" "$example_file" "$test_name"
                ;;
            snapshots)
                test_glyph_snapshots "$glyph" "$example_file" "$test_name"
                ;;
            all)
                test_glyph_all "$glyph" "$example_file" "$test_name"
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
        log_success "$glyph: All tests passed ($example_count/$example_count)"
        return 0
    else
        log_error "$glyph: $failed/$example_count tests failed"
        return 1
    fi
}

# Test glyph syntax
test_glyph_syntax() {
    local glyph="$1"
    local example_file="$2"
    local test_name="$3"
    local example_name=$(basename "$example_file" .yaml)

    if validate_syntax "$KASTER_DIR" "$example_file"; then
        log_success "$glyph/$example_name: Syntax valid"
        increment_passed
        return 0
    else
        log_error "$glyph/$example_name: Syntax validation failed"
        increment_failed
        return 1
    fi
}

# Test glyph comprehensive
test_glyph_comprehensive() {
    local glyph="$1"
    local example_file="$2"
    local test_name="$3"
    local example_name=$(basename "$example_file" .yaml)

    local output=$(render_template "$KASTER_DIR" "$example_file" "$test_name")

    if has_errors "$output"; then
        log_error "$glyph/$example_name: Rendering failed"
        get_errors "$output" | while IFS= read -r line; do
            echo "  $line"
        done
        increment_failed
        return 1
    fi

    local resource_count=$(count_resources "$output")

    if [ "$resource_count" -eq 0 ]; then
        log_error "$glyph/$example_name: No resources generated"
        increment_failed
        return 1
    fi

    log_success "$glyph/$example_name: Generated $resource_count resources"
    increment_passed
    return 0
}

# Test glyph with snapshots
test_glyph_snapshots() {
    local glyph="$1"
    local example_file="$2"
    local test_name="$3"
    local example_name=$(basename "$example_file" .yaml)

    mkdir -p "$OUTPUT_DIR/$glyph"

    local actual_file="$OUTPUT_DIR/$glyph/$example_name.yaml"
    local expected_file="$OUTPUT_DIR/$glyph/$example_name.expected.yaml"

    local output=$(render_template "$KASTER_DIR" "$example_file" "$test_name")

    if has_errors "$output"; then
        log_error "$glyph/$example_name: Rendering failed"
        increment_failed
        return 1
    fi

    echo "$output" > "$actual_file"

    local snapshot_result=$(compare_snapshot "$actual_file" "$expected_file")
    local snapshot_exit=$?

    if [ $snapshot_exit -eq 0 ]; then
        log_success "$glyph/$example_name: Snapshot matches"
        increment_passed
        return 0
    elif [ $snapshot_exit -eq 2 ]; then
        log_warning "$glyph/$example_name: No snapshot (run: make generate-expected GLYPH=$glyph)"
        increment_skipped
        return 0
    else
        log_error "$glyph/$example_name: Snapshot differs"
        log_info "  Run: diff $actual_file $expected_file"
        increment_failed
        return 1
    fi
}

# Test glyph with all modes
test_glyph_all() {
    local glyph="$1"
    local example_file="$2"
    local test_name="$3"
    local example_name=$(basename "$example_file" .yaml)

    local failed=0

    # Syntax
    if ! test_glyph_syntax "$glyph" "$example_file" "$test_name"; then
        failed=$((failed + 1))
    fi

    # Comprehensive (don't increment counters again, already done in syntax)
    TESTS_PASSED=$((TESTS_PASSED - 1))
    TESTS_FAILED=$((TESTS_FAILED - failed))

    if ! test_glyph_comprehensive "$glyph" "$example_file" "$test_name"; then
        failed=$((failed + 1))
    fi

    # Snapshots
    TESTS_PASSED=$((TESTS_PASSED - 1))
    TESTS_FAILED=$((TESTS_FAILED - failed + 1))
    TESTS_SKIPPED=$((TESTS_SKIPPED > 0 ? TESTS_SKIPPED - 1 : 0))

    test_glyph_snapshots "$glyph" "$example_file" "$test_name"

    return $failed
}

# Test multiple glyphs
test_glyphs() {
    local mode="$1"
    shift
    local glyphs=("$@")

    if [ ${#glyphs[@]} -eq 0 ] || [ "${glyphs[0]}" = "all" ]; then
        log_info "Auto-discovering glyphs..."
        glyphs=($(discover_tested_glyphs))

        local all_glyphs=($(discover_glyphs))
        local untested=($(discover_untested_glyphs))

        log_info "Found ${#all_glyphs[@]} glyphs total"
        log_info "Testing ${#glyphs[@]} glyphs with examples"

        if [ ${#untested[@]} -gt 0 ]; then
            log_warning "${#untested[@]} glyphs without examples: ${untested[*]}"
        fi
    fi

    if [ ${#glyphs[@]} -eq 0 ]; then
        log_error "No glyphs found to test"
        return 1
    fi

    log_header "Testing Glyphs (mode: $mode)"

    local failed_glyphs=()

    for glyph in "${glyphs[@]}"; do
        if ! test_glyph "$glyph" "$mode"; then
            failed_glyphs+=("$glyph")
        fi
    done

    print_summary

    if [ ${#failed_glyphs[@]} -gt 0 ]; then
        log_error "Failed glyphs: ${failed_glyphs[*]}"
        return 1
    fi

    return 0
}

# Main entry point
main() {
    local mode="${1:-comprehensive}"
    shift || true

    check_required_commands helm yq || exit 1

    test_glyphs "$mode" "$@"
}

# Only run main if executed directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
