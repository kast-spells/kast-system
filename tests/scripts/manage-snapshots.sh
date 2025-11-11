#!/bin/bash
# Snapshot Management Script
# Generate, update, and show diffs for chart snapshots

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
CHART="${2:-}"
EXAMPLE="${3:-}"
OUTPUT_TEST_DIR="output-test"

usage() {
    echo "Usage: $0 <mode> [chart] [example]"
    echo ""
    echo "Modes:"
    echo "  generate <chart>           - Generate all snapshots for chart"
    echo "  update <chart> <example>   - Update specific snapshot"
    echo "  update-all                 - Update all snapshots"
    echo "  show-diff <chart> <example> - Show diff for snapshot"
    echo ""
    echo "Examples:"
    echo "  $0 generate summon"
    echo "  $0 update summon basic-deployment"
    echo "  $0 update-all"
    echo "  $0 show-diff summon basic-deployment"
    exit 1
}

# ═══════════════════════════════════════════════════════════════════════════
# MODE: generate - Generate snapshots for chart
# ═══════════════════════════════════════════════════════════════════════════
generate_snapshots() {
    local chart_name="$1"

    if [ -z "$chart_name" ]; then
        echo -e "${RED}Error: Chart name required${RESET}"
        echo -e "${BLUE}Available charts:${RESET}"
        find . -name "Chart.yaml" -not -path "./charts/glyphs/*" -exec dirname {} \; | xargs -n1 basename | sed 's/^/  - /'
        exit 1
    fi

    local chart_dir="charts/$chart_name"

    # Handle trinkets
    if [ "$chart_name" = "microspell" ] || [ "$chart_name" = "tarot" ] || [ "$chart_name" = "covenant" ]; then
        chart_dir="charts/trinkets/$chart_name"
    elif [ "$chart_name" = "librarian" ]; then
        chart_dir="librarian"
    fi

    if [ ! -d "$chart_dir" ]; then
        echo -e "${RED}❌ Chart not found: $chart_dir${RESET}"
        exit 1
    fi

    if [ ! -d "$chart_dir/examples" ]; then
        echo -e "${YELLOW}⚠️  No examples directory for $chart_name${RESET}"
        exit 0
    fi

    mkdir -p "$OUTPUT_TEST_DIR/$chart_name"
    echo -e "${BLUE}📸 Generating snapshots for $chart_name...${RESET}"

    for example in "$chart_dir"/examples/*.yaml; do
        if [ -f "$example" ]; then
            local example_name=$(basename "$example" .yaml)
            local test_name="snapshot-$chart_name-$example_name"
            local output_file="$OUTPUT_TEST_DIR/$chart_name/$example_name.expected.yaml"

            echo -e "${BLUE}  Generating $example_name.expected.yaml...${RESET}"

            if helm template "$test_name" "$chart_dir" -f "$example" > "$output_file" 2>/dev/null; then
                echo -e "${GREEN}✅ Generated $example_name.expected.yaml${RESET}"
            else
                echo -e "${RED}❌ Failed to generate $example_name.expected.yaml${RESET}"
            fi
        fi
    done
}

# ═══════════════════════════════════════════════════════════════════════════
# MODE: update - Update specific snapshot
# ═══════════════════════════════════════════════════════════════════════════
update_snapshot() {
    local chart_name="$1"
    local example_name="$2"

    if [ -z "$chart_name" ] || [ -z "$example_name" ]; then
        echo -e "${RED}Error: Chart and example names required${RESET}"
        echo -e "${YELLOW}Usage: $0 update summon basic-deployment${RESET}"
        exit 1
    fi

    local chart_dir="charts/$chart_name"

    # Handle trinkets
    if [ "$chart_name" = "microspell" ] || [ "$chart_name" = "tarot" ] || [ "$chart_name" = "covenant" ]; then
        chart_dir="charts/trinkets/$chart_name"
    elif [ "$chart_name" = "librarian" ]; then
        chart_dir="librarian"
    fi

    local example_file="$chart_dir/examples/$example_name.yaml"
    local output_file="$OUTPUT_TEST_DIR/$chart_name/$example_name.expected.yaml"

    if [ ! -f "$example_file" ]; then
        echo -e "${RED}❌ Example not found: $example_file${RESET}"
        exit 1
    fi

    mkdir -p "$OUTPUT_TEST_DIR/$chart_name"
    echo -e "${BLUE}🔄 Updating snapshot: $chart_name/$example_name${RESET}"

    local test_name="update-$chart_name-$example_name"

    if helm template "$test_name" "$chart_dir" -f "$example_file" > "$output_file" 2>/dev/null; then
        echo -e "${GREEN}✅ Updated $output_file${RESET}"
    else
        echo -e "${RED}❌ Failed to update snapshot${RESET}"
        exit 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# MODE: update-all - Update all snapshots
# ═══════════════════════════════════════════════════════════════════════════
update_all_snapshots() {
    echo -e "${BLUE}📸 Updating all snapshots...${RESET}"

    find . -name "Chart.yaml" -not -path "./charts/glyphs/*" | while read chart_file; do
        local chart_dir=$(dirname "$chart_file")
        local chart_name=$(basename "$chart_dir")

        if [ -d "$chart_dir/examples" ]; then
            echo -e "${BLUE}Updating snapshots for: $chart_name${RESET}"
            generate_snapshots "$chart_name"
        fi
    done

    echo -e "${GREEN}✅ All snapshots updated${RESET}"
}

# ═══════════════════════════════════════════════════════════════════════════
# MODE: show-diff - Show diff for snapshot
# ═══════════════════════════════════════════════════════════════════════════
show_diff() {
    local chart_name="$1"
    local example_name="$2"

    if [ -z "$chart_name" ] || [ -z "$example_name" ]; then
        echo -e "${RED}Error: Chart and example names required${RESET}"
        echo -e "${YELLOW}Usage: $0 show-diff summon basic-deployment${RESET}"
        exit 1
    fi

    local actual="$OUTPUT_TEST_DIR/$chart_name/$example_name.yaml"
    local expected="$OUTPUT_TEST_DIR/$chart_name/$example_name.expected.yaml"

    if [ ! -f "$actual" ] || [ ! -f "$expected" ]; then
        echo -e "${RED}❌ Missing files${RESET}"
        echo -e "${YELLOW}Run: make test-snapshots${RESET}"
        exit 1
    fi

    echo -e "${BLUE}🔍 Showing diff for $chart_name/$example_name...${RESET}"
    diff -u "$expected" "$actual" || echo -e "${YELLOW}Files differ${RESET}"
}

# ═══════════════════════════════════════════════════════════════════════════
# Main dispatcher
# ═══════════════════════════════════════════════════════════════════════════
case "$MODE" in
    generate)
        generate_snapshots "$CHART"
        ;;
    update)
        update_snapshot "$CHART" "$EXAMPLE"
        ;;
    update-all)
        update_all_snapshots
        ;;
    show-diff)
        show_diff "$CHART" "$EXAMPLE"
        ;;
    *)
        usage
        ;;
esac
