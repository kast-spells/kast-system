#!/bin/bash
# Validation script for Kast Helm chart outputs

set -e

CHARTS_DIR="charts"
SUMMON_DIR="$CHARTS_DIR/summon"
TRINKETS_DIR="$CHARTS_DIR/trinkets"
CONFIG_DIR="tests/configs"

echo "🔍 Running validation checks..."

# Colors
BLUE='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

# Validation functions
validate_yaml() {
    local chart_path="$1"
    local values_file="$2"
    local test_name="$3"
    
    echo -e "${BLUE}  Validating YAML syntax: $test_name${RESET}"
    
    if [ -n "$values_file" ]; then
        helm template validate-test "$chart_path" -f "$values_file" > /tmp/kast-validation.yaml 2>/dev/null
    else
        helm template validate-test "$chart_path" > /tmp/kast-validation.yaml 2>/dev/null
    fi
    
    # Check if YAML is valid
    if yq eval '.' /tmp/kast-validation.yaml > /dev/null 2>&1; then
        echo -e "${GREEN}✅ $test_name YAML valid${RESET}"
    else
        echo -e "${RED}❌ $test_name YAML invalid${RESET}"
        return 1
    fi
}

check_required_fields() {
    local chart_path="$1"
    local values_file="$2"
    local test_name="$3"
    
    echo -e "${BLUE}  Checking required Kubernetes fields: $test_name${RESET}"
    
    if [ -n "$values_file" ]; then
        output=$(helm template validate-test "$chart_path" -f "$values_file" 2>/dev/null)
    else
        output=$(helm template validate-test "$chart_path" 2>/dev/null)
    fi
    
    # Check for required fields in resources
    missing_fields=""
    
    # Check Deployment has required fields
    if echo "$output" | grep -q "kind: Deployment"; then
        if ! echo "$output" | yq eval 'select(.kind == "Deployment") | .metadata.name' - | grep -q "."; then
            missing_fields="$missing_fields Deployment.metadata.name"
        fi
        if ! echo "$output" | yq eval 'select(.kind == "Deployment") | .spec.selector.matchLabels' - | grep -q "."; then
            missing_fields="$missing_fields Deployment.spec.selector.matchLabels"
        fi
    fi
    
    # Check Service has required fields  
    if echo "$output" | grep -q "kind: Service"; then
        if ! echo "$output" | yq eval 'select(.kind == "Service") | .spec.selector' - | grep -q "."; then
            missing_fields="$missing_fields Service.spec.selector"
        fi
    fi
    
    # Check PVC has required fields
    if echo "$output" | grep -q "kind: PersistentVolumeClaim"; then
        if ! echo "$output" | yq eval 'select(.kind == "PersistentVolumeClaim") | .spec.resources.requests.storage' - | grep -q "."; then
            missing_fields="$missing_fields PVC.spec.resources.requests.storage"
        fi
    fi
    
    if [ -z "$missing_fields" ]; then
        echo -e "${GREEN}✅ $test_name required fields present${RESET}"
    else
        echo -e "${RED}❌ $test_name missing fields:$missing_fields${RESET}"
        return 1
    fi
}

check_naming_consistency() {
    local chart_path="$1"
    local values_file="$2"
    local test_name="$3"
    
    echo -e "${BLUE}  Checking naming consistency: $test_name${RESET}"
    
    if [ -n "$values_file" ]; then
        output=$(helm template naming-test "$chart_path" -f "$values_file" 2>/dev/null)
    else
        output=$(helm template naming-test "$chart_path" 2>/dev/null)
    fi
    
    # Check for consistent naming patterns
    names=$(echo "$output" | yq eval '.metadata.name' - | sort | uniq | grep -v "null" | grep -v "^$")
    inconsistent_names=""
    
    # All names should start with the same base (release name)
    base_name=$(echo "$names" | head -1 | cut -d'-' -f1)
    
    while IFS= read -r name; do
        if [ -n "$name" ] && ! echo "$name" | grep -q "^$base_name"; then
            inconsistent_names="$inconsistent_names $name"
        fi
    done <<< "$names"
    
    if [ -z "$inconsistent_names" ]; then
        echo -e "${GREEN}✅ $test_name naming consistent${RESET}"
    else
        echo -e "${YELLOW}⚠️  $test_name inconsistent names:$inconsistent_names${RESET}"
    fi
}

check_pvc_functionality() {
    echo -e "${BLUE}  Testing PVC generation functionality${RESET}"
    
    # Test PVC generation
    output=$(helm template pvc-test "$SUMMON_DIR" -f "$CONFIG_DIR/pvc-values.yaml" 2>/dev/null)
    
    # Check if PVCs are generated
    pvc_count=$(echo "$output" | grep -c "kind: PersistentVolumeClaim" || true)
    
    if [ "$pvc_count" -gt 0 ]; then
        echo -e "${GREEN}✅ PVC generation working ($pvc_count PVCs)${RESET}"
        
        # Check for correct PVC naming (should include volume key)
        pvc_names=$(echo "$output" | yq eval 'select(.kind == "PersistentVolumeClaim") | .metadata.name' -)
        echo -e "${BLUE}    Generated PVC names: $(echo $pvc_names | tr '\n' ' ')${RESET}"
        
        # Check if volume mounts are present in deployment
        volume_mounts=$(echo "$output" | yq eval 'select(.kind == "Deployment") | .spec.template.spec.containers[0].volumeMounts | length' -)
        if [ "$volume_mounts" -gt 0 ]; then
            echo -e "${GREEN}✅ Volume mounts present in deployment${RESET}"
        else
            echo -e "${RED}❌ Volume mounts missing in deployment${RESET}"
        fi
        
    else
        echo -e "${RED}❌ PVC generation not working${RESET}"
        return 1
    fi
}

check_template_comments() {
    echo -e "${BLUE}  Checking for template artifacts in output${RESET}"
    
    output=$(helm template artifact-test "$SUMMON_DIR" 2>/dev/null)
    
    # Check for leftover template comments or debugging
    if echo "$output" | grep -q "{{.*}}"; then
        echo -e "${RED}❌ Template artifacts found in output${RESET}"
        echo "$output" | grep "{{.*}}" | head -3
        return 1
    fi
    
    # Check for TODO comments in output (shouldn't be there)
    if echo "$output" | grep -qi "TODO"; then
        echo -e "${YELLOW}⚠️  TODO comments found in output${RESET}"
        echo "$output" | grep -i "TODO" | head -3
    fi
    
    echo -e "${GREEN}✅ No template artifacts in output${RESET}"
}

# Main validation execution
main() {
    echo "🧪 Starting Kast validation tests..."
    
    # Ensure test configs exist
    if [ ! -f "$CONFIG_DIR/basic-values.yaml" ]; then
        echo "Creating test configurations..."
        ./tests/scripts/setup-test-configs.sh
    fi
    
    # Test summon chart
    echo -e "\n${BLUE}Testing Summon Chart:${RESET}"
    validate_yaml "$SUMMON_DIR" "" "summon-basic"
    validate_yaml "$SUMMON_DIR" "$CONFIG_DIR/pvc-values.yaml" "summon-pvc"
    check_required_fields "$SUMMON_DIR" "$CONFIG_DIR/basic-values.yaml" "summon-basic"
    check_naming_consistency "$SUMMON_DIR" "$CONFIG_DIR/basic-values.yaml" "summon-basic"
    
    # Test microspell trinket
    echo -e "\n${BLUE}Testing Microspell Trinket:${RESET}"
    if [ -d "$TRINKETS_DIR/microspell" ]; then
        validate_yaml "$TRINKETS_DIR/microspell" "" "microspell-basic"
        validate_yaml "$TRINKETS_DIR/microspell" "$CONFIG_DIR/microspell-values.yaml" "microspell-complex"
        check_required_fields "$TRINKETS_DIR/microspell" "" "microspell-basic"
        check_naming_consistency "$TRINKETS_DIR/microspell" "" "microspell-basic"
    fi
    
    # Test PVC functionality specifically
    echo -e "\n${BLUE}Testing PVC Functionality:${RESET}"
    check_pvc_functionality
    
    # Test template cleanliness
    echo -e "\n${BLUE}Testing Template Cleanliness:${RESET}"
    check_template_comments
    
    echo -e "\n${GREEN}🎉 Validation completed!${RESET}"
}

# Cleanup function
cleanup() {
    rm -f /tmp/kast-validation.yaml
}

trap cleanup EXIT

main "$@"