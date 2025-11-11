#!/bin/bash
# Consolidated Chart Testing Script
# Handles syntax, comprehensive, and snapshot testing

set -euo pipefail

# Colors
BLUE='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

# Change to repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

MODE="${1:-comprehensive}"
OUTPUT_TEST_DIR="output-test"

usage() {
    echo "Usage: $0 <mode>"
    echo ""
    echo "Modes:"
    echo "  syntax        - Quick syntax validation"
    echo "  comprehensive - Rendering + resource completeness (default)"
    echo "  snapshots     - Snapshot comparison + K8s schema validation"
    echo ""
    exit 1
}

# ═══════════════════════════════════════════════════════════════════════════
# MODE: syntax - Quick validation
# ═══════════════════════════════════════════════════════════════════════════
test_syntax() {
    echo -e "${BLUE}🚀 TDD: Running syntax validation...${RESET}"

    local failed=0

    find . -name "Chart.yaml" -not -path "./charts/glyphs/*" | while read chart_file; do
        chart_dir=$(dirname "$chart_file")
        chart_name=$(basename "$chart_dir")

        if helm template "test-syntax-$chart_name" "$chart_dir" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ $chart_name syntax${RESET}"
        else
            echo -e "${RED}❌ $chart_name syntax${RESET}"
            failed=$((failed + 1))
        fi
    done

    return $failed
}

# ═══════════════════════════════════════════════════════════════════════════
# MODE: comprehensive - Rendering + resource completeness
# ═══════════════════════════════════════════════════════════════════════════
test_comprehensive() {
    echo -e "${BLUE}🧪 TDD: Comprehensive validation (rendering + resource expectations)...${RESET}"

    local total_failed=0

    find . -name "Chart.yaml" -not -path "./charts/glyphs/*" | while read chart_file; do
        chart_dir=$(dirname "$chart_file")
        chart_name=$(basename "$chart_dir")

        echo -e "${BLUE}Testing chart: $chart_name${RESET}"

        if [ -d "$chart_dir/examples" ]; then
            for example in "$chart_dir"/examples/*.yaml; do
                if [ -f "$example" ]; then
                    example_name=$(basename "$example" .yaml)
                    test_name="tdd-$chart_name-$example_name"

                    echo -e "${BLUE}  Validating $example_name...${RESET}"

                    if helm template "$test_name" "$chart_dir" -f "$example" > /dev/null 2>&1; then
                        if tests/scripts/validate-resource-completeness.sh "$chart_dir" "$example" "$test_name" 2>&1 | grep -q "✅"; then
                            echo -e "${GREEN}✅ $chart_name-$example_name${RESET}"
                        else
                            echo -e "${RED}❌ $chart_name-$example_name (expectations failed)${RESET}"
                            total_failed=$((total_failed + 1))
                        fi
                    else
                        echo -e "${RED}❌ $chart_name-$example_name (rendering failed)${RESET}"
                        total_failed=$((total_failed + 1))
                    fi
                fi
            done
        else
            echo -e "${YELLOW}⚠️  $chart_name has no examples/ directory - create test examples for TDD${RESET}"

            if helm template "test-$chart_name" "$chart_dir" > /dev/null 2>&1; then
                echo -e "${GREEN}✅ $chart_name-basic${RESET}"
            else
                echo -e "${RED}❌ $chart_name-basic${RESET}"
                total_failed=$((total_failed + 1))
            fi
        fi
    done

    return $total_failed
}

# ═══════════════════════════════════════════════════════════════════════════
# MODE: snapshots - Snapshot comparison + K8s schema
# ═══════════════════════════════════════════════════════════════════════════
test_snapshots() {
    echo -e "${BLUE}📸 TDD: Snapshot + K8s schema validation...${RESET}"

    local total_failed=0

    find . -name "Chart.yaml" -not -path "./charts/glyphs/*" | while read chart_file; do
        chart_dir=$(dirname "$chart_file")
        chart_name=$(basename "$chart_dir")

        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -e "${BLUE}Testing chart: $chart_name${RESET}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

        if [ -d "$chart_dir/examples" ]; then
            for example in "$chart_dir"/examples/*.yaml; do
                if [ -f "$example" ]; then
                    example_name=$(basename "$example" .yaml)
                    test_name="tdd-$chart_name-$example_name"

                    echo -e "${BLUE}  Testing $example_name...${RESET}"

                    mkdir -p "$OUTPUT_TEST_DIR/$chart_name"
                    actual_output="$OUTPUT_TEST_DIR/$chart_name/$example_name.yaml"
                    expected_output="$OUTPUT_TEST_DIR/$chart_name/$example_name.expected.yaml"
                    issues=0

                    # Step 1: Rendering
                    echo -e "${BLUE}    [1/3] Rendering template...${RESET}"
                    if helm template "$test_name" "$chart_dir" -f "$example" > "$actual_output" 2>/dev/null; then
                        echo -e "${GREEN}      ✅ Rendered successfully${RESET}"
                    else
                        echo -e "${RED}      ❌ Rendering failed${RESET}"
                        issues=$((issues + 1))
                    fi

                    if [ $issues -eq 0 ]; then
                        # Step 2: Snapshot comparison
                        echo -e "${BLUE}    [2/3] Snapshot comparison...${RESET}"
                        if [ -f "$expected_output" ]; then
                            if diff -q "$actual_output" "$expected_output" > /dev/null 2>&1; then
                                echo -e "${GREEN}      ✅ Snapshot matches${RESET}"
                            else
                                echo -e "${RED}      ❌ Snapshot differs${RESET}"
                                echo -e "${YELLOW}      💡 diff $actual_output $expected_output${RESET}"
                                echo -e "${YELLOW}      💡 make update-snapshot CHART=$chart_name EXAMPLE=$example_name${RESET}"
                                issues=$((issues + 1))
                            fi
                        else
                            echo -e "${YELLOW}      ⚠️  No snapshot (run: make generate-snapshots CHART=$chart_name)${RESET}"
                        fi

                        # Step 3: K8s schema validation
                        echo -e "${BLUE}    [3/3] K8s schema validation...${RESET}"
                        if helm install "$test_name" "$chart_dir" -f "$example" --dry-run --namespace validate-ns --create-namespace > /dev/null 2>&1; then
                            echo -e "${GREEN}      ✅ Schema valid${RESET}"
                        else
                            echo -e "${RED}      ❌ Schema validation failed${RESET}"
                            issues=$((issues + 1))
                        fi
                    fi

                    if [ $issues -eq 0 ]; then
                        echo -e "${GREEN}  ✅ $chart_name-$example_name${RESET}"
                    else
                        echo -e "${RED}  ❌ $chart_name-$example_name ($issues issues)${RESET}"
                        total_failed=$((total_failed + 1))
                    fi

                    echo ""
                fi
            done
        else
            echo -e "${YELLOW}⚠️  $chart_name has no examples/ directory - create test examples for TDD${RESET}"

            if helm template "test-$chart_name" "$chart_dir" > /dev/null 2>&1; then
                echo -e "${GREEN}✅ $chart_name-basic${RESET}"
            else
                echo -e "${RED}❌ $chart_name-basic${RESET}"
                total_failed=$((total_failed + 1))
            fi
        fi
    done

    return $total_failed
}

# ═══════════════════════════════════════════════════════════════════════════
# Main dispatcher
# ═══════════════════════════════════════════════════════════════════════════
case "$MODE" in
    syntax)
        test_syntax
        ;;
    comprehensive)
        test_comprehensive
        ;;
    snapshots)
        test_snapshots
        ;;
    *)
        usage
        ;;
esac
