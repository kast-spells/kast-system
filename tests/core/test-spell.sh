#!/bin/bash
# Spell Testing Module
# Tests individual spells by rendering actual K8s resources

set -euo pipefail

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"
source "$LIB_DIR/utils.sh"
source "$LIB_DIR/discover.sh"
source "$LIB_DIR/validate.sh"

REPO_ROOT="$(get_repo_root)"
OUTPUT_DIR="$REPO_ROOT/output-test"
LIBRARIAN_DIR="$REPO_ROOT/librarian"

# Test spell
test_spell() {
    local spell="$1"
    local book="${2:-}"
    local mode="${3:-comprehensive}"
    local debug="${4:-}"

    # Get book from flags or use default
    if [ -z "$book" ]; then
        book=$(get_flag_value "book" "$@") || book="example-tdd-book"
    fi

    if [ -z "$debug" ]; then
        if parse_flag "debug" "$@"; then
            debug="--debug"
        fi
    fi

    log_header "Testing Spell: $spell"
    log_info "Book: $book"
    log_info "Mode: $mode"
    echo ""

    # Check dependencies
    if ! check_command yq; then
        log_error "yq is required but not installed"
        log_info "Install: brew install yq (or equivalent)"
        return 1
    fi

    # Step 1: Render librarian to get Application
    log_section "Step 1: Generating ArgoCD Application via librarian"

    if [ ! -f "$LIBRARIAN_DIR/Chart.yaml" ]; then
        log_error "Librarian not found at: $LIBRARIAN_DIR"
        return 1
    fi

    local librarian_output
    librarian_output=$(helm template test-librarian "$LIBRARIAN_DIR" \
        --set name="$book" \
        --namespace argocd \
        2>&1)

    if [ $? -ne 0 ]; then
        log_error "Librarian rendering failed"
        echo "$librarian_output"
        return 1
    fi

    log_success "Librarian rendered successfully"
    echo ""

    # Step 2: Extract spell's Application
    log_section "Step 2: Extracting Application for spell: $spell"

    local application
    application=$(echo "$librarian_output" | yq eval "select(.kind == \"Application\" and .metadata.name == \"$spell\")" - 2>/dev/null)

    if [ -z "$application" ] || [ "$application" = "null" ]; then
        log_error "No Application found for spell: $spell"
        echo ""
        log_info "Available spells in book '$book':"
        echo "$librarian_output" | yq eval 'select(.kind == "Application") | .metadata.name' - | sed 's/^/  - /'
        return 1
    fi

    log_success "Application extracted"
    echo ""

    # Step 3: Parse sources
    log_section "Step 3: Parsing Application sources"

    local sources_count
    sources_count=$(echo "$application" | yq eval '.spec.sources | length' - 2>/dev/null)

    if [ "$sources_count" = "null" ] || [ "$sources_count" -eq 0 ]; then
        log_error "No sources found in Application"
        return 1
    fi

    log_success "Found $sources_count source(s)"
    echo ""

    # Step 4: Render each source
    log_section "Step 4: Rendering Kubernetes resources from sources"
    echo ""

    local temp_dir
    temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT

    local total_resources=0
    local failed_sources=0

    for i in $(seq 0 $((sources_count - 1))); do
        if ! render_source "$spell" "$application" "$i" "$temp_dir" "$debug"; then
            failed_sources=$((failed_sources + 1))
        else
            # Count resources rendered
            local source_output="$OUTPUT_DIR/spell-${spell}-source-$((i+1))-*.yaml"
            if ls $source_output 1> /dev/null 2>&1; then
                local resources=$(cat $source_output 2>/dev/null | grep -c "^kind:" || echo "0")
                total_resources=$((total_resources + resources))
            fi
        fi
    done

    echo ""
    log_header "Test Summary"

    if [ $failed_sources -eq 0 ]; then
        log_success "Spell test completed: $total_resources K8s resources generated"
        log_info "Outputs saved to: $OUTPUT_DIR/spell-$spell-*"
        increment_passed
        return 0
    else
        log_error "Spell test failed: $failed_sources/$sources_count sources failed"
        increment_failed
        return 1
    fi
}

# Render single source
render_source() {
    local spell="$1"
    local application="$2"
    local source_index="$3"
    local temp_dir="$4"
    local debug="${5:-}"

    # Extract source details
    local chart_path
    chart_path=$(echo "$application" | yq eval ".spec.sources[$source_index].path" - 2>/dev/null)

    local repo_url
    repo_url=$(echo "$application" | yq eval ".spec.sources[$source_index].repoURL" - 2>/dev/null)

    # Skip if not a local chart
    if [[ "$chart_path" != ./* ]]; then
        log_warning "Source $((source_index+1)): Skipping non-local chart ($repo_url)"
        return 0
    fi

    # Clean chart path (remove leading ./)
    chart_path="${chart_path#./}"
    local chart_name=$(basename "$chart_path")

    log_info "Source $((source_index+1))/$sources_count: $chart_name"
    log_info "  Path: $chart_path"

    # Check if chart exists
    if [ ! -f "$REPO_ROOT/$chart_path/Chart.yaml" ]; then
        log_error "  Chart not found: $REPO_ROOT/$chart_path"
        return 1
    fi

    # Extract helm values
    local values_file="$temp_dir/values-source-$source_index.yaml"

    # Try valuesObject first (YAML object)
    local values_object
    values_object=$(echo "$application" | yq eval ".spec.sources[$source_index].helm.valuesObject" - 2>/dev/null)

    if [ "$values_object" != "null" ] && [ -n "$values_object" ]; then
        echo "$values_object" > "$values_file"
    else
        # Try values (string)
        local values_string
        values_string=$(echo "$application" | yq eval ".spec.sources[$source_index].helm.values" - 2>/dev/null)

        if [ "$values_string" != "null" ] && [ -n "$values_string" ]; then
            echo "$values_string" > "$values_file"
        else
            # No values, create empty file
            echo "{}" > "$values_file"
        fi
    fi

    # Render the chart
    local release_name="test-$spell-$chart_name"
    local namespace
    namespace=$(echo "$application" | yq eval '.spec.destination.namespace' - 2>/dev/null)
    namespace="${namespace:-default}"

    log_info "  Rendering chart..."

    local output
    if [ "$debug" = "--debug" ]; then
        output=$(helm template "$release_name" "$REPO_ROOT/$chart_path" \
            -f "$values_file" \
            --namespace "$namespace" \
            --debug \
            2>&1)
    else
        output=$(helm template "$release_name" "$REPO_ROOT/$chart_path" \
            -f "$values_file" \
            --namespace "$namespace" \
            2>&1)
    fi

    if [ $? -ne 0 ]; then
        log_error "  Rendering failed"
        echo "$output" | head -20
        return 1
    fi

    # Count resources
    local resource_count=$(echo "$output" | grep -c "^kind:" || echo "0")

    log_success "  Generated $resource_count resource(s)"

    # Show resource summary
    if [ "$resource_count" -gt 0 ]; then
        echo ""
        log_info "  Resource Summary:"
        echo "$output" | grep "^kind:" | sort | uniq -c | while read count kind; do
            log_info "    ${count}x ${kind}"
        done
        echo ""
    fi

    # Show full output if debug
    if [ "$debug" = "--debug" ]; then
        log_info "  Full Output:"
        echo "  ---"
        echo "$output"
        echo "  ---"
        echo ""
    fi

    # Save output to file
    mkdir -p "$OUTPUT_DIR"
    local output_file="$OUTPUT_DIR/spell-${spell}-source-$((source_index+1))-${chart_name}.yaml"
    echo "$output" > "$output_file"
    log_success "  Saved to: $output_file"
    echo ""

    return 0
}

# Main entry point
main() {
    local spell="${1:-}"
    shift || true

    if [ -z "$spell" ]; then
        log_error "Spell name required"
        echo "Usage: $0 <spell> [--book <book>] [--debug]"
        echo ""
        echo "Examples:"
        echo "  $0 example-api"
        echo "  $0 example-api --book example-tdd-book"
        echo "  $0 example-api --book example-tdd-book --debug"
        exit 1
    fi

    check_required_commands helm yq || exit 1

    test_spell "$spell" "" "comprehensive" "" "$@"
}

# Only run main if executed directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
