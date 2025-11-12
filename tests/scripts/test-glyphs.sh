#!/bin/bash
# Glyph Testing Script
# Tests glyphs through kaster orchestration with output validation

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

MODE="${1:-}"
GLYPH="${2:-}"
EXAMPLE="${3:-}"

GLYPHS_DIR="charts/glyphs"
KASTER_DIR="charts/kaster"
OUTPUT_TEST_DIR="output-test"

usage() {
    echo "Usage: $0 <mode> [glyph] [example]"
    echo ""
    echo "Modes:"
    echo "  all                        - Test all glyphs"
    echo "  test <glyph>              - Test specific glyph"
    echo "  generate <glyph>          - Generate expected outputs for glyph"
    echo "  show-diff <glyph> <example> - Show diff for glyph test"
    echo ""
    echo "Examples:"
    echo "  $0 all"
    echo "  $0 test vault"
    echo "  $0 generate vault"
    echo "  $0 show-diff vault secrets"
    exit 1
}

# ═══════════════════════════════════════════════════════════════════════════
# MODE: all - Test all glyphs
# ═══════════════════════════════════════════════════════════════════════════
test_all_glyphs() {
    echo -e "${BLUE}🎭 TDD: Testing all glyphs through kaster orchestration...${RESET}"

    for glyph_dir in "$GLYPHS_DIR"/*/; do
        glyph_name=$(basename "$glyph_dir")

        if [ -d "$glyph_dir/examples" ]; then
            test_glyph "$glyph_name" || true
        fi
    done

    echo -e "${GREEN}✅ All glyph tests completed!${RESET}"
}

# ═══════════════════════════════════════════════════════════════════════════
# MODE: test - Test specific glyph
# ═══════════════════════════════════════════════════════════════════════════
test_glyph() {
    local glyph_name="$1"
    local glyph_dir="$GLYPHS_DIR/$glyph_name"

    if [ ! -d "$glyph_dir" ]; then
        echo -e "${RED}❌ Glyph $glyph_name not found in $glyph_dir${RESET}"
        echo -e "${BLUE}Available glyphs:${RESET}"
        ls -1 "$GLYPHS_DIR" | sed 's/^/  - /'
        exit 1
    fi

    if [ ! -d "$glyph_dir/examples" ]; then
        echo -e "${YELLOW}⚠️  $glyph_name has no examples/ directory${RESET}"
        exit 1
    fi

    echo -e "${BLUE}🎭 Testing $glyph_name glyphs...${RESET}"
    mkdir -p "$OUTPUT_TEST_DIR/$glyph_name"

    for example in "$glyph_dir"/examples/*.yaml; do
        if [ -f "$example" ]; then
            local example_name=$(basename "$example" .yaml)
            local test_name=$(echo "tdd-$glyph_name-$example_name" | tr '[:upper:]' '[:lower:]')

            echo -e "${BLUE}  Testing $example_name...${RESET}"

            if helm template "$test_name" "$KASTER_DIR" -f "$example" > "$OUTPUT_TEST_DIR/$glyph_name/$example_name.yaml" 2>/dev/null; then
                local expected_file="$OUTPUT_TEST_DIR/$glyph_name/$example_name.expected.yaml"

                if [ -f "$expected_file" ]; then
                    if diff -q "$OUTPUT_TEST_DIR/$glyph_name/$example_name.yaml" "$expected_file" > /dev/null 2>&1; then
                        echo -e "${GREEN}✅ $glyph_name-$example_name (output matches expected)${RESET}"
                    else
                        echo -e "${RED}❌ $glyph_name-$example_name (output differs from expected)${RESET}"
                        echo -e "${YELLOW}  Run: diff $OUTPUT_TEST_DIR/$glyph_name/$example_name.yaml $expected_file${RESET}"
                    fi
                else
                    echo -e "${GREEN}✅ $glyph_name-$example_name (rendered successfully, no expected output to compare)${RESET}"
                    echo -e "${YELLOW}  💡 To add output validation, create: $expected_file${RESET}"
                fi
            else
                echo -e "${RED}❌ $glyph_name-$example_name (rendering failed)${RESET}"
            fi
        fi
    done
}

# ═══════════════════════════════════════════════════════════════════════════
# MODE: generate - Generate expected outputs for glyph
# ═══════════════════════════════════════════════════════════════════════════
generate_expected() {
    local glyph_name="$1"
    local glyph_dir="$GLYPHS_DIR/$glyph_name"

    if [ -z "$glyph_name" ]; then
        echo -e "${RED}Error: Glyph name required${RESET}"
        echo -e "${BLUE}Available glyphs:${RESET}"
        ls -1 "$GLYPHS_DIR" | sed 's/^/  - /'
        exit 1
    fi

    if [ ! -d "$glyph_dir" ]; then
        echo -e "${RED}❌ Glyph $glyph_name not found in $glyph_dir${RESET}"
        echo -e "${BLUE}Available glyphs:${RESET}"
        ls -1 "$GLYPHS_DIR" | sed 's/^/  - /'
        exit 1
    fi

    mkdir -p "$OUTPUT_TEST_DIR/$glyph_name"
    echo -e "${BLUE}📄 Generating expected outputs for $glyph_name...${RESET}"

    for example in "$glyph_dir"/examples/*.yaml; do
        if [ -f "$example" ]; then
            local example_name=$(basename "$example" .yaml)
            local test_name="tdd-$glyph_name-$example_name"

            echo -e "${BLUE}  Generating $example_name.expected.yaml...${RESET}"

            if helm template "$test_name" "$KASTER_DIR" -f "$example" > "$OUTPUT_TEST_DIR/$glyph_name/$example_name.expected.yaml" 2>/dev/null; then
                echo -e "${GREEN}✅ Generated $example_name.expected.yaml${RESET}"
            else
                echo -e "${RED}❌ Failed to generate $example_name.expected.yaml${RESET}"
            fi
        fi
    done
}

# ═══════════════════════════════════════════════════════════════════════════
# MODE: show-diff - Show diff for specific glyph test
# ═══════════════════════════════════════════════════════════════════════════
show_diff() {
    local glyph_name="$1"
    local example_name="$2"

    if [ -z "$glyph_name" ] || [ -z "$example_name" ]; then
        echo -e "${RED}Error: Glyph and example names required${RESET}"
        echo -e "${YELLOW}Usage: $0 show-diff vault secrets${RESET}"
        exit 1
    fi

    local actual="$OUTPUT_TEST_DIR/$glyph_name/$example_name.yaml"
    local expected="$OUTPUT_TEST_DIR/$glyph_name/$example_name.expected.yaml"

    if [ ! -f "$actual" ] || [ ! -f "$expected" ]; then
        echo -e "${RED}❌ Missing files${RESET}"
        echo -e "${YELLOW}Run: make glyphs $glyph_name && make generate-expected GLYPH=$glyph_name${RESET}"
        exit 1
    fi

    echo -e "${BLUE}🔍 Showing diff for $glyph_name/$example_name...${RESET}"
    diff -u "$expected" "$actual" || echo -e "${YELLOW}Files differ${RESET}"
}

# ═══════════════════════════════════════════════════════════════════════════
# Main dispatcher
# ═══════════════════════════════════════════════════════════════════════════
case "$MODE" in
    all)
        test_all_glyphs
        ;;
    test)
        test_glyph "$GLYPH"
        ;;
    generate)
        generate_expected "$GLYPH"
        ;;
    show-diff)
        show_diff "$GLYPH" "$EXAMPLE"
        ;;
    *)
        usage
        ;;
esac
