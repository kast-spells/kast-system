#!/bin/bash
# Testing Status Report
# Shows testing coverage for all charts, glyphs, and trinkets

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

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BLUE}📊 Testing Status Report${RESET}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

# Main Charts
echo -e "${BLUE}📦 Main Charts:${RESET}"
find . -name "Chart.yaml" -not -path "./charts/glyphs/*" -not -path "./charts/trinkets/*" | while read chart_file; do
    chart_dir=$(dirname "$chart_file")
    chart_name=$(basename "$chart_dir")

    if [ -d "$chart_dir/examples" ]; then
        example_count=$(find "$chart_dir/examples" -name "*.yaml" -type f 2>/dev/null | wc -l)
        snapshot_count=$(find "output-test/$chart_name" -name "*.expected.yaml" -type f 2>/dev/null | wc -l)

        if [ "$snapshot_count" -gt 0 ]; then
            echo -e "  ${GREEN}✅ $chart_name: $example_count examples ($snapshot_count snapshots)${RESET}"
        else
            echo -e "  ${YELLOW}⚠️  $chart_name: $example_count examples (no snapshots)${RESET}"
        fi
    else
        echo -e "  ${RED}❌ $chart_name: NO examples/${RESET}"
    fi
done

echo ""

# Glyphs
echo -e "${BLUE}🎭 Glyphs:${RESET}"
for glyph_dir in charts/glyphs/*/; do
    glyph_name=$(basename "$glyph_dir")

    if [ -d "$glyph_dir/examples" ]; then
        example_count=$(find "$glyph_dir/examples" -name "*.yaml" -type f 2>/dev/null | wc -l)
        snapshot_count=$(find "output-test/$glyph_name" -name "*.expected.yaml" -type f 2>/dev/null | wc -l)

        if [ "$snapshot_count" -gt 0 ]; then
            echo -e "  ${GREEN}✅ $glyph_name: $example_count examples ($snapshot_count snapshots)${RESET}"
        else
            echo -e "  ${YELLOW}⚠️  $glyph_name: $example_count examples (no snapshots)${RESET}"
        fi
    else
        echo -e "  ${RED}❌ $glyph_name: NO examples/${RESET}"
    fi
done

echo ""

# Trinkets
echo -e "${BLUE}🔮 Trinkets:${RESET}"
for trinket_dir in charts/trinkets/*/; do
    trinket_name=$(basename "$trinket_dir")

    if [ -d "$trinket_dir/examples" ]; then
        example_count=$(find "$trinket_dir/examples" -name "*.yaml" -type f 2>/dev/null | wc -l)
        snapshot_count=$(find "output-test/$trinket_name" -name "*.expected.yaml" -type f 2>/dev/null | wc -l)

        if [ "$snapshot_count" -gt 0 ]; then
            echo -e "  ${GREEN}✅ $trinket_name: $example_count examples ($snapshot_count snapshots)${RESET}"
        else
            echo -e "  ${YELLOW}⚠️  $trinket_name: $example_count examples (no snapshots)${RESET}"
        fi
    else
        echo -e "  ${RED}❌ $trinket_name: NO examples/${RESET}"
    fi
done

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "${BLUE}Legend:${RESET}"
echo -e "  ${GREEN}✅${RESET} = Examples + Snapshots complete"
echo -e "  ${YELLOW}⚠️${RESET}  = Examples exist, snapshots needed"
echo -e "  ${RED}❌${RESET} = No examples (needs TDD work)"
