#!/bin/bash
# Test ApplicationSet Expansion
# Simulates ApplicationSet git files generator to expand Applications
# Used for TDD validation during librarian migration

set -euo pipefail

# Colors
BLUE='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

# Default options
BOOK="${1:-the-yaml-life}"
BOOKRACK_PATH="${2:-/home/namen/_home/the.yaml.life/proto-the-yaml-life/bookrack}"
OUTPUT_DIR="${3:-output-test/librarian-appsets}"

echo -e "${BLUE}🔮 Testing ApplicationSet Expansion${RESET}"
echo -e "  Book: ${YELLOW}$BOOK${RESET}"
echo -e "  Bookrack: ${YELLOW}$BOOKRACK_PATH${RESET}"
echo -e "  Output: ${YELLOW}$OUTPUT_DIR${RESET}"
echo ""

# Verify bookrack exists
if [ ! -d "$BOOKRACK_PATH/$BOOK" ]; then
    echo -e "${RED}❌ Book not found: $BOOKRACK_PATH/$BOOK${RESET}"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Step 1: Generate ApplicationSets via librarian
echo -e "${BLUE}🔨 Rendering librarian ApplicationSets...${RESET}"

LIBRARIAN_OUTPUT=$(helm template appset-librarian librarian \
    --set name="$BOOK" \
    --namespace argocd \
    2>&1)

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Librarian rendering failed${RESET}"
    echo "$LIBRARIAN_OUTPUT"
    exit 1
fi

# Step 2: Extract ApplicationSets
APPSET_COUNT=$(echo "$LIBRARIAN_OUTPUT" | yq eval 'select(.kind == "ApplicationSet")' - | grep -c "kind: ApplicationSet" || echo "0")

if [ "$APPSET_COUNT" = "0" ]; then
    echo -e "${RED}❌ No ApplicationSets found in librarian output${RESET}"
    echo -e "${YELLOW}ℹ️  Make sure librarian is generating ApplicationSets, not Applications${RESET}"
    exit 1
fi

echo -e "${GREEN}✅ Found $APPSET_COUNT ApplicationSet(s)${RESET}"
echo ""

# Step 3: Process each ApplicationSet
echo -e "${BLUE}📦 Expanding ApplicationSets...${RESET}"
echo ""

TOTAL_APPS=0

while IFS= read -r appset; do
    if [ -z "$appset" ] || [ "$appset" = "null" ]; then
        continue
    fi

    # Extract ApplicationSet metadata
    APPSET_NAME=$(echo "$appset" | yq eval '.metadata.name' -)

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${GREEN}ApplicationSet: $APPSET_NAME${RESET}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""

    # Extract git files generator config
    GIT_PATH=$(echo "$appset" | yq eval '.spec.generators[0].git.files[0].path' -)

    if [ "$GIT_PATH" = "null" ]; then
        echo -e "${YELLOW}  ⚠️  No git.files generator found${RESET}"
        echo ""
        continue
    fi

    echo -e "  Generator path: ${YELLOW}$GIT_PATH${RESET}"

    # Extract chapter name from path (assuming pattern: bookrack/<book>/<chapter>/*.yaml)
    CHAPTER=$(echo "$GIT_PATH" | sed -E "s|bookrack/$BOOK/([^/]+)/.*|\1|")

    echo -e "  Chapter: ${YELLOW}$CHAPTER${RESET}"

    # Find matching spell files
    SPELL_FILES=$(find "$BOOKRACK_PATH/$BOOK/$CHAPTER" -name "*.yaml" -type f ! -name "index.yaml" 2>/dev/null || true)

    if [ -z "$SPELL_FILES" ]; then
        echo -e "${YELLOW}  ⚠️  No spell files found in chapter${RESET}"
        echo ""
        continue
    fi

    SPELL_COUNT=$(echo "$SPELL_FILES" | wc -l | tr -d ' ')
    echo -e "  Spells found: ${YELLOW}$SPELL_COUNT${RESET}"
    echo ""

    # Step 4: Expand ApplicationSet template for each spell file
    while IFS= read -r spell_file; do
        if [ -z "$spell_file" ]; then
            continue
        fi

        SPELL_NAME=$(basename "$spell_file" .yaml)

        echo -e "  ${BLUE}├─${RESET} Expanding: ${YELLOW}$SPELL_NAME${RESET}"

        # Read spell file content
        SPELL_CONTENT=$(cat "$spell_file")

        # Create temporary values file with spell content
        # This simulates what ApplicationSet git files generator does
        TEMP_SPELL_VALUES=$(mktemp)
        echo "$SPELL_CONTENT" > "$TEMP_SPELL_VALUES"

        # Extract ApplicationSet template
        APPSET_TEMPLATE=$(echo "$appset" | yq eval '.spec.template' -)

        # Replace Go template variables with actual values from spell file
        # This is a simplified simulation of ApplicationSet's template expansion

        # Get spell name from file
        SPELL_NAME_FROM_FILE=$(yq eval '.name' "$TEMP_SPELL_VALUES" 2>/dev/null || echo "$SPELL_NAME")

        # Replace {{.name}} with actual name
        APPLICATION=$(echo "$APPSET_TEMPLATE" | sed "s/{{\.name}}/$SPELL_NAME_FROM_FILE/g")

        # Add apiVersion and kind
        APPLICATION="apiVersion: argoproj.io/v1alpha1
kind: Application
$APPLICATION"

        # Save expanded Application
        OUTPUT_FILE="$OUTPUT_DIR/$SPELL_NAME_FROM_FILE.yaml"
        echo "$APPLICATION" > "$OUTPUT_FILE"

        TOTAL_APPS=$((TOTAL_APPS + 1))

        rm -f "$TEMP_SPELL_VALUES"

    done <<< "$SPELL_FILES"

    echo ""

done < <(echo "$LIBRARIAN_OUTPUT" | yq eval -o=json '.' - | jq -c 'select(.kind == "ApplicationSet")')

echo -e "${GREEN}✅ Expansion complete!${RESET}"
echo -e "  ApplicationSets: ${YELLOW}$APPSET_COUNT${RESET}"
echo -e "  Applications generated: ${YELLOW}$TOTAL_APPS${RESET}"
echo -e "  Location: ${YELLOW}$OUTPUT_DIR${RESET}"
echo ""
echo -e "${BLUE}📝 Generated Applications:${RESET}"
ls -1 "$OUTPUT_DIR" | sed 's/^/  /'
