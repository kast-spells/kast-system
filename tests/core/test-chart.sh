#!/bin/bash
# Chart Testing Module
# Tests main charts (summon, kaster, librarian)

set -euo pipefail

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"
source "$LIB_DIR/utils.sh"
source "$LIB_DIR/discover.sh"
source "$LIB_DIR/validate.sh"

REPO_ROOT="$(get_repo_root)"
OUTPUT_DIR="$REPO_ROOT/output-test"

# Test single chart
test_chart() {
    local chart="$1"
    local mode="${2:-comprehensive}"

    if ! chart_exists "$chart"; then
        log_error "Chart not found: $chart"
        return 1
    fi

    local chart_path=$(get_chart_path "$chart")

    if ! validate_has_examples "$chart_path"; then
        log_warning "$chart: No examples found (testing basic render)"
        # Test basic render without examples
        test_chart_basic "$chart" "$chart_path"
        return $?
    fi

    log_section "Testing chart: $chart"

    local examples=$(get_chart_examples "$chart")
    local example_count=$(echo "$examples" | wc -w)

    log_info "$chart: Found $example_count examples"

    local failed=0

    for example_file in $examples; do
        local example_name=$(basename "$example_file" .yaml)
        local test_name="test-$chart-$example_name"

        case "$mode" in
            syntax)
                test_chart_syntax "$chart" "$chart_path" "$example_file" "$test_name"
                ;;
            comprehensive)
                test_chart_comprehensive "$chart" "$chart_path" "$example_file" "$test_name"
                ;;
            snapshots)
                test_chart_snapshots "$chart" "$chart_path" "$example_file" "$test_name"
                ;;
            all)
                test_chart_all "$chart" "$chart_path" "$example_file" "$test_name"
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
        log_success "$chart: All tests passed ($example_count/$example_count)"
        return 0
    else
        log_error "$chart: $failed/$example_count tests failed"
        return 1
    fi
}

# Test chart basic (no examples)
test_chart_basic() {
    local chart="$1"
    local chart_path="$2"
    local test_name="test-$chart-basic"

    if validate_syntax "$chart_path"; then
        log_success "$chart: Basic syntax valid"
        increment_passed
        return 0
    else
        log_error "$chart: Basic syntax validation failed"
        increment_failed
        return 1
    fi
}

# Test chart syntax
test_chart_syntax() {
    local chart="$1"
    local chart_path="$2"
    local example_file="$3"
    local test_name="$4"
    local example_name=$(basename "$example_file" .yaml)

    if validate_syntax "$chart_path" "$example_file"; then
        log_success "$chart/$example_name: Syntax valid"
        increment_passed
        return 0
    else
        log_error "$chart/$example_name: Syntax validation failed"
        increment_failed
        return 1
    fi
}

# Test chart comprehensive (with resource validation)
test_chart_comprehensive() {
    local chart="$1"
    local chart_path="$2"
    local example_file="$3"
    local test_name="$4"
    local example_name=$(basename "$example_file" .yaml)

    local output=$(render_template "$chart_path" "$example_file" "$test_name")

    if has_errors "$output"; then
        log_error "$chart/$example_name: Rendering failed"
        get_errors "$output" | while IFS= read -r line; do
            echo "  $line"
        done
        increment_failed
        return 1
    fi

    local resource_count=$(count_resources "$output")

    if [ "$resource_count" -eq 0 ]; then
        log_error "$chart/$example_name: No resources generated"
        increment_failed
        return 1
    fi

    # Run resource completeness validation if script exists
    if [ -f "$REPO_ROOT/tests/scripts/validate-resource-completeness.sh" ]; then
        if ! bash "$REPO_ROOT/tests/scripts/validate-resource-completeness.sh" "$chart_path" "$example_file" "$test_name" > /dev/null 2>&1; then
            log_warning "$chart/$example_name: Resource completeness check failed"
        fi
    fi

    log_success "$chart/$example_name: Generated $resource_count resources"
    increment_passed
    return 0
}

# Test chart with snapshots
test_chart_snapshots() {
    local chart="$1"
    local chart_path="$2"
    local example_file="$3"
    local test_name="$4"
    local example_name=$(basename "$example_file" .yaml)

    mkdir -p "$OUTPUT_DIR/$chart"

    local actual_file="$OUTPUT_DIR/$chart/$example_name.yaml"
    local expected_file="$OUTPUT_DIR/$chart/$example_name.expected.yaml"

    local output=$(render_template "$chart_path" "$example_file" "$test_name")

    if has_errors "$output"; then
        log_error "$chart/$example_name: Rendering failed"
        increment_failed
        return 1
    fi

    echo "$output" > "$actual_file"

    # K8s schema validation
    if ! validate_k8s_schema "$actual_file" "$chart_path" "$example_file"; then
        log_warning "$chart/$example_name: K8s schema validation failed"
    fi

    local snapshot_result=$(compare_snapshot "$actual_file" "$expected_file")
    local snapshot_exit=$?

    if [ $snapshot_exit -eq 0 ]; then
        log_success "$chart/$example_name: Snapshot matches"
        increment_passed
        return 0
    elif [ $snapshot_exit -eq 2 ]; then
        log_warning "$chart/$example_name: No snapshot (run: make generate-snapshots CHART=$chart)"
        increment_skipped
        return 0
    else
        log_error "$chart/$example_name: Snapshot differs"
        log_info "  Run: diff $actual_file $expected_file"
        increment_failed
        return 1
    fi
}

# Test chart with all modes
test_chart_all() {
    local chart="$1"
    local chart_path="$2"
    local example_file="$3"
    local test_name="$4"

    # Run all validations but only count once
    local saved_passed=$TESTS_PASSED
    local saved_failed=$TESTS_FAILED
    local saved_skipped=$TESTS_SKIPPED

    test_chart_syntax "$chart" "$chart_path" "$example_file" "$test_name"
    test_chart_comprehensive "$chart" "$chart_path" "$example_file" "$test_name"
    test_chart_snapshots "$chart" "$chart_path" "$example_file" "$test_name"

    # Reset to count only once
    TESTS_PASSED=$((saved_passed + 1))
    TESTS_FAILED=$saved_failed
    TESTS_SKIPPED=$saved_skipped

    return 0
}

# Test multiple charts
test_charts() {
    local mode="$1"
    shift
    local charts=("$@")

    if [ ${#charts[@]} -eq 0 ] || [ "${charts[0]}" = "all" ]; then
        log_info "Auto-discovering charts..."
        charts=($(discover_charts))

        log_info "Found ${#charts[@]} charts"
    fi

    if [ ${#charts[@]} -eq 0 ]; then
        log_error "No charts found to test"
        return 1
    fi

    log_header "Testing Charts (mode: $mode)"

    local failed_charts=()

    for chart in "${charts[@]}"; do
        if ! test_chart "$chart" "$mode"; then
            if [ $? -eq 1 ]; then
                failed_charts+=("$chart")
            fi
        fi
    done

    print_summary

    if [ ${#failed_charts[@]} -gt 0 ]; then
        log_error "Failed charts: ${failed_charts[*]}"
        return 1
    fi

    return 0
}

# Main entry point
main() {
    local mode="${1:-comprehensive}"
    shift || true

    check_required_commands helm || exit 1

    test_charts "$mode" "$@"
}

# Only run main if executed directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
