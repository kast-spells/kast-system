#!/bin/bash
# Test book/chapter/spell rendering with full librarian context
# Intelligently renders multi-source ArgoCD Applications

set -euo pipefail

# Colors
BLUE='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

# Default options
BOOK=""
CHAPTER=""
SPELL=""
MODE="summary"  # summary, eval, debug
EVAL_QUERY=""

usage() {
    echo "Usage: $0 [OPTIONS] <book> [chapter] [spell]"
    echo ""
    echo "Test levels:"
    echo "  $0 the-example-book                    # Render entire book"
    echo "  $0 the-example-book intro              # Render chapter"
    echo "  $0 the-example-book intro argocd       # Render specific spell"
    echo ""
    echo "Options:"
    echo "  --eval <query>    Run yq eval with custom query"
    echo "  --debug           Show full helm template output"
    echo "  --summary         Show resource summary (default)"
    echo ""
    echo "Examples:"
    echo "  # Show all resources in book"
    echo "  $0 the-example-book"
    echo ""
    echo "  # Query specific fields"
    echo "  $0 the-example-book intro argocd --eval '.spec.sources[] | .repoURL'"
    echo ""
    echo "  # Full debug output"
    echo "  $0 the-example-book intro argocd --debug"
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --eval)
            MODE="eval"
            EVAL_QUERY="$2"
            shift 2
            ;;
        --debug)
            MODE="debug"
            shift
            ;;
        --summary)
            MODE="summary"
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            if [ -z "$BOOK" ]; then
                BOOK="$1"
            elif [ -z "$CHAPTER" ]; then
                CHAPTER="$1"
            elif [ -z "$SPELL" ]; then
                SPELL="$1"
            else
                echo -e "${RED}Error: Too many arguments${RESET}"
                usage
            fi
            shift
            ;;
    esac
done

if [ -z "$BOOK" ]; then
    usage
fi

# Verify yq is available
if ! command -v yq &> /dev/null; then
    echo -e "${RED}Error: yq is required but not installed${RESET}"
    echo "Install with: brew install yq  (or your package manager)"
    exit 1
fi

# Determine test level
if [ -n "$SPELL" ]; then
    LEVEL="spell"
    echo -e "${BLUE}📖 Testing Spell${RESET}"
    echo -e "  Book: ${YELLOW}$BOOK${RESET}"
    echo -e "  Chapter: ${YELLOW}$CHAPTER${RESET}"
    echo -e "  Spell: ${YELLOW}$SPELL${RESET}"
elif [ -n "$CHAPTER" ]; then
    LEVEL="chapter"
    echo -e "${BLUE}📚 Testing Chapter${RESET}"
    echo -e "  Book: ${YELLOW}$BOOK${RESET}"
    echo -e "  Chapter: ${YELLOW}$CHAPTER${RESET}"
else
    LEVEL="book"
    echo -e "${BLUE}📗 Testing Book${RESET}"
    echo -e "  Book: ${YELLOW}$BOOK${RESET}"
fi

echo ""

# Step 1: Generate ArgoCD Applications via librarian
echo -e "${BLUE}🔨 Generating ArgoCD Applications via librarian...${RESET}"

LIBRARIAN_OUTPUT=$(helm template test-librarian librarian \
    --set name="$BOOK" \
    --namespace argocd \
    2>/dev/null)

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Librarian rendering failed${RESET}"
    echo "$LIBRARIAN_OUTPUT"
    exit 1
fi

# Step 2: Filter Applications based on level
case $LEVEL in
    spell)
        # Get specific spell Application
        APPLICATIONS=$(echo "$LIBRARIAN_OUTPUT" | /usr/local/bin/yq eval "select(.kind == \"Application\" and .metadata.name == \"$SPELL\")" -)
        if [ -z "$APPLICATIONS" ] || [ "$APPLICATIONS" = "null" ]; then
            echo -e "${RED}❌ No Application found for spell: $SPELL${RESET}"
            echo ""
            echo -e "${YELLOW}Available applications:${RESET}"
            echo "$LIBRARIAN_OUTPUT" | /usr/local/bin/yq eval 'select(.kind == "Application") | .metadata.name' - | sed 's/^/  - /'
            exit 1
        fi
        ;;
    chapter)
        # Get all Applications from chapter (need to add chapter metadata to detect this)
        # For now, we'll get all and user can filter
        APPLICATIONS=$(echo "$LIBRARIAN_OUTPUT" | /usr/local/bin/yq eval 'select(.kind == "Application")' -)
        echo -e "${YELLOW}ℹ️  Showing all applications (chapter filtering not yet implemented)${RESET}"
        ;;
    book)
        # Get all Applications
        APPLICATIONS=$(echo "$LIBRARIAN_OUTPUT" | /usr/local/bin/yq eval 'select(.kind == "Application")' -)
        ;;
esac

# Count applications
APP_COUNT=$(echo "$APPLICATIONS" | /usr/local/bin/yq eval 'select(.kind == "Application")' - | grep -c "kind: Application" || echo "0")
echo -e "${GREEN}✅ Found $APP_COUNT Application(s)${RESET}"
echo ""

# Step 3: Process each Application
echo -e "${BLUE}📦 Processing Applications...${RESET}"
echo ""

# Split applications into separate documents
APP_INDEX=0
while IFS= read -r app; do
    if [ -z "$app" ] || [ "$app" = "null" ]; then
        continue
    fi

    APP_INDEX=$((APP_INDEX + 1))

    # Extract application metadata
    APP_NAME=$(echo "$app" | /usr/local/bin/yq eval '.metadata.name' -)
    APP_NAMESPACE=$(echo "$app" | /usr/local/bin/yq eval '.spec.destination.namespace' -)

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${GREEN}Application: $APP_NAME${RESET}"
    echo -e "${BLUE}  Namespace: $APP_NAMESPACE${RESET}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""

    # Get sources count
    SOURCES_COUNT=$(echo "$app" | /usr/local/bin/yq eval '.spec.sources | length' -)

    if [ "$SOURCES_COUNT" = "null" ] || [ "$SOURCES_COUNT" = "0" ]; then
        echo -e "${YELLOW}  ⚠️  No sources found${RESET}"
        echo ""
        continue
    fi

    echo -e "${BLUE}  Sources: $SOURCES_COUNT${RESET}"
    echo ""

    # Process each source
    for ((i=0; i<SOURCES_COUNT; i++)); do
        echo -e "${YELLOW}  ┌─ Source $((i+1))/$SOURCES_COUNT${RESET}"

        # Extract source details
        REPO_URL=$(echo "$app" | /usr/local/bin/yq eval ".spec.sources[$i].repoURL" -)
        CHART=$(echo "$app" | /usr/local/bin/yq eval ".spec.sources[$i].chart" -)
        SOURCE_PATH=$(echo "$app" | /usr/local/bin/yq eval ".spec.sources[$i].path" -)
        TARGET_REV=$(echo "$app" | /usr/local/bin/yq eval ".spec.sources[$i].targetRevision" -)

        echo -e "${YELLOW}  │${RESET} RepoURL: $REPO_URL"

        if [ "$CHART" != "null" ]; then
            echo -e "${YELLOW}  │${RESET} Chart: $CHART"
        fi

        if [ "$SOURCE_PATH" != "null" ]; then
            echo -e "${YELLOW}  │${RESET} Path: $SOURCE_PATH"
        fi

        if [ "$TARGET_REV" != "null" ]; then
            echo -e "${YELLOW}  │${RESET} Revision: $TARGET_REV"
        fi

        # Determine if this is a local chart we can render
        LOCAL_CHART_PATH=""

        # Check if it's a local repository (contains our working path patterns)
        if [[ "$REPO_URL" == *"kast-system"* ]] || [[ "$REPO_URL" == *"github.com"* ]]; then
            # Try to find local chart
            if [ "$CHART" != "null" ]; then
                # OCI/Helm repo - look for chart name
                if [ -d "charts/$CHART" ]; then
                    LOCAL_CHART_PATH="charts/$CHART"
                elif [ -d "charts/trinkets/$CHART" ]; then
                    LOCAL_CHART_PATH="charts/trinkets/$CHART"
                fi
            elif [ "$SOURCE_PATH" != "null" ]; then
                # Git repo with path
                CLEAN_PATH=$(echo "$SOURCE_PATH" | sed 's/^\.\///')
                if [ -d "$CLEAN_PATH" ]; then
                    LOCAL_CHART_PATH="$CLEAN_PATH"
                fi
            fi
        fi

        # Extract helm values
        VALUES=$(echo "$app" | /usr/local/bin/yq eval ".spec.sources[$i].helm.values" -)

        if [ "$LOCAL_CHART_PATH" != "" ] && [ -d "$LOCAL_CHART_PATH" ]; then
            echo -e "${YELLOW}  │${RESET} ${GREEN}✓ Local chart: $LOCAL_CHART_PATH${RESET}"

            if [ "$VALUES" != "null" ] && [ -n "$VALUES" ]; then
                # Create temp values file
                TEMP_VALUES=$(mktemp)
                echo "$VALUES" > "$TEMP_VALUES"

                echo -e "${YELLOW}  │${RESET}"
                echo -e "${YELLOW}  └─ Rendering...${RESET}"
                echo ""

                # Render the chart (with destination namespace)
                RENDERED=$(helm template test-source-$i "$LOCAL_CHART_PATH" -f "$TEMP_VALUES" --namespace "$APP_NAMESPACE" 2>/dev/null)
                RENDER_EXIT=$?

                rm -f "$TEMP_VALUES"

                if [ $RENDER_EXIT -ne 0 ]; then
                    echo -e "${RED}     ❌ Render failed:${RESET}"
                    echo "$RENDERED" | sed 's/^/     /'
                    echo ""
                    continue
                fi

                # Output based on mode
                case $MODE in
                    summary)
                        # Show resource summary
                        echo -e "${GREEN}     Resources generated:${RESET}"
                        echo "$RENDERED" | /usr/local/bin/yq eval 'select(.kind) | .kind + ": " + .metadata.name' - | grep -v '^---$' | sort | uniq | sed 's/^/       /'
                        ;;
                    eval)
                        # Run custom yq query
                        echo -e "${GREEN}     Query result:${RESET}"
                        echo "$RENDERED" | /usr/local/bin/yq eval "$EVAL_QUERY" - | sed 's/^/       /'
                        ;;
                    debug)
                        # Show full output
                        echo "$RENDERED" | sed 's/^/     /'
                        ;;
                esac

                echo ""
            else
                echo -e "${YELLOW}  └─ No helm values${RESET}"
                echo ""
            fi
        else
            echo -e "${YELLOW}  │${RESET} ${YELLOW}⚠️  External/unknown chart - cannot render locally${RESET}"
            echo -e "${YELLOW}  └─${RESET}"
            echo ""
        fi
    done

done < <(echo "$APPLICATIONS" | /usr/local/bin/yq eval -o=json '.' - | /usr/bin/jq -c 'select(.kind == "Application")')

echo -e "${GREEN}✅ Test complete!${RESET}"
