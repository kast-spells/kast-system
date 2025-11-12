#!/bin/bash
# Consolidated Librarian Migration Testing
# TDD validation for librarian migration to ApplicationSets
#
# Modes:
#   baseline - Generate snapshot of current librarian Applications
#   test     - Test ApplicationSet expansion
#   compare  - Compare baseline vs ApplicationSet outputs
#   render   - Render spell from cluster Application

set -euo pipefail

# Colors
BLUE='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

MODE="${1:-}"
shift || true

usage() {
    echo "Usage: $0 <mode> [options]"
    echo ""
    echo "Modes:"
    echo "  baseline [book] [output_dir]"
    echo "    Generate snapshot of current librarian Applications"
    echo "    Default book: the-yaml-life"
    echo "    Default output: output-test/librarian-snapshot"
    echo ""
    echo "  test [book] [bookrack_path] [output_dir]"
    echo "    Test ApplicationSet expansion (simulate git files generator)"
    echo "    Default book: the-yaml-life"
    echo "    Default bookrack: /home/namen/_home/the.yaml.life/proto-the-yaml-life/bookrack"
    echo "    Default output: output-test/librarian-appsets"
    echo ""
    echo "  compare [snapshot_dir] [appset_dir]"
    echo "    Compare baseline vs ApplicationSet outputs"
    echo "    Default snapshot: output-test/librarian-snapshot"
    echo "    Default appset: output-test/librarian-appsets"
    echo "    Use VERBOSE=1 for detailed diffs"
    echo ""
    echo "  render <spell-name>"
    echo "    Render spell using values from cluster Application"
    echo ""
    echo "Examples:"
    echo "  $0 baseline"
    echo "  $0 test the-yaml-life"
    echo "  $0 compare"
    echo "  $0 render stalwart"
    exit 1
}

# ═══════════════════════════════════════════════════════════════════════════
# MODE: baseline - Generate snapshot of current librarian Applications
# ═══════════════════════════════════════════════════════════════════════════
mode_baseline() {
    local BOOK="${1:-the-yaml-life}"
    local OUTPUT_DIR="${2:-output-test/librarian-snapshot}"

    echo -e "${BLUE}📸 Generating Librarian Applications Snapshot${RESET}"
    echo -e "  Book: ${YELLOW}$BOOK${RESET}"
    echo -e "  Output: ${YELLOW}$OUTPUT_DIR${RESET}"
    echo ""

    # Create output directory
    mkdir -p "$OUTPUT_DIR"

    # Step 1: Generate all Applications via librarian
    echo -e "${BLUE}🔨 Rendering librarian...${RESET}"

    local LIBRARIAN_OUTPUT
    LIBRARIAN_OUTPUT=$(helm template snapshot-librarian librarian \
        --set name="$BOOK" \
        --namespace argocd \
        2>&1 | grep -v "walk.go:" | grep -v "found symbolic link")

    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Librarian rendering failed${RESET}"
        echo "$LIBRARIAN_OUTPUT"
        exit 1
    fi

    # Remove empty lines and comments
    LIBRARIAN_OUTPUT=$(echo "$LIBRARIAN_OUTPUT" | grep -v "^$" | grep -v "^#se puede")

    # Step 2: Extract Applications and save individually
    echo -e "${BLUE}📦 Extracting Applications...${RESET}"

    # Save to temp file first
    local TEMP_OUTPUT=$(mktemp)
    echo "$LIBRARIAN_OUTPUT" > "$TEMP_OUTPUT"

    local APP_COUNT=0

    # Extract each Application document
    yq eval 'select(.kind == "Application")' "$TEMP_OUTPUT" | yq eval -o=json '.' - | jq -c '.' | while IFS= read -r app; do
        if [ -z "$app" ] || [ "$app" = "null" ]; then
            continue
        fi

        # Extract application name
        local APP_NAME=$(echo "$app" | jq -r '.metadata.name')

        if [ "$APP_NAME" = "null" ] || [ -z "$APP_NAME" ]; then
            continue
        fi

        # Save to file (convert back to YAML)
        local OUTPUT_FILE="$OUTPUT_DIR/$APP_NAME.yaml"
        echo "$app" | yq eval -P '.' - > "$OUTPUT_FILE"

        APP_COUNT=$((APP_COUNT + 1))
        echo -e "  ${GREEN}✓${RESET} $APP_NAME"
    done

    rm -f "$TEMP_OUTPUT"

    # Step 3: Also save AppProject if present
    local PROJECT_OUTPUT=$(echo "$LIBRARIAN_OUTPUT" | yq eval 'select(.kind == "AppProject")' -)
    if [ -n "$PROJECT_OUTPUT" ] && [ "$PROJECT_OUTPUT" != "null" ]; then
        echo "$PROJECT_OUTPUT" > "$OUTPUT_DIR/_project.yaml"
        echo -e "  ${GREEN}✓${RESET} AppProject"
    fi

    echo ""
    echo -e "${GREEN}✅ Snapshot complete!${RESET}"
    echo -e "  Location: ${YELLOW}$OUTPUT_DIR${RESET}"
    echo ""
    echo -e "${BLUE}📝 Files:${RESET}"
    ls -1 "$OUTPUT_DIR" | sed 's/^/  /'
}

# ═══════════════════════════════════════════════════════════════════════════
# MODE: test - Test ApplicationSet expansion
# ═══════════════════════════════════════════════════════════════════════════
mode_test() {
    local BOOK="${1:-the-yaml-life}"
    local BOOKRACK_PATH="${2:-/home/namen/_home/the.yaml.life/proto-the-yaml-life/bookrack}"
    local OUTPUT_DIR="${3:-output-test/librarian-appsets}"

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

    local LIBRARIAN_OUTPUT
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
    local APPSET_COUNT=$(echo "$LIBRARIAN_OUTPUT" | yq eval 'select(.kind == "ApplicationSet")' - | grep -c "kind: ApplicationSet" || echo "0")

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

    local TOTAL_APPS=0

    while IFS= read -r appset; do
        if [ -z "$appset" ] || [ "$appset" = "null" ]; then
            continue
        fi

        # Extract ApplicationSet metadata
        local APPSET_NAME=$(echo "$appset" | yq eval '.metadata.name' -)

        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -e "${GREEN}ApplicationSet: $APPSET_NAME${RESET}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo ""

        # Extract git files generator config
        local GIT_PATH=$(echo "$appset" | yq eval '.spec.generators[0].git.files[0].path' -)

        if [ "$GIT_PATH" = "null" ]; then
            echo -e "${YELLOW}  ⚠️  No git.files generator found${RESET}"
            echo ""
            continue
        fi

        echo -e "  Generator path: ${YELLOW}$GIT_PATH${RESET}"

        # Extract chapter name from path
        local CHAPTER=$(echo "$GIT_PATH" | sed -E "s|bookrack/$BOOK/([^/]+)/.*|\1|")

        echo -e "  Chapter: ${YELLOW}$CHAPTER${RESET}"

        # Find matching spell files
        local SPELL_FILES=$(find "$BOOKRACK_PATH/$BOOK/$CHAPTER" -name "*.yaml" -type f ! -name "index.yaml" 2>/dev/null || true)

        if [ -z "$SPELL_FILES" ]; then
            echo -e "${YELLOW}  ⚠️  No spell files found in chapter${RESET}"
            echo ""
            continue
        fi

        local SPELL_COUNT=$(echo "$SPELL_FILES" | wc -l | tr -d ' ')
        echo -e "  Spells found: ${YELLOW}$SPELL_COUNT${RESET}"
        echo ""

        # Step 4: Expand ApplicationSet template for each spell file
        while IFS= read -r spell_file; do
            if [ -z "$spell_file" ]; then
                continue
            fi

            local SPELL_NAME=$(basename "$spell_file" .yaml)

            echo -e "  ${BLUE}├─${RESET} Expanding: ${YELLOW}$SPELL_NAME${RESET}"

            # Read spell file content
            local SPELL_CONTENT=$(cat "$spell_file")

            # Create temporary values file
            local TEMP_SPELL_VALUES=$(mktemp)
            echo "$SPELL_CONTENT" > "$TEMP_SPELL_VALUES"

            # Extract ApplicationSet template
            local APPSET_TEMPLATE=$(echo "$appset" | yq eval '.spec.template' -)

            # Get spell name from file
            local SPELL_NAME_FROM_FILE=$(yq eval '.name' "$TEMP_SPELL_VALUES" 2>/dev/null || echo "$SPELL_NAME")

            # Replace {{.name}} with actual name
            local APPLICATION=$(echo "$APPSET_TEMPLATE" | sed "s/{{\.name}}/$SPELL_NAME_FROM_FILE/g")

            # Add apiVersion and kind
            APPLICATION="apiVersion: argoproj.io/v1alpha1
kind: Application
$APPLICATION"

            # Save expanded Application
            local OUTPUT_FILE="$OUTPUT_DIR/$SPELL_NAME_FROM_FILE.yaml"
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
}

# ═══════════════════════════════════════════════════════════════════════════
# MODE: compare - Compare baseline vs ApplicationSet outputs
# ═══════════════════════════════════════════════════════════════════════════
mode_compare() {
    local SNAPSHOT_DIR="${1:-output-test/librarian-snapshot}"
    local APPSET_DIR="${2:-output-test/librarian-appsets}"

    echo -e "${BLUE}🔍 Comparing Librarian Migration${RESET}"
    echo -e "  Snapshot (current): ${YELLOW}$SNAPSHOT_DIR${RESET}"
    echo -e "  ApplicationSets: ${YELLOW}$APPSET_DIR${RESET}"
    echo ""

    # Verify directories exist
    if [ ! -d "$SNAPSHOT_DIR" ]; then
        echo -e "${RED}❌ Snapshot directory not found: $SNAPSHOT_DIR${RESET}"
        echo -e "${YELLOW}ℹ️  Run: $0 baseline first${RESET}"
        exit 1
    fi

    if [ ! -d "$APPSET_DIR" ]; then
        echo -e "${RED}❌ ApplicationSet directory not found: $APPSET_DIR${RESET}"
        echo -e "${YELLOW}ℹ️  Run: $0 test first${RESET}"
        exit 1
    fi

    # Count files
    local SNAPSHOT_COUNT=$(find "$SNAPSHOT_DIR" -name "*.yaml" ! -name "_*" | wc -l | tr -d ' ')
    local APPSET_COUNT=$(find "$APPSET_DIR" -name "*.yaml" ! -name "_*" | wc -l | tr -d ' ')

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

    local TOTAL_APPS=0
    local IDENTICAL_APPS=0
    local DIFFERENT_APPS=0
    local MISSING_APPS=0

    for snapshot_file in "$SNAPSHOT_DIR"/*.yaml; do
        if [[ "$(basename "$snapshot_file")" == _* ]]; then
            continue
        fi

        TOTAL_APPS=$((TOTAL_APPS + 1))

        local APP_NAME=$(basename "$snapshot_file" .yaml)
        local APPSET_FILE="$APPSET_DIR/$APP_NAME.yaml"

        if [ ! -f "$APPSET_FILE" ]; then
            echo -e "  ${RED}✗${RESET} $APP_NAME ${RED}(missing in appsets)${RESET}"
            MISSING_APPS=$((MISSING_APPS + 1))
            continue
        fi

        # Compare files using yq to normalize YAML
        local SNAPSHOT_NORMALIZED=$(yq eval 'del(.metadata.labels."helm.sh/chart") | del(.metadata.annotations) | del(.metadata.creationTimestamp)' "$snapshot_file" | sort)
        local APPSET_NORMALIZED=$(yq eval 'del(.metadata.labels."helm.sh/chart") | del(.metadata.annotations) | del(.metadata.creationTimestamp)' "$APPSET_FILE" | sort)

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
    local SUCCESS_RATE=0
    if [ "$TOTAL_APPS" -gt 0 ]; then
        SUCCESS_RATE=$((IDENTICAL_APPS * 100 / TOTAL_APPS))
    fi

    echo -e "  Success rate: ${YELLOW}${SUCCESS_RATE}%${RESET}"
    echo ""

    # Show detailed diff command for failed apps
    if [ "$DIFFERENT_APPS" -gt 0 ]; then
        echo -e "${YELLOW}💡 To see detailed differences:${RESET}"
        echo -e "  VERBOSE=1 $0 compare $SNAPSHOT_DIR $APPSET_DIR"
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
}

# ═══════════════════════════════════════════════════════════════════════════
# MODE: render - Render spell from cluster Application
# ═══════════════════════════════════════════════════════════════════════════
mode_render() {
    local SPELL_NAME="${1:-}"

    if [ -z "$SPELL_NAME" ]; then
        echo "Usage: $0 render <spell-name>"
        echo "Example: $0 render stalwart"
        exit 1
    fi

    echo -e "${BLUE}🔍 Searching for Application: ${SPELL_NAME}${RESET}"

    # Check if Application exists
    if ! kubectl get application "$SPELL_NAME" -n argocd &>/dev/null; then
        echo -e "${RED}❌ Application '$SPELL_NAME' not found in argocd namespace${RESET}"
        exit 1
    fi

    echo -e "${GREEN}✅ Found Application: ${SPELL_NAME}${RESET}"

    # Extract Application spec
    local APP_SPEC=$(kubectl get application "$SPELL_NAME" -n argocd -o json)

    # Get repository URL from first source
    local REPO_URL=$(echo "$APP_SPEC" | jq -r '.spec.sources[0].repoURL // .spec.source.repoURL')
    local TARGET_REVISION=$(echo "$APP_SPEC" | jq -r '.spec.sources[0].targetRevision // .spec.source.targetRevision')
    local CHART_PATH=$(echo "$APP_SPEC" | jq -r '.spec.sources[0].path // .spec.source.path')

    echo -e "${BLUE}📦 Repository: ${REPO_URL}${RESET}"
    echo -e "${BLUE}🔖 Revision: ${TARGET_REVISION}${RESET}"
    echo -e "${BLUE}📁 Path: ${CHART_PATH}${RESET}"

    # Check if it's a local repository (kast-system)
    if [[ ! "$REPO_URL" =~ github.com/kast-spells/kast-system ]]; then
        echo -e "${YELLOW}⚠️  This is not a local kast-system repository${RESET}"
        echo -e "${YELLOW}   Repository: ${REPO_URL}${RESET}"
        echo -e "${YELLOW}   This script only works with local kast-system repos${RESET}"
        exit 1
    fi

    echo -e "${GREEN}✅ Local kast-system repository detected${RESET}"

    # Extract values from first source
    local VALUES=$(echo "$APP_SPEC" | jq -r '.spec.sources[0].helm.values // .spec.source.helm.values')

    # Determine chart to use
    local CHART
    if echo "$VALUES" | grep -q "^glyphs:"; then
        CHART="kaster"
        echo -e "${BLUE}🎭 Detected glyphs in values, using kaster chart${RESET}"
    elif [[ "$CHART_PATH" == *"kaster"* ]]; then
        CHART="kaster"
    else
        CHART="summon"
    fi

    if [ -z "$VALUES" ] || [ "$VALUES" == "null" ]; then
        echo -e "${RED}❌ No helm values found in Application${RESET}"
        exit 1
    fi

    # Create temporary values file
    local TEMP_VALUES=$(mktemp /tmp/spell-values-XXXXXX.yaml)
    echo "$VALUES" > "$TEMP_VALUES"

    echo -e "${BLUE}💾 Values saved to: ${TEMP_VALUES}${RESET}"

    # Show values summary
    echo -e "${BLUE}📊 Values summary:${RESET}"
    echo "$VALUES" | head -30
    if [ $(echo "$VALUES" | wc -l) -gt 30 ]; then
        echo -e "${YELLOW}... (truncated, full values in ${TEMP_VALUES})${RESET}"
    fi

    # Render with helm template
    echo -e "${BLUE}🎨 Rendering spell with helm template...${RESET}"

    local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
    local CHART_DIR="${REPO_ROOT}/charts/${CHART}"

    if [ ! -d "$CHART_DIR" ]; then
        echo -e "${RED}❌ Chart directory not found: ${CHART_DIR}${RESET}"
        rm -f "$TEMP_VALUES"
        exit 1
    fi

    echo -e "${BLUE}📂 Chart: ${CHART_DIR}${RESET}"
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${GREEN}📝 Helm Template Output:${RESET}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""

    # Run helm template
    helm template "$SPELL_NAME" "$CHART_DIR" -f "$TEMP_VALUES"

    # Cleanup
    rm -f "$TEMP_VALUES"

    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${GREEN}✅ Rendering complete${RESET}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

# ═══════════════════════════════════════════════════════════════════════════
# Main dispatcher
# ═══════════════════════════════════════════════════════════════════════════
case "$MODE" in
    baseline)
        mode_baseline "$@"
        ;;
    test)
        mode_test "$@"
        ;;
    compare)
        mode_compare "$@"
        ;;
    render)
        mode_render "$@"
        ;;
    *)
        usage
        ;;
esac
