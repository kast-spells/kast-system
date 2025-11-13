#!/bin/bash
# Spell Testing Script - Renders actual K8s resources
# Tests individual spell by rendering all sources with real Helm output

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

BOOK="${1:-}"
SPELL="${2:-}"
DEBUG="${3:-}"

usage() {
    echo "Usage: $0 <book> <spell> [--debug]"
    echo ""
    echo "Renders actual Kubernetes resources for a spell"
    echo ""
    echo "Examples:"
    echo "  $0 example-tdd-book example-api"
    echo "  $0 the-example-book argocd --debug"
    echo ""
    exit 1
}

if [ -z "$BOOK" ] || [ -z "$SPELL" ]; then
    usage
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BLUE}📜 Testing Spell with Real Resources${RESET}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "  Book:  ${YELLOW}$BOOK${RESET}"
echo -e "  Spell: ${YELLOW}$SPELL${RESET}"
echo ""

# Check for yq
if ! command -v yq &> /dev/null; then
    echo -e "${RED}❌ Error: yq is required but not installed${RESET}"
    echo -e "${YELLOW}Install with: brew install yq (or equivalent)${RESET}"
    exit 1
fi

# Step 1: Render librarian to get the Application
echo -e "${BLUE}[1/4] Generating ArgoCD Application via librarian...${RESET}"

LIBRARIAN_OUTPUT=$(helm template test-librarian librarian \
    --set name="$BOOK" \
    --namespace argocd \
    2>&1)

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Librarian rendering failed${RESET}"
    echo "$LIBRARIAN_OUTPUT"
    exit 1
fi

echo -e "${GREEN}  ✅ Librarian rendered${RESET}"
echo ""

# Step 2: Extract the specific spell's Application
echo -e "${BLUE}[2/4] Extracting Application for spell: $SPELL...${RESET}"

APPLICATION=$(echo "$LIBRARIAN_OUTPUT" | yq eval "select(.kind == \"Application\" and .metadata.name == \"$SPELL\")" - 2>/dev/null)

if [ -z "$APPLICATION" ] || [ "$APPLICATION" = "null" ]; then
    echo -e "${RED}❌ No Application found for spell: $SPELL${RESET}"
    echo ""
    echo -e "${YELLOW}Available spells in book '$BOOK':${RESET}"
    echo "$LIBRARIAN_OUTPUT" | yq eval 'select(.kind == "Application") | .metadata.name' - | sed 's/^/  - /'
    exit 1
fi

echo -e "${GREEN}  ✅ Application extracted${RESET}"
echo ""

# Step 3: Parse sources
echo -e "${BLUE}[3/4] Parsing Application sources...${RESET}"

SOURCES_COUNT=$(echo "$APPLICATION" | yq eval '.spec.sources | length' - 2>/dev/null)

if [ "$SOURCES_COUNT" == "null" ] || [ "$SOURCES_COUNT" -eq 0 ]; then
    echo -e "${RED}❌ No sources found in Application${RESET}"
    exit 1
fi

echo -e "${GREEN}  ✅ Found $SOURCES_COUNT source(s)${RESET}"
echo ""

# Step 4: Render each source
echo -e "${BLUE}[4/4] Rendering Kubernetes resources from sources...${RESET}"
echo ""

TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

for i in $(seq 0 $((SOURCES_COUNT - 1))); do
    SOURCE_INDEX=$i

    # Extract source details
    CHART_PATH=$(echo "$APPLICATION" | yq eval ".spec.sources[$SOURCE_INDEX].path" - 2>/dev/null)
    REPO_URL=$(echo "$APPLICATION" | yq eval ".spec.sources[$SOURCE_INDEX].repoURL" - 2>/dev/null)

    # Skip if not a local chart
    if [[ "$CHART_PATH" != ./* ]]; then
        echo -e "${YELLOW}  ⚠️  Source $((i+1)): Skipping non-local chart ($REPO_URL)${RESET}"
        continue
    fi

    # Clean chart path (remove leading ./)
    CHART_PATH="${CHART_PATH#./}"
    CHART_NAME=$(basename "$CHART_PATH")

    echo -e "${BLUE}  📦 Source $((i+1))/${SOURCES_COUNT}: $CHART_NAME${RESET}"
    echo -e "${BLUE}     Path: $CHART_PATH${RESET}"

    # Check if chart exists
    if [ ! -f "$CHART_PATH/Chart.yaml" ]; then
        echo -e "${RED}     ❌ Chart not found: $CHART_PATH${RESET}"
        continue
    fi

    # Extract helm values (can be in .helm.values or .helm.valuesObject)
    VALUES_FILE="$TEMP_DIR/values-source-$i.yaml"

    # Try valuesObject first (YAML object)
    VALUES_OBJECT=$(echo "$APPLICATION" | yq eval ".spec.sources[$SOURCE_INDEX].helm.valuesObject" - 2>/dev/null)
    if [ "$VALUES_OBJECT" != "null" ] && [ -n "$VALUES_OBJECT" ]; then
        echo "$VALUES_OBJECT" > "$VALUES_FILE"
    else
        # Try values (string)
        VALUES_STRING=$(echo "$APPLICATION" | yq eval ".spec.sources[$SOURCE_INDEX].helm.values" - 2>/dev/null)
        if [ "$VALUES_STRING" != "null" ] && [ -n "$VALUES_STRING" ]; then
            echo "$VALUES_STRING" > "$VALUES_FILE"
        else
            # No values, create empty file
            echo "{}" > "$VALUES_FILE"
        fi
    fi

    # Render the chart
    RELEASE_NAME="test-$SPELL-$CHART_NAME"
    NAMESPACE=$(echo "$APPLICATION" | yq eval '.spec.destination.namespace' - 2>/dev/null)
    NAMESPACE="${NAMESPACE:-default}"

    echo -e "${BLUE}     🔨 Rendering chart...${RESET}"

    if [ "$DEBUG" == "--debug" ]; then
        OUTPUT=$(helm template "$RELEASE_NAME" "$CHART_PATH" \
            -f "$VALUES_FILE" \
            --namespace "$NAMESPACE" \
            --debug \
            2>&1)
    else
        OUTPUT=$(helm template "$RELEASE_NAME" "$CHART_PATH" \
            -f "$VALUES_FILE" \
            --namespace "$NAMESPACE" \
            2>&1)
    fi

    if [ $? -ne 0 ]; then
        echo -e "${RED}     ❌ Rendering failed${RESET}"
        echo "$OUTPUT" | head -20
        continue
    fi

    # Count resources
    RESOURCE_COUNT=$(echo "$OUTPUT" | grep -c "^kind:" || echo "0")

    echo -e "${GREEN}     ✅ Generated $RESOURCE_COUNT resource(s)${RESET}"
    echo ""

    # Show resource summary
    echo -e "${BLUE}     📋 Resource Summary:${RESET}"
    echo "$OUTPUT" | grep "^kind:" | sort | uniq -c | while read count kind; do
        echo -e "${GREEN}        - ${count}x ${kind}${RESET}"
    done
    echo ""

    # Show full output if debug
    if [ "$DEBUG" == "--debug" ]; then
        echo -e "${BLUE}     📄 Full Output:${RESET}"
        echo -e "${BLUE}     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo "$OUTPUT"
        echo -e "${BLUE}     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo ""
    fi

    # Save output to file
    OUTPUT_FILE="output-test/spell-${SPELL}-source-$((i+1))-${CHART_NAME}.yaml"
    mkdir -p "$(dirname "$OUTPUT_FILE")"
    echo "$OUTPUT" > "$OUTPUT_FILE"
    echo -e "${GREEN}     💾 Saved to: $OUTPUT_FILE${RESET}"
    echo ""
done

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${GREEN}✅ Spell test completed successfully!${RESET}"
echo ""
echo -e "${BLUE}💡 Tips:${RESET}"
echo -e "  - Add --debug to see full resource output"
echo -e "  - Check output-test/spell-${SPELL}-* for saved resources"
echo -e "  - Use: make test-spell BOOK=$BOOK SPELL=$SPELL"
