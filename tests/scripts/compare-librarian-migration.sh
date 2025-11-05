#!/bin/bash
# Compare Librarian Migration
# Compares Applications from current librarian vs ApplicationSet expansion
# TDD validation: ensures migration generates identical Applications

set -euo pipefail

# Colors
BLUE='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

# Directories
SNAPSHOT_DIR="${1:-output-test/librarian-snapshot}"
APPSET_DIR="${2:-output-test/librarian-appsets}"

echo -e "${BLUE}🔍 Comparing Librarian Migration${RESET}"
echo -e "  Snapshot (current): ${YELLOW}$SNAPSHOT_DIR${RESET}"
echo -e "  ApplicationSets: ${YELLOW}$APPSET_DIR${RESET}"
echo ""

# Verify directories exist
if [ ! -d "$SNAPSHOT_DIR" ]; then
    echo -e "${RED}❌ Snapshot directory not found: $SNAPSHOT_DIR${RESET}"
    echo -e "${YELLOW}ℹ️  Run: make snapshot-librarian first${RESET}"
    exit 1
fi

if [ ! -d "$APPSET_DIR" ]; then
    echo -e "${RED}❌ ApplicationSet directory not found: $APPSET_DIR${RESET}"
    echo -e "${YELLOW}ℹ️  Run: make test-librarian-appsets first${RESET}"
    exit 1
fi

# Count files
SNAPSHOT_COUNT=$(find "$SNAPSHOT_DIR" -name "*.yaml" ! -name "_*" | wc -l | tr -d ' ')
APPSET_COUNT=$(find "$APPSET_DIR" -name "*.yaml" ! -name "_*" | wc -l | tr -d ' ')

echo -e "${BLUE}📊 File counts:${RESET}"
echo -e "  Current Applications: ${YELLOW}$SNAPSHOT_COUNT${RESET}"
echo -e "  Generated Applications: ${YELLOW}$APPSET_COUNT${RESET}"
echo ""

# Check if counts match
if [ "$SNAPSHOT_COUNT" != "$APPSET_COUNT" ]; then
    echo -e "${RED}❌ Application counts don't match!${RESET}"
    echo ""

    echo -e "${YELLOW}Applications in snapshot but not in appsets:${RESET}"
    comm -23 <(ls -1 "$SNAPSHOT_DIR" | grep -v "^_" | sort) <(ls -1 "$APPSET_DIR" | grep -v "^_" | sort) | sed 's/^/  /'

    echo ""
    echo -e "${YELLOW}Applications in appsets but not in snapshot:${RESET}"
    comm -13 <(ls -1 "$SNAPSHOT_DIR" | grep -v "^_" | sort) <(ls -1 "$APPSET_DIR" | grep -v "^_" | sort) | sed 's/^/  /'

    echo ""
fi

# Compare each Application
echo -e "${BLUE}🔍 Comparing Applications...${RESET}"
echo ""

TOTAL_APPS=0
IDENTICAL_APPS=0
DIFFERENT_APPS=0
MISSING_APPS=0

for snapshot_file in "$SNAPSHOT_DIR"/*.yaml; do
    if [[ "$(basename "$snapshot_file")" == _* ]]; then
        continue
    fi

    TOTAL_APPS=$((TOTAL_APPS + 1))

    APP_NAME=$(basename "$snapshot_file" .yaml)
    APPSET_FILE="$APPSET_DIR/$APP_NAME.yaml"

    if [ ! -f "$APPSET_FILE" ]; then
        echo -e "  ${RED}✗${RESET} $APP_NAME ${RED}(missing in appsets)${RESET}"
        MISSING_APPS=$((MISSING_APPS + 1))
        continue
    fi

    # Compare files using yq to normalize YAML
    # Remove dynamic fields that might differ
    SNAPSHOT_NORMALIZED=$(yq eval 'del(.metadata.labels."helm.sh/chart") | del(.metadata.annotations) | del(.metadata.creationTimestamp)' "$snapshot_file" | sort)
    APPSET_NORMALIZED=$(yq eval 'del(.metadata.labels."helm.sh/chart") | del(.metadata.annotations) | del(.metadata.creationTimestamp)' "$APPSET_FILE" | sort)

    if diff -q <(echo "$SNAPSHOT_NORMALIZED") <(echo "$APPSET_NORMALIZED") > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${RESET} $APP_NAME"
        IDENTICAL_APPS=$((IDENTICAL_APPS + 1))
    else
        echo -e "  ${RED}✗${RESET} $APP_NAME ${YELLOW}(differences found)${RESET}"
        DIFFERENT_APPS=$((DIFFERENT_APPS + 1))

        # Show diff if verbose
        if [ "${VERBOSE:-0}" = "1" ]; then
            echo ""
            echo -e "${YELLOW}    Diff:${RESET}"
            diff -u <(echo "$SNAPSHOT_NORMALIZED") <(echo "$APPSET_NORMALIZED") | tail -n +3 | sed 's/^/      /' || true
            echo ""
        fi
    fi
done

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BLUE}📊 Summary${RESET}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "  Total Applications: ${YELLOW}$TOTAL_APPS${RESET}"
echo -e "  ${GREEN}✓ Identical: $IDENTICAL_APPS${RESET}"
echo -e "  ${RED}✗ Different: $DIFFERENT_APPS${RESET}"
echo -e "  ${RED}✗ Missing: $MISSING_APPS${RESET}"
echo ""

# Calculate success percentage
SUCCESS_RATE=0
if [ "$TOTAL_APPS" -gt 0 ]; then
    SUCCESS_RATE=$((IDENTICAL_APPS * 100 / TOTAL_APPS))
fi

echo -e "  Success rate: ${YELLOW}${SUCCESS_RATE}%${RESET}"
echo ""

# Show detailed diff command for failed apps
if [ "$DIFFERENT_APPS" -gt 0 ]; then
    echo -e "${YELLOW}💡 To see detailed differences:${RESET}"
    echo -e "  VERBOSE=1 $0 $SNAPSHOT_DIR $APPSET_DIR"
    echo ""
    echo -e "${YELLOW}💡 To compare specific app:${RESET}"
    echo -e "  diff $SNAPSHOT_DIR/<app-name>.yaml $APPSET_DIR/<app-name>.yaml"
    echo ""
fi

# Exit code based on results
if [ "$IDENTICAL_APPS" = "$TOTAL_APPS" ] && [ "$MISSING_APPS" = "0" ]; then
    echo -e "${GREEN}✅ TDD: All Applications match! Migration successful!${RESET}"
    exit 0
elif [ "$SUCCESS_RATE" -ge 80 ]; then
    echo -e "${YELLOW}⚠️  TDD: Most Applications match, but some differences remain${RESET}"
    exit 1
else
    echo -e "${RED}❌ TDD: Significant differences found. Keep working!${RESET}"
    exit 1
fi
