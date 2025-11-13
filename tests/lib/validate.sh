#!/bin/bash
# Validation Library
# Common validation functions for testing

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

REPO_ROOT="$(get_repo_root)"

# Validate helm template syntax
validate_syntax() {
    local chart_path="$1"
    local values_file="${2:-}"
    local release_name="test-syntax-$(basename "$chart_path")"

    if [ -n "$values_file" ] && [ -f "$values_file" ]; then
        helm template "$release_name" "$chart_path" -f "$values_file" > /dev/null 2>&1
    else
        helm template "$release_name" "$chart_path" > /dev/null 2>&1
    fi
}

# Render helm template
render_template() {
    local chart_path="$1"
    local values_file="${2:-}"
    local release_name="${3:-test-render}"
    local namespace="${4:-default}"

    if [ -n "$values_file" ] && [ -f "$values_file" ]; then
        helm template "$release_name" "$chart_path" \
            -f "$values_file" \
            --namespace "$namespace" \
            2>&1
    else
        helm template "$release_name" "$chart_path" \
            --namespace "$namespace" \
            2>&1
    fi
}

# Count resources in rendered output
count_resources() {
    local output="$1"
    echo "$output" | grep -c "^kind:" || echo "0"
}

# Get resource types from rendered output
get_resource_types() {
    local output="$1"
    echo "$output" | grep "^kind:" | awk '{print $2}' | sort | uniq
}

# Get resource summary (count per type)
get_resource_summary() {
    local output="$1"
    echo "$output" | grep "^kind:" | sort | uniq -c | while read count kind; do
        echo "${count}x ${kind}"
    done
}

# Validate resource completeness
# Checks if expected resources are present based on values
validate_resource_completeness() {
    local chart_path="$1"
    local values_file="$2"
    local output="$3"

    # This is a simplified version
    # Full implementation would read values and check for expected resources
    # For now, just check that some resources were generated

    local resource_count=$(count_resources "$output")
    if [ "$resource_count" -eq 0 ]; then
        return 1
    fi
    return 0
}

# Compare with snapshot
compare_snapshot() {
    local actual_file="$1"
    local expected_file="$2"

    if [ ! -f "$expected_file" ]; then
        log_warning "No snapshot found: $expected_file"
        return 2
    fi

    if diff -q "$actual_file" "$expected_file" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Validate with kubectl dry-run (K8s schema validation)
validate_k8s_schema() {
    local output_file="$1"

    # This requires kubectl to be configured
    # For now, we'll use helm install --dry-run which also validates schema

    local chart_path="$2"
    local values_file="${3:-}"
    local release_name="test-schema"
    local namespace="validate-ns"

    if [ -n "$values_file" ] && [ -f "$values_file" ]; then
        helm install "$release_name" "$chart_path" \
            -f "$values_file" \
            --dry-run \
            --namespace "$namespace" \
            --create-namespace \
            > /dev/null 2>&1
    else
        helm install "$release_name" "$chart_path" \
            --dry-run \
            --namespace "$namespace" \
            --create-namespace \
            > /dev/null 2>&1
    fi
}

# Check if output has errors
has_errors() {
    local output="$1"
    echo "$output" | grep -qi "error:"
}

# Extract errors from output
get_errors() {
    local output="$1"
    echo "$output" | grep -i "error:" | head -10
}

# Validate that examples directory exists and has files
validate_has_examples() {
    local component_path="$1"

    if [ ! -d "$component_path/examples" ]; then
        return 1
    fi

    local example_count=$(find "$component_path/examples" -name "*.yaml" -type f 2>/dev/null | wc -l)
    if [ "$example_count" -eq 0 ]; then
        return 1
    fi

    return 0
}

# Get example count
get_example_count() {
    local component_path="$1"

    if [ -d "$component_path/examples" ]; then
        find "$component_path/examples" -name "*.yaml" -type f 2>/dev/null | wc -l
    else
        echo "0"
    fi
}

# Export functions
export -f validate_syntax render_template
export -f count_resources get_resource_types get_resource_summary
export -f validate_resource_completeness compare_snapshot validate_k8s_schema
export -f has_errors get_errors
export -f validate_has_examples get_example_count
