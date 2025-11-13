#!/bin/bash
# Resource Completeness Validation Script
# Validates that rendered templates contain ALL expected resources based on configuration

set -e

# Colors
BLUE='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

# Parse YAML values to understand what should be generated
parse_values() {
    local values_file="$1"
    
    # Use yq if available, fallback to grep-based parsing
    if command -v yq &> /dev/null; then
        parse_values_with_yq "$values_file"
    else
        parse_values_with_grep "$values_file"
    fi
}

parse_values_with_yq() {
    local values_file="$1"
    
    # Extract key configuration flags
    WORKLOAD_ENABLED=$(yq eval '.workload.enabled // false' "$values_file")
    WORKLOAD_TYPE=$(yq eval '.workload.type // "deployment"' "$values_file")
    SERVICE_ENABLED=$(yq eval '.service.enabled // false' "$values_file")
    SERVICE_EXTERNAL=$(yq eval '.service.external // false' "$values_file")
    SERVICEACCOUNT_ENABLED=$(yq eval '.serviceAccount.enabled // false' "$values_file")
    AUTOSCALING_ENABLED=$(yq eval '.autoscaling.enabled // false' "$values_file")
    
    # Count volumes that need PVCs (but not StatefulSet volumeClaimTemplates)
    PVC_COUNT=$(yq eval '[.volumes // {} | to_entries[] | select(.value.type == "pvc")] | length' "$values_file")
    
    # Count StatefulSet volumeClaimTemplates (these don't generate separate PVCs)
    VOLUMECLAIMTEMPLATE_COUNT=$(yq eval '[.workload.volumeClaimTemplates // {} | to_entries[]] | length' "$values_file")
    
    # Count secrets to be created
    SECRET_COUNT=$(yq eval '[.secrets // {} | to_entries[] | select(.value.location == "create")] | length' "$values_file")
    
    # Ingress/VirtualService expectations
    NEEDS_VIRTUALSERVICE=$(yq eval '.infrastructure.istio.virtualService.enabled // false' "$values_file")
}

parse_values_with_grep() {
    local values_file="$1"
    
    # Fallback parsing with grep (less accurate but works without yq)
    WORKLOAD_ENABLED=$(grep -E "^\s*enabled:\s*true" "$values_file" | head -1 | grep -q "true" && echo "true" || echo "false")
    WORKLOAD_TYPE=$(grep -E "^\s*type:\s*(deployment|statefulset|job|cronjob)" "$values_file" | head -1 | sed -E 's/.*type:\s*([a-z]+).*/\1/' || echo "deployment")
    SERVICE_ENABLED=$(grep -A5 "^service:" "$values_file" | grep -q "enabled: true" && echo "true" || echo "false")
    SERVICE_EXTERNAL=$(grep -A10 "^service:" "$values_file" | grep -q "external: true" && echo "true" || echo "false")
    SERVICEACCOUNT_ENABLED=$(grep -A5 "^serviceAccount:" "$values_file" | grep -q "enabled: true" && echo "true" || echo "false")
    AUTOSCALING_ENABLED=$(grep -A5 "^autoscaling:" "$values_file" | grep -q "enabled: true" && echo "true" || echo "false")
    
    # Count PVC volumes (but not StatefulSet volumeClaimTemplates)
    PVC_COUNT=$(grep -c "type: pvc" "$values_file" 2>/dev/null || echo "0")
    
    # Count StatefulSet volumeClaimTemplates (these don't generate separate PVCs)
    VOLUMECLAIMTEMPLATE_COUNT=$(grep -A10 "volumeClaimTemplates:" "$values_file" | grep -c "destinationPath:" 2>/dev/null || echo "0")
    
    # Count create secrets  
    SECRET_COUNT=$(grep -c "location: create" "$values_file" 2>/dev/null || echo "0")
    
    NEEDS_VIRTUALSERVICE="false"
}

# Extract actual resources from rendered YAML
extract_resources() {
    local yaml_content="$1"
    
    # Count each resource type
    ACTUAL_DEPLOYMENTS=$(echo "$yaml_content" | grep -c "kind: Deployment" 2>/dev/null || echo "0")
    ACTUAL_STATEFULSETS=$(echo "$yaml_content" | grep -c "kind: StatefulSet" 2>/dev/null || echo "0")
    ACTUAL_JOBS=$(echo "$yaml_content" | grep -c "^kind: Job" 2>/dev/null || echo "0")
    ACTUAL_CRONJOBS=$(echo "$yaml_content" | grep -c "kind: CronJob" 2>/dev/null || echo "0")
    ACTUAL_SERVICES=$(echo "$yaml_content" | grep -c "kind: Service" 2>/dev/null || echo "0")
    ACTUAL_SERVICEACCOUNTS=$(echo "$yaml_content" | grep -c "kind: ServiceAccount" 2>/dev/null || echo "0")
    ACTUAL_PVCS=$(echo "$yaml_content" | grep -c "kind: PersistentVolumeClaim" 2>/dev/null || echo "0")
    ACTUAL_SECRETS=$(echo "$yaml_content" | grep -c "kind: Secret" 2>/dev/null || echo "0")
    ACTUAL_HPAS=$(echo "$yaml_content" | grep -c "kind: HorizontalPodAutoscaler" 2>/dev/null || echo "0")
    ACTUAL_VIRTUALSERVICES=$(echo "$yaml_content" | grep -c "kind: VirtualService" 2>/dev/null || echo "0")
    ACTUAL_CONFIGMAPS=$(echo "$yaml_content" | grep -c "kind: ConfigMap" 2>/dev/null || echo "0")
    
    # Ensure all counts are integers (fix for bash comparison issues)
    ACTUAL_DEPLOYMENTS=${ACTUAL_DEPLOYMENTS//[^0-9]/}
    ACTUAL_STATEFULSETS=${ACTUAL_STATEFULSETS//[^0-9]/}
    ACTUAL_JOBS=${ACTUAL_JOBS//[^0-9]/}
    ACTUAL_CRONJOBS=${ACTUAL_CRONJOBS//[^0-9]/}
    ACTUAL_SERVICES=${ACTUAL_SERVICES//[^0-9]/}
    ACTUAL_SERVICEACCOUNTS=${ACTUAL_SERVICEACCOUNTS//[^0-9]/}
    ACTUAL_PVCS=${ACTUAL_PVCS//[^0-9]/}
    ACTUAL_SECRETS=${ACTUAL_SECRETS//[^0-9]/}
    ACTUAL_HPAS=${ACTUAL_HPAS//[^0-9]/}
    ACTUAL_VIRTUALSERVICES=${ACTUAL_VIRTUALSERVICES//[^0-9]/}
    ACTUAL_CONFIGMAPS=${ACTUAL_CONFIGMAPS//[^0-9]/}
    
    # Extract resource names for detailed validation
    RESOURCE_NAMES=$(echo "$yaml_content" | grep -E "^\s*name:" | sed -E 's/^\s*name:\s*([^"]*).*/\1/' | sort)
}

# Validate resource completeness
validate_completeness() {
    local chart_name="$1"
    local example_name="$2"
    local issues=0
    
    echo -e "${BLUE}  Checking resource completeness...${RESET}"
    
    # Workload validation
    if [ "$WORKLOAD_ENABLED" = "true" ]; then
        if [ "$WORKLOAD_TYPE" = "deployment" ] && [ "$ACTUAL_DEPLOYMENTS" -eq 0 ]; then
            echo -e "${RED}    [ERROR] Expected Deployment but found none${RESET}"
            ((issues++))
        elif [ "$WORKLOAD_TYPE" = "statefulset" ] && [ "$ACTUAL_STATEFULSETS" -eq 0 ]; then
            echo -e "${RED}    [ERROR] Expected StatefulSet but found none${RESET}"
            ((issues++))
        elif [ "$WORKLOAD_TYPE" = "job" ] && [ "$ACTUAL_JOBS" -eq 0 ]; then
            echo -e "${RED}    [ERROR] Expected Job but found none${RESET}"
            ((issues++))
        elif [ "$WORKLOAD_TYPE" = "cronjob" ] && [ "$ACTUAL_CRONJOBS" -eq 0 ]; then
            echo -e "${RED}    [ERROR] Expected CronJob but found none${RESET}"
            ((issues++))
        else
            echo -e "${GREEN}    [OK] Workload resource present (${WORKLOAD_TYPE})${RESET}"
        fi
    fi
    
    # Service validation
    if [ "$SERVICE_ENABLED" = "true" ] && [ "$ACTUAL_SERVICES" -eq 0 ]; then
        echo -e "${RED}    [ERROR] Expected Service but found none${RESET}"
        ((issues++))
    elif [ "$SERVICE_ENABLED" = "true" ]; then
        echo -e "${GREEN}    [OK] Service resource present${RESET}"
    fi
    
    # ServiceAccount validation
    if [ "$SERVICEACCOUNT_ENABLED" = "true" ] && [ "$ACTUAL_SERVICEACCOUNTS" -eq 0 ]; then
        echo -e "${RED}    [ERROR] Expected ServiceAccount but found none${RESET}"
        ((issues++))
    elif [ "$SERVICEACCOUNT_ENABLED" = "true" ]; then
        echo -e "${GREEN}    [OK] ServiceAccount resource present${RESET}"
    fi
    
    # PVC validation (handles both regular PVCs and StatefulSet volumeClaimTemplates)
    if [ "$PVC_COUNT" -gt 0 ] && [ "$ACTUAL_PVCS" -lt "$PVC_COUNT" ]; then
        echo -e "${RED}    [ERROR] Expected $PVC_COUNT PVCs but found $ACTUAL_PVCS${RESET}"
        ((issues++))
    elif [ "$PVC_COUNT" -gt 0 ]; then
        echo -e "${GREEN}    [OK] All $PVC_COUNT PVC resources present${RESET}"
    fi
    
    # StatefulSet volumeClaimTemplates validation (these don't generate PVC resources)
    if [ "$VOLUMECLAIMTEMPLATE_COUNT" -gt 0 ] && [ "$WORKLOAD_TYPE" = "statefulset" ]; then
        echo -e "${GREEN}    [OK] StatefulSet with $VOLUMECLAIMTEMPLATE_COUNT volumeClaimTemplates configured${RESET}"
    elif [ "$VOLUMECLAIMTEMPLATE_COUNT" -gt 0 ] && [ "$WORKLOAD_TYPE" != "statefulset" ]; then
        echo -e "${YELLOW}    [WARN]  volumeClaimTemplates configured but workload type is not StatefulSet${RESET}"
    fi
    
    # Secret validation
    if [ "$SECRET_COUNT" -gt 0 ] && [ "$ACTUAL_SECRETS" -lt "$SECRET_COUNT" ]; then
        echo -e "${RED}    [ERROR] Expected $SECRET_COUNT Secrets but found $ACTUAL_SECRETS${RESET}"
        ((issues++))
    elif [ "$SECRET_COUNT" -gt 0 ]; then
        echo -e "${GREEN}    [OK] All $SECRET_COUNT Secret resources present${RESET}"
    fi
    
    # HPA validation
    if [ "$AUTOSCALING_ENABLED" = "true" ] && [ "$ACTUAL_HPAS" -eq 0 ]; then
        echo -e "${RED}    [ERROR] Expected HorizontalPodAutoscaler but found none${RESET}"
        ((issues++))
    elif [ "$AUTOSCALING_ENABLED" = "true" ]; then
        echo -e "${GREEN}    [OK] HorizontalPodAutoscaler resource present${RESET}"
    fi
    
    # VirtualService validation (for external services)
    if [ "$SERVICE_EXTERNAL" = "true" ] || [ "$NEEDS_VIRTUALSERVICE" = "true" ]; then
        if [ "$ACTUAL_VIRTUALSERVICES" -eq 0 ]; then
            echo -e "${YELLOW}    [WARN]  Expected VirtualService for external service but found none (may need Istio glyph)${RESET}"
        else
            echo -e "${GREEN}    [OK] VirtualService resource present${RESET}"
        fi
    fi
    
    # Chart-specific validations
    case "$chart_name" in
        "microspell")
            validate_microspell_completeness "$example_name"
            issues=$((issues + $?))
            ;;
        "summon")
            validate_summon_completeness "$example_name"
            issues=$((issues + $?))
            ;;
    esac
    
    return $issues
}

validate_microspell_completeness() {
    local example_name="$1"
    local issues=0
    
    echo -e "${BLUE}    Microspell-specific validation...${RESET}"
    
    # Microspell should always create a workload (deployment, statefulset, job, or cronjob)
    local total_workloads=$((ACTUAL_DEPLOYMENTS + ACTUAL_STATEFULSETS + ACTUAL_JOBS + ACTUAL_CRONJOBS))
    if [ "$total_workloads" -eq 0 ]; then
        echo -e "${RED}      [ERROR] Microspell must generate at least one workload${RESET}"
        ((issues++))
    fi
    
    # If secrets are configured, they should be present or referenced
    if [ "$SECRET_COUNT" -gt 0 ]; then
        echo -e "${GREEN}      [OK] Secrets configuration detected${RESET}"
    fi
    
    return $issues
}

validate_summon_completeness() {
    local example_name="$1"
    local issues=0
    
    echo -e "${BLUE}    Summon-specific validation...${RESET}"
    
    # StatefulSet examples should have persistent storage (either PVCs or volumeClaimTemplates)
    if [[ "$example_name" == *"statefulset"* ]] && [ "$ACTUAL_PVCS" -eq 0 ] && [ "$VOLUMECLAIMTEMPLATE_COUNT" -eq 0 ]; then
        echo -e "${YELLOW}      [WARN]  StatefulSet example without persistent storage (PVCs or volumeClaimTemplates)${RESET}"
    elif [[ "$example_name" == *"statefulset"* ]] && [ "$VOLUMECLAIMTEMPLATE_COUNT" -gt 0 ]; then
        echo -e "${GREEN}      [OK] StatefulSet with volumeClaimTemplates storage properly configured${RESET}"
    fi
    
    # Storage examples should have PVCs or volumeClaimTemplates
    if [[ "$example_name" == *"storage"* ]] && [ "$ACTUAL_PVCS" -eq 0 ] && [ "$VOLUMECLAIMTEMPLATE_COUNT" -eq 0 ]; then
        echo -e "${RED}      [ERROR] Storage example but no PVCs or volumeClaimTemplates configured${RESET}"
        ((issues++))
    elif [[ "$example_name" == *"storage"* ]] && [ "$VOLUMECLAIMTEMPLATE_COUNT" -gt 0 ]; then
        echo -e "${GREEN}      [OK] Storage example with volumeClaimTemplates properly configured${RESET}"
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
    
    echo -e "${BLUE}[TEST] Validating resource completeness for $test_name${RESET}"
    
    # Parse expected configuration
    echo -e "${BLUE}  Parsing configuration expectations...${RESET}"
    parse_values "$example_file"
    
    # Render template
    local yaml_content
    yaml_content=$(helm template "$test_name" "$chart_dir" -f "$example_file" 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo -e "${RED}  [ERROR] Failed to render template${RESET}"
        return 1
    fi
    
    # Extract actual resources
    echo -e "${BLUE}  Extracting actual resources...${RESET}"
    extract_resources "$yaml_content"
    
    # Show summary
    echo -e "${BLUE}  Resource Summary:${RESET}"
    echo -e "    Deployments: $(printf "%02d" $ACTUAL_DEPLOYMENTS), StatefulSets: $(printf "%02d" $ACTUAL_STATEFULSETS), Jobs: $(printf "%02d" $ACTUAL_JOBS), CronJobs: $(printf "%02d" $ACTUAL_CRONJOBS)"
    echo -e "    Services: $ACTUAL_SERVICES, ServiceAccounts: $ACTUAL_SERVICEACCOUNTS"
    echo -e "    PVCs: $(printf "%02d" $ACTUAL_PVCS), Secrets: $(printf "%02d" $ACTUAL_SECRETS)"
    echo -e "    HPAs: $(printf "%02d" $ACTUAL_HPAS), VirtualServices: $(printf "%02d" $ACTUAL_VIRTUALSERVICES)"
    
    # Validate completeness
    if validate_completeness "$chart_name" "$example_name"; then
        echo -e "${GREEN}[OK] Resource completeness validation passed${RESET}"
        return 0
    else
        echo -e "${RED}[ERROR] Resource completeness validation failed${RESET}"
        return 1
    fi
}

# If called directly, run main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi