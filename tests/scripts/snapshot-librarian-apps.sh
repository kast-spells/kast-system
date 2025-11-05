#!/bin/bash
# Snapshot Librarian Applications
# Generates snapshot of all Applications that librarian currently produces
# This is the BASELINE for TDD migration to ApplicationSets

set -euo pipefail

# Colors
BLUE='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

# Default book
BOOK="${1:-the-yaml-life}"
OUTPUT_DIR="${2:-output-test/librarian-snapshot}"

echo -e "${BLUE}📸 Generating Librarian Applications Snapshot${RESET}"
echo -e "  Book: ${YELLOW}$BOOK${RESET}"
echo -e "  Output: ${YELLOW}$OUTPUT_DIR${RESET}"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Step 1: Generate all Applications via librarian
echo -e "${BLUE}🔨 Rendering librarian...${RESET}"

LIBRARIAN_OUTPUT=$(helm template snapshot-librarian librarian \
    --set name="$BOOK" \
    --namespace argocd \
    2>&1 | grep -v "walk.go:" | grep -v "found symbolic link")

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Librarian rendering failed${RESET}"
    echo "$LIBRARIAN_OUTPUT"
    exit 1
fi

# Remove empty lines and ensure proper YAML structure
LIBRARIAN_OUTPUT=$(echo "$LIBRARIAN_OUTPUT" | grep -v "^$" | grep -v "^#se puede")

# Step 2: Extract Applications and save individually
echo -e "${BLUE}📦 Extracting Applications...${RESET}"

# Save to temp file first
TEMP_OUTPUT=$(mktemp)
echo "$LIBRARIAN_OUTPUT" > "$TEMP_OUTPUT"

APP_COUNT=0

# Extract each Application document
yq eval 'select(.kind == "Application")' "$TEMP_OUTPUT" | yq eval -o=json '.' - | jq -c '.' | while IFS= read -r app; do
    if [ -z "$app" ] || [ "$app" = "null" ]; then
        continue
    fi

    # Extract application name
    APP_NAME=$(echo "$app" | jq -r '.metadata.name')

    if [ "$APP_NAME" = "null" ] || [ -z "$APP_NAME" ]; then
        continue
    fi

    # Save to file (convert back to YAML)
    OUTPUT_FILE="$OUTPUT_DIR/$APP_NAME.yaml"
    echo "$app" | yq eval -P '.' - > "$OUTPUT_FILE"

    APP_COUNT=$((APP_COUNT + 1))
    echo -e "  ${GREEN}✓${RESET} $APP_NAME"
done

rm -f "$TEMP_OUTPUT"

# Step 3: Also save AppProject if present
PROJECT_OUTPUT=$(echo "$LIBRARIAN_OUTPUT" | yq eval 'select(.kind == "AppProject")' -)
if [ -n "$PROJECT_OUTPUT" ] && [ "$PROJECT_OUTPUT" != "null" ]; then
    echo "$PROJECT_OUTPUT" > "$OUTPUT_DIR/_project.yaml"
    echo -e "  ${GREEN}✓${RESET} AppProject"
fi

echo ""
echo -e "${GREEN}✅ Snapshot complete!${RESET}"
echo -e "  Applications: ${YELLOW}$APP_COUNT${RESET}"
echo -e "  Location: ${YELLOW}$OUTPUT_DIR${RESET}"
echo ""
echo -e "${BLUE}📝 Files:${RESET}"
ls -1 "$OUTPUT_DIR" | sed 's/^/  /'
