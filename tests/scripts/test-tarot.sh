#!/bin/bash
# Tarot Testing Script
# Comprehensive testing for Tarot trinket (Argo Workflows)

set -euo pipefail

# Colors
BLUE='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

# Tarot chart directory
TAROT_DIR="charts/trinkets/tarot"

# Change to repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

# Test modes
MODE="${1:-all}"

usage() {
    echo "Usage: $0 [mode]"
    echo ""
    echo "Modes:"
    echo "  all              - Run all tarot tests (default)"
    echo "  syntax           - Test Helm template syntax"
    echo "  execution-modes  - Test container/DAG execution modes"
    echo "  card-resolution  - Test card resolution system"
    echo "  secrets          - Test secret management"
    echo "  rbac             - Test RBAC generation"
    echo "  complex          - Test complex workflows"
    echo ""
    exit 1
}

# ═══════════════════════════════════════════════════════════════════════════
# Test: Syntax Validation
# ═══════════════════════════════════════════════════════════════════════════
test_syntax() {
    echo -e "${BLUE}🧪 Testing Helm Template Syntax...${RESET}"

    local failed=0

    for example in "$TAROT_DIR"/examples/*.yaml; do
        local example_name=$(basename "$example" .yaml)
        echo -e "${BLUE}  📋 Testing $example_name...${RESET}"

        if helm template "test-$example_name" "$TAROT_DIR" -f "$example" --dry-run > /dev/null 2>&1; then
            echo -e "${GREEN}    ✅ Template renders successfully${RESET}"
        else
            echo -e "${RED}    ❌ Template rendering failed${RESET}"
            failed=$((failed + 1))
        fi
    done

    return $failed
}

# ═══════════════════════════════════════════════════════════════════════════
# Test: Execution Modes
# ═══════════════════════════════════════════════════════════════════════════
test_execution_modes() {
    echo -e "${BLUE}🎯 Testing Execution Modes...${RESET}"

    local failed=0

    # Test Container Mode
    echo -e "${BLUE}  🔍 Container Mode...${RESET}"
    if helm template test-container "$TAROT_DIR" -f "$TAROT_DIR/examples/minimal-test.yaml" | grep -q "container:"; then
        echo -e "${GREEN}    ✅ Container mode working${RESET}"
    else
        echo -e "${RED}    ❌ Container mode failed${RESET}"
        failed=$((failed + 1))
    fi

    # Test DAG Mode
    echo -e "${BLUE}  🔍 DAG Mode...${RESET}"
    if helm template test-dag "$TAROT_DIR" -f "$TAROT_DIR/examples/simple-dag-test.yaml" | grep -q "dag:"; then
        echo -e "${GREEN}    ✅ DAG mode working${RESET}"
    else
        echo -e "${RED}    ❌ DAG mode failed${RESET}"
        failed=$((failed + 1))
    fi

    return $failed
}

# ═══════════════════════════════════════════════════════════════════════════
# Test: Card Resolution
# ═══════════════════════════════════════════════════════════════════════════
test_card_resolution() {
    echo -e "${BLUE}🎴 Testing Card Resolution...${RESET}"

    local failed=0

    if helm template test-cards "$TAROT_DIR" -f "$TAROT_DIR/examples/mixed-cards-example.yaml" > /dev/null 2>&1; then
        echo -e "${GREEN}    ✅ Card resolution working${RESET}"
    else
        echo -e "${RED}    ❌ Card resolution failed${RESET}"
        failed=$((failed + 1))
    fi

    return $failed
}

# ═══════════════════════════════════════════════════════════════════════════
# Test: Secret Management
# ═══════════════════════════════════════════════════════════════════════════
test_secrets() {
    echo -e "${BLUE}🔐 Testing Secret Management...${RESET}"

    local failed=0

    if helm template test-secrets "$TAROT_DIR" -f "$TAROT_DIR/examples/basic-ci-custom.yaml" | grep -q "kind: Secret"; then
        echo -e "${GREEN}    ✅ Secret generation working${RESET}"
    else
        echo -e "${RED}    ❌ Secret generation failed${RESET}"
        failed=$((failed + 1))
    fi

    return $failed
}

# ═══════════════════════════════════════════════════════════════════════════
# Test: RBAC System
# ═══════════════════════════════════════════════════════════════════════════
test_rbac() {
    echo -e "${BLUE}👮 Testing RBAC System...${RESET}"

    local failed=0

    if helm template test-rbac "$TAROT_DIR" -f "$TAROT_DIR/examples/simple-dag-test.yaml" | grep -q "kind: ServiceAccount"; then
        echo -e "${GREEN}    ✅ RBAC generation working${RESET}"
    else
        echo -e "${RED}    ❌ RBAC generation failed${RESET}"
        failed=$((failed + 1))
    fi

    return $failed
}

# ═══════════════════════════════════════════════════════════════════════════
# Test: Complex Workflows
# ═══════════════════════════════════════════════════════════════════════════
test_complex() {
    echo -e "${BLUE}🎪 Testing Complex Workflows...${RESET}"

    local failed=0
    local examples=(
        "enterprise-approval.yaml"
        "complex-ml-pipeline.yaml"
    )

    for example in "${examples[@]}"; do
        local example_path="$TAROT_DIR/examples/$example"

        if [ ! -f "$example_path" ]; then
            echo -e "${YELLOW}  ⚠️  Example not found: $example (skipping)${RESET}"
            continue
        fi

        local example_name=$(basename "$example" .yaml)
        echo -e "${BLUE}  🏭 Testing $example_name...${RESET}"

        if helm template "test-$example_name" "$TAROT_DIR" -f "$example_path" > /dev/null 2>&1; then
            echo -e "${GREEN}    ✅ Complex workflow renders${RESET}"
        else
            echo -e "${RED}    ❌ Complex workflow failed${RESET}"
            failed=$((failed + 1))
        fi
    done

    return $failed
}

# ═══════════════════════════════════════════════════════════════════════════
# Main dispatcher
# ═══════════════════════════════════════════════════════════════════════════
main() {
    echo -e "${BLUE}🎭 TDD: Testing Tarot System...${RESET}"
    echo ""

    local total_failures=0

    case "$MODE" in
        all)
            test_syntax || total_failures=$((total_failures + $?))
            echo ""
            test_execution_modes || total_failures=$((total_failures + $?))
            echo ""
            test_card_resolution || total_failures=$((total_failures + $?))
            echo ""
            test_secrets || total_failures=$((total_failures + $?))
            echo ""
            test_rbac || total_failures=$((total_failures + $?))
            echo ""
            ;;
        syntax)
            test_syntax || total_failures=$?
            ;;
        execution-modes)
            test_execution_modes || total_failures=$?
            ;;
        card-resolution)
            test_card_resolution || total_failures=$?
            ;;
        secrets)
            test_secrets || total_failures=$?
            ;;
        rbac)
            test_rbac || total_failures=$?
            ;;
        complex)
            test_complex || total_failures=$?
            ;;
        *)
            usage
            ;;
    esac

    echo ""
    if [ $total_failures -eq 0 ]; then
        echo -e "${GREEN}✅ Tarot system tests completed successfully!${RESET}"
        exit 0
    else
        echo -e "${RED}❌ Tarot tests failed with $total_failures error(s)${RESET}"
        exit 1
    fi
}

main "$@"
