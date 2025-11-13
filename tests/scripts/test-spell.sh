#!/bin/bash
# Simple Spell Testing Script
# Renders a single spell with its full librarian context

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

usage() {
    echo "Usage: $0 <book> <spell>"
    echo ""
    echo "Simple test for individual spells with full context"
    echo ""
    echo "Examples:"
    echo "  $0 the-example-book argocd"
    echo "  $0 example-tdd-book example-api"
    echo ""
    exit 1
}

if [ -z "$BOOK" ] || [ -z "$SPELL" ]; then
    usage
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BLUE}📜 Testing Spell${RESET}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "  Book:  ${YELLOW}$BOOK${RESET}"
echo -e "  Spell: ${YELLOW}$SPELL${RESET}"
echo ""

# Step 1: Render librarian to get the Application
echo -e "${BLUE}[1/3] Generating ArgoCD Application via librarian...${RESET}"

LIBRARIAN_OUTPUT=$(helm template test-librarian librarian \
    --set name="$BOOK" \
    --namespace argocd \
    2>&1)

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Librarian rendering failed${RESET}"
    echo "$LIBRARIAN_OUTPUT"
    exit 1
fi

echo -e "${GREEN}  ✅ Librarian rendered successfully${RESET}"
echo ""

# Step 2: Extract the specific spell's Application
echo -e "${BLUE}[2/3] Extracting Application for spell: $SPELL...${RESET}"

# Try to extract using yq if available, otherwise use grep/sed
if command -v yq &> /dev/null; then
    APPLICATION=$(echo "$LIBRARIAN_OUTPUT" | yq eval "select(.kind == \"Application\" and .metadata.name == \"$SPELL\")" - 2>/dev/null)
else
    # Fallback: simple extraction (less robust)
    APPLICATION=$(echo "$LIBRARIAN_OUTPUT" | awk "/kind: Application/,/^---$/" | awk "/name: $SPELL/,/^---$/")
fi

if [ -z "$APPLICATION" ] || [ "$APPLICATION" = "null" ]; then
    echo -e "${RED}❌ No Application found for spell: $SPELL${RESET}"
    echo ""
    echo -e "${YELLOW}Available spells in this book:${RESET}"
    if command -v yq &> /dev/null; then
        echo "$LIBRARIAN_OUTPUT" | yq eval 'select(.kind == "Application") | .metadata.name' - | sed 's/^/  - /'
    else
        echo "$LIBRARIAN_OUTPUT" | grep -A1 "kind: Application" | grep "name:" | awk '{print "  - " $2}'
    fi
    exit 1
fi

echo -e "${GREEN}  ✅ Application extracted${RESET}"
echo ""

# Step 3: Show Application summary
echo -e "${BLUE}[3/3] Application Summary:${RESET}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo "$APPLICATION"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

# Extract sources count
if command -v yq &> /dev/null; then
    SOURCES_COUNT=$(echo "$APPLICATION" | yq eval '.spec.sources | length' - 2>/dev/null)
    if [ "$SOURCES_COUNT" != "null" ] && [ "$SOURCES_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✅ Multi-source Application with $SOURCES_COUNT sources${RESET}"
    else
        echo -e "${YELLOW}⚠️  Single-source Application${RESET}"
    fi
else
    SOURCES_COUNT=$(echo "$APPLICATION" | grep -c "repoURL:" || echo "1")
    echo -e "${GREEN}✅ Application has $SOURCES_COUNT source(s)${RESET}"
fi

echo ""
echo -e "${GREEN}✅ Spell test completed successfully!${RESET}"
echo ""
echo -e "${BLUE}💡 Tips:${RESET}"
echo -e "  - To render the actual resources, extract the Application sources and run helm template"
echo -e "  - To debug: helm template test-librarian librarian --set name=$BOOK --namespace argocd --debug"
