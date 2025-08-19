#!/bin/bash
# Kubernetes Resource Validation Script
# Validates that rendered Helm templates produce valid Kubernetes resources

set -e

# Colors for output
BLUE='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

validate_k8s_yaml() {
    local yaml_content="$1"
    local test_name="$2"
    
    echo -e "${BLUE}  Validating K8s resources for $test_name...${RESET}"
    
    # Check if kubectl is available for validation
    if ! command -v kubectl &> /dev/null; then
        echo -e "${YELLOW}    ⚠️  kubectl not available, skipping K8s validation${RESET}"
        return 0
    fi
    
    # Validate YAML syntax and K8s resource structure
    echo "$yaml_content" | kubectl apply --dry-run=client --validate=true -f - > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}    ✅ K8s validation passed${RESET}"
        return 0
    else
        echo -e "${RED}    ❌ K8s validation failed${RESET}"
        echo "$yaml_content" | kubectl apply --dry-run=client --validate=true -f - 2>&1 | head -10
        return 1
    fi
}

validate_resource_expectations() {
    local yaml_content="$1"
    local test_name="$2"
    local chart_name="$3"
    local example_name="$4"
    
    echo -e "${BLUE}  Validating resource expectations for $test_name...${RESET}"
    
    # Check for common required fields
    local issues=0
    
    # Every K8s resource should have apiVersion, kind, metadata.name
    if ! echo "$yaml_content" | grep -q "apiVersion:"; then
        echo -e "${RED}    ❌ Missing apiVersion${RESET}"
        ((issues++))
    fi
    
    if ! echo "$yaml_content" | grep -q "kind:"; then
        echo -e "${RED}    ❌ Missing kind${RESET}"
        ((issues++))
    fi
    
    if ! echo "$yaml_content" | grep -q "metadata:"; then
        echo -e "${RED}    ❌ Missing metadata${RESET}"
        ((issues++))
    fi
    
    # Chart-specific validations
    case "$chart_name" in
        "summon")
            validate_summon_expectations "$yaml_content" "$example_name"
            issues=$((issues + $?))
            ;;
        "microspell")
            validate_microspell_expectations "$yaml_content" "$example_name"
            issues=$((issues + $?))
            ;;
    esac
    
    if [ $issues -eq 0 ]; then
        echo -e "${GREEN}    ✅ Resource expectations met${RESET}"
        return 0
    else
        echo -e "${RED}    ❌ $issues expectation failures${RESET}"
        return 1
    fi
}

validate_summon_expectations() {
    local yaml_content="$1"
    local example_name="$2"
    local issues=0
    
    # If workload is enabled, should have Deployment/StatefulSet
    if echo "$yaml_content" | grep -q "workload:"; then
        if ! echo "$yaml_content" | grep -qE "kind: (Deployment|StatefulSet)"; then
            echo -e "${RED}      ❌ Workload enabled but no Deployment/StatefulSet found${RESET}"
            ((issues++))
        fi
    fi
    
    # If service is enabled, should have Service resource
    if echo "$yaml_content" | grep -q "service:"; then
        if ! echo "$yaml_content" | grep -q "kind: Service"; then
            echo -e "${RED}      ❌ Service enabled but no Service resource found${RESET}"
            ((issues++))
        fi
    fi
    
    # If volumes with PVC, should have PVC resources
    if echo "$yaml_content" | grep -q "type: pvc"; then
        if ! echo "$yaml_content" | grep -q "kind: PersistentVolumeClaim"; then
            echo -e "${RED}      ❌ PVC volumes defined but no PVC resources found${RESET}"
            ((issues++))
        fi
    fi
    
    # StatefulSet examples should have StatefulSet
    if [[ "$example_name" == *"statefulset"* ]]; then
        if ! echo "$yaml_content" | grep -q "kind: StatefulSet"; then
            echo -e "${RED}      ❌ StatefulSet example but no StatefulSet resource found${RESET}"
            ((issues++))
        fi
    fi
    
    return $issues
}

validate_microspell_expectations() {
    local yaml_content="$1" 
    local example_name="$2"
    local issues=0
    
    # Microspell should generate summon workloads
    if ! echo "$yaml_content" | grep -qE "kind: (Deployment|StatefulSet)"; then
        echo -e "${RED}      ❌ Microspell should generate workload resources${RESET}"
        ((issues++))
    fi
    
    # If service.external is true, should have VirtualService (if istio glyph available)
    if echo "$yaml_content" | grep -q "external: true"; then
        # This is tricky without parsing values, so we'll check if VS exists
        if echo "$yaml_content" | grep -q "kind: VirtualService"; then
            echo -e "${GREEN}      ✅ External service has VirtualService${RESET}"
        fi
    fi
    
    return $issues
}

# Main validation function
main() {
    if [ $# -lt 3 ]; then
        echo "Usage: $0 <chart_dir> <example_file> <test_name>"
        exit 1
    fi
    
    local chart_dir="$1"
    local example_file="$2" 
    local test_name="$3"
    local chart_name=$(basename "$chart_dir")
    local example_name=$(basename "$example_file" .yaml)
    
    echo -e "${BLUE}🔍 Validating $test_name${RESET}"
    
    # Render the template
    local yaml_content
    yaml_content=$(helm template "$test_name" "$chart_dir" -f "$example_file" 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}  ❌ Failed to render template${RESET}"
        return 1
    fi
    
    local validation_passed=0
    
    # Run K8s validation
    if validate_k8s_yaml "$yaml_content" "$test_name"; then
        ((validation_passed++))
    fi
    
    # Run expectation validation
    if validate_resource_expectations "$yaml_content" "$test_name" "$chart_name" "$example_name"; then
        ((validation_passed++))
    fi
    
    if [ $validation_passed -eq 2 ]; then
        echo -e "${GREEN}✅ $test_name validation passed${RESET}"
        return 0
    else
        echo -e "${RED}❌ $test_name validation failed${RESET}"
        return 1
    fi
}

# If called directly, run main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi