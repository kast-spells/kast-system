#!/bin/bash
# Test covenant book rendering with full context
# Covenant books don't have chapter/spell structure - they're pure configuration

set -euo pipefail

# Colors
BLUE='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

# Default options
COVENANT_BOOK=""
MODE="summary"  # summary, debug, full
CHAPTER="identity"  # Default chapter name for resource scoping
CHAPTER_FILTER=""  # If set, tests covenant with chapterFilter (Stage 2)
TEST_ALL_CHAPTERS=false  # If true, tests main + all chapters

usage() {
    echo "Usage: $0 [OPTIONS] <covenant-book>"
    echo ""
    echo "Test covenant book rendering:"
    echo "  $0 covenant-tyl                    # Render main covenant (ApplicationSet)"
    echo "  $0 covenant-test-full              # Render covenant-test-full book"
    echo ""
    echo "Options:"
    echo "  --debug                Show full helm template output"
    echo "  --full                 Show all generated resources"
    echo "  --summary              Show resource summary (default)"
    echo "  --chapter <name>       Set chapter name for scoping (default: identity)"
    echo "  --chapter-filter <ch>  Test with chapterFilter (simulates ApplicationSet app)"
    echo "  --all-chapters         Test main + all chapter filters"
    echo ""
    echo "Examples:"
    echo "  # Show main covenant (generates ApplicationSet)"
    echo "  $0 covenant-tyl"
    echo ""
    echo "  # Test specific chapter (as ApplicationSet would render it)"
    echo "  $0 covenant-tyl --chapter-filter tyl"
    echo ""
    echo "  # Test main + all chapters"
    echo "  $0 covenant-tyl --all-chapters"
    echo ""
    echo "  # Full debug output"
    echo "  $0 covenant-tyl --debug"
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --debug)
            MODE="debug"
            shift
            ;;
        --full)
            MODE="full"
            shift
            ;;
        --summary)
            MODE="summary"
            shift
            ;;
        --chapter)
            CHAPTER="$2"
            shift 2
            ;;
        --chapter-filter)
            CHAPTER_FILTER="$2"
            shift 2
            ;;
        --all-chapters)
            TEST_ALL_CHAPTERS=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            if [ -z "$COVENANT_BOOK" ]; then
                COVENANT_BOOK="$1"
            else
                echo -e "${RED}Error: Too many arguments${RESET}"
                usage
            fi
            shift
            ;;
    esac
done

if [ -z "$COVENANT_BOOK" ]; then
    usage
fi

# Verify yq is available
if ! command -v yq &> /dev/null; then
    echo -e "${RED}Error: yq is required but not installed${RESET}"
    echo "Install with: brew install yq  (or your package manager)"
    exit 1
fi

# Covenant and bookrack paths (configurable via env vars)
# Priority: 1. Env var, 2. Relative path, 3. Default user path
COVENANT_CHART_PATH="${COVENANT_CHART_PATH:-}"
BOOKRACK_PATH="${COVENANT_BOOKRACK_PATH:-}"

# Auto-detect if not set
if [ -z "$COVENANT_CHART_PATH" ]; then
    # Try kast-system first (new location), then proto-the-yaml-life (legacy)
    if [ -d "covenant" ]; then
        COVENANT_CHART_PATH="covenant"
    elif [ -d "../proto-the-yaml-life/covenant" ]; then
        COVENANT_CHART_PATH="../proto-the-yaml-life/covenant"
    elif [ -d "$HOME/_home/the.yaml.life/proto-the-yaml-life/covenant" ]; then
        COVENANT_CHART_PATH="$HOME/_home/the.yaml.life/proto-the-yaml-life/covenant"
    fi
fi

if [ -z "$BOOKRACK_PATH" ]; then
    # Try kast-system first, then proto-the-yaml-life
    if [ -d "bookrack" ]; then
        BOOKRACK_PATH="bookrack"
    elif [ -d "../proto-the-yaml-life/bookrack" ]; then
        BOOKRACK_PATH="../proto-the-yaml-life/bookrack"
    elif [ -d "$HOME/_home/the.yaml.life/proto-the-yaml-life/bookrack" ]; then
        BOOKRACK_PATH="$HOME/_home/the.yaml.life/proto-the-yaml-life/bookrack"
    fi
fi

# Verify covenant chart exists
if [ ! -d "$COVENANT_CHART_PATH" ]; then
    echo -e "${RED}Error: Covenant chart not found: $COVENANT_CHART_PATH${RESET}"
    echo -e "${YELLOW}Set COVENANT_CHART_PATH to point to covenant chart location${RESET}"
    echo -e "${YELLOW}Example: export COVENANT_CHART_PATH=/path/to/proto-the-yaml-life/covenant${RESET}"
    exit 1
fi

# Verify covenant book exists
if [ ! -d "$BOOKRACK_PATH/$COVENANT_BOOK" ]; then
    echo -e "${RED}Error: Covenant book not found: $BOOKRACK_PATH/$COVENANT_BOOK${RESET}"
    echo -e "${YELLOW}Set COVENANT_BOOKRACK_PATH to point to bookrack location${RESET}"
    echo -e "${YELLOW}Example: export COVENANT_BOOKRACK_PATH=/path/to/proto-the-yaml-life/bookrack${RESET}"
    exit 1
fi

# Verify covenant book has index.yaml with realm config
if [ ! -f "$BOOKRACK_PATH/$COVENANT_BOOK/index.yaml" ]; then
    echo -e "${RED}Error: Covenant book missing index.yaml: $BOOKRACK_PATH/$COVENANT_BOOK/index.yaml${RESET}"
    exit 1
fi

# Handle --all-chapters mode
if [ "$TEST_ALL_CHAPTERS" = true ]; then
    echo -e "${BLUE}📖 Testing All Chapters Mode${RESET}"
    echo -e "  Book: ${YELLOW}$COVENANT_BOOK${RESET}"
    echo ""

    # Discover all chapters
    CHAPTERS=$(find "$BOOKRACK_PATH/$COVENANT_BOOK" -maxdepth 2 -name "index.yaml" ! -path "*/$COVENANT_BOOK/index.yaml" -exec dirname {} \; | xargs -I {} basename {} | sort)
    CHAPTER_COUNT=$(echo "$CHAPTERS" | wc -w | xargs)

    echo -e "${BLUE}Discovered chapters: ${YELLOW}$CHAPTER_COUNT${RESET}"
    echo "$CHAPTERS" | tr ' ' '\n' | sed 's/^/  - /'
    echo ""

    # First test main covenant (no chapterFilter)
    echo -e "${BLUE}================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================━${RESET}"
    echo -e "${BLUE}[1/$(($CHAPTER_COUNT + 1))] Testing Main Covenant (ApplicationSet Generator)${RESET}"
    echo -e "${BLUE}================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================━${RESET}"
    "$0" "$COVENANT_BOOK" "--$MODE"
    MAIN_RESULT=$?

    if [ $MAIN_RESULT -ne 0 ]; then
        echo -e "${RED}[ERROR] Main covenant test failed${RESET}"
        exit 1
    fi

    # Then test each chapter with chapterFilter
    CHAPTER_NUM=2
    for CHAPTER_NAME in $CHAPTERS; do
        echo ""
        echo -e "${BLUE}================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================━${RESET}"
        echo -e "${BLUE}[$CHAPTER_NUM/$(($CHAPTER_COUNT + 1))] Testing Chapter: $CHAPTER_NAME${RESET}"
        echo -e "${BLUE}================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================━${RESET}"
        "$0" "$COVENANT_BOOK" "--$MODE" --chapter-filter "$CHAPTER_NAME"
        CHAPTER_RESULT=$?

        if [ $CHAPTER_RESULT -ne 0 ]; then
            echo -e "${RED}[ERROR] Chapter $CHAPTER_NAME test failed${RESET}"
            exit 1
        fi

        CHAPTER_NUM=$(($CHAPTER_NUM + 1))
    done

    echo ""
    echo -e "${GREEN}================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================━${RESET}"
    echo -e "${GREEN}[OK] All tests passed! (Main + $CHAPTER_COUNT chapters)${RESET}"
    echo -e "${GREEN}================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================━${RESET}"
    exit 0
fi

echo -e "${BLUE}📖 Testing Covenant Book${RESET}"
echo -e "  Book: ${YELLOW}$COVENANT_BOOK${RESET}"
if [ -n "$CHAPTER_FILTER" ]; then
    echo -e "  Mode: ${YELLOW}Chapter Filter (Stage 2)${RESET}"
    echo -e "  Chapter Filter: ${YELLOW}$CHAPTER_FILTER${RESET}"
else
    echo -e "  Mode: ${YELLOW}Main Covenant (Stage 1)${RESET}"
fi
echo -e "  Chapter Context: ${YELLOW}$CHAPTER${RESET}"
echo ""

# Read book index to get realm info and repository settings
REALM_NAME=$(yq '.realm.name // "kast"' "$BOOKRACK_PATH/$COVENANT_BOOK/index.yaml")

# Read repository settings from covenant book index (required for ApplicationSet)
BOOK_REPOSITORY=$(yq '.repository // ""' "$BOOKRACK_PATH/$COVENANT_BOOK/index.yaml")
BOOK_PATH=$(yq '.path // ""' "$BOOKRACK_PATH/$COVENANT_BOOK/index.yaml")
BOOK_REVISION=$(yq '.revision // ""' "$BOOKRACK_PATH/$COVENANT_BOOK/index.yaml")

# Fallback to defaults if not specified in book
BOOK_REPOSITORY=${BOOK_REPOSITORY:-"https://github.com/kast-spells/kast-system.git"}
BOOK_PATH=${BOOK_PATH:-"./covenant"}
BOOK_REVISION=${BOOK_REVISION:-"main"}

echo -e "${BLUE}📋 Covenant Configuration${RESET}"
echo -e "  Realm: ${YELLOW}$REALM_NAME${RESET}"

# Count integrations (KeycloakClients)
INTEGRATIONS_COUNT=0
if [ -d "$BOOKRACK_PATH/$COVENANT_BOOK/conventions/integrations" ]; then
    INTEGRATIONS_COUNT=$(find "$BOOKRACK_PATH/$COVENANT_BOOK/conventions/integrations" -name "*.yaml" -o -name "*.yml" | wc -l | xargs)
fi
echo -e "  Integrations: ${YELLOW}$INTEGRATIONS_COUNT${RESET}"

# Count client scopes
CLIENT_SCOPES_COUNT=0
if [ -d "$BOOKRACK_PATH/$COVENANT_BOOK/conventions/client-scopes" ]; then
    CLIENT_SCOPES_COUNT=$(find "$BOOKRACK_PATH/$COVENANT_BOOK/conventions/client-scopes" -name "*.yaml" -o -name "*.yml" | wc -l | xargs)
fi
echo -e "  Client Scopes: ${YELLOW}$CLIENT_SCOPES_COUNT${RESET}"

# Count members (users)
MEMBERS_COUNT=0
if [ -d "$BOOKRACK_PATH/$COVENANT_BOOK" ]; then
    MEMBERS_COUNT=$(find "$BOOKRACK_PATH/$COVENANT_BOOK" -type f \( -name "*.yaml" -o -name "*.yml" \) -path "*/*/index.yaml" -prune -o -type f \( -name "*.yaml" -o -name "*.yml" \) ! -path "*/conventions/*" ! -name "index.yaml" -print | wc -l | xargs)
fi
echo -e "  Members: ${YELLOW}$MEMBERS_COUNT${RESET}"
echo ""

# Build lexicon for testing (normally provided by librarian)
# This mimics what librarian would inject
# Production covenant requires keycloakCrdName in lexicon
LEXICON_VAULT='{"type":"vault","url":"http://vault.vault.svc:8200","namespace":"vault","serviceAccount":"vault","authPath":"kubernetes","secretPath":"identity/oidc","labels":{"default":"book"}}'
LEXICON_KEYCLOAK='{"type":"keycloak","url":"http://keycloak.keycloak.svc","namespace":"keycloak","keycloakCrdName":"main","labels":{"default":"book"}}'

echo -e "${BLUE}🔨 Rendering Production Covenant...${RESET}"

# Create temp file for output
TEMP_OUTPUT=$(mktemp)
trap "rm -f $TEMP_OUTPUT" EXIT

# Build helm command with optional chapterFilter
# When using chapterFilter, name must include chapter suffix (e.g., covenant-tyl-tyl)
# The covenant template will strip the suffix to get the book path
RELEASE_NAME="$COVENANT_BOOK"
COVENANT_NAME="$COVENANT_BOOK"
if [ -n "$CHAPTER_FILTER" ]; then
    RELEASE_NAME="$COVENANT_BOOK-$CHAPTER_FILTER"
    COVENANT_NAME="$COVENANT_BOOK-$CHAPTER_FILTER"
fi

HELM_ARGS=(
    "$RELEASE_NAME"
    "$COVENANT_CHART_PATH"
    --set name="$COVENANT_NAME"
    --set spellbook.name="$COVENANT_BOOK"
    --set spellbook.argocdNamespace="argocd"
    --set spellbook.repository="$BOOK_REPOSITORY"
    --set spellbook.path="$BOOK_PATH"
    --set spellbook.revision="$BOOK_REVISION"
    --set chapter.name="$CHAPTER"
    --set-json "lexicon[0]=$LEXICON_VAULT"
    --set-json "lexicon[1]=$LEXICON_KEYCLOAK"
)

# Add chapterFilter if specified (Stage 2 mode)
if [ -n "$CHAPTER_FILTER" ]; then
    HELM_ARGS+=(--set covenant.chapterFilter="$CHAPTER_FILTER")
fi

# Render covenant chart with book context
helm template "${HELM_ARGS[@]}" > "$TEMP_OUTPUT" 2>&1

RENDER_EXIT_CODE=$?

if [ $RENDER_EXIT_CODE -ne 0 ]; then
    echo -e "${RED}[ERROR] Rendering failed${RESET}"
    cat "$TEMP_OUTPUT"
    exit 1
fi

echo -e "${GREEN}[OK] Rendering successful${RESET}"
echo ""

# Process output based on mode
case $MODE in
    debug)
        echo -e "${BLUE}================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================━${RESET}"
        echo -e "${BLUE}Full Helm Template Output${RESET}"
        echo -e "${BLUE}================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================━${RESET}"
        cat "$TEMP_OUTPUT"
        ;;

    full)
        echo -e "${BLUE}================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================━${RESET}"
        echo -e "${BLUE}Generated Resources${RESET}"
        echo -e "${BLUE}================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================━${RESET}"
        # Filter out comments and warnings, show YAML documents
        grep -v "^#" "$TEMP_OUTPUT" | grep -v "^walk.go"
        ;;

    summary)
        echo -e "${BLUE}================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================━${RESET}"
        echo -e "${GREEN}Resources Generated${RESET}"
        echo -e "${BLUE}================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================━${RESET}"

        # Extract and count resources
        RESOURCES=$(grep "^kind:" "$TEMP_OUTPUT" | sort | uniq -c | sort -rn)

        if [ -z "$RESOURCES" ]; then
            echo -e "${YELLOW}  No Kubernetes resources generated${RESET}"
        else
            echo "$RESOURCES" | while read count kind_line; do
                kind=$(echo "$kind_line" | awk '{print $2}')
                echo -e "  ${GREEN}$kind${RESET}: $count"
            done
        fi

        echo ""

        # Show specific Keycloak resources
        echo -e "${BLUE}Keycloak Resources:${RESET}"
        # Count both KeycloakRealm and ClusterKeycloakRealm
        KEYCLOAK_REALM=$(grep -cE "kind: (KeycloakRealm|ClusterKeycloakRealm)$" "$TEMP_OUTPUT" 2>/dev/null || echo "0")
        KEYCLOAK_CLIENTS=$(grep -c "kind: KeycloakClient$" "$TEMP_OUTPUT" 2>/dev/null || echo "0")
        KEYCLOAK_GROUPS=$(grep -c "kind: KeycloakRealmGroup$" "$TEMP_OUTPUT" 2>/dev/null || echo "0")
        KEYCLOAK_USERS=$(grep -c "kind: KeycloakRealmUser$" "$TEMP_OUTPUT" 2>/dev/null || echo "0")

        echo -e "  Realm: ${YELLOW}${KEYCLOAK_REALM}${RESET}"
        echo -e "  Clients: ${YELLOW}${KEYCLOAK_CLIENTS}${RESET}"
        echo -e "  Groups: ${YELLOW}${KEYCLOAK_GROUPS}${RESET}"
        echo -e "  Users: ${YELLOW}${KEYCLOAK_USERS}${RESET}"

        # Validate based on mode
        if [ -n "$CHAPTER_FILTER" ]; then
            # Chapter mode: Should have Users and Groups, NO Realm or ApplicationSet
            USERS_NUM=$(echo "$KEYCLOAK_USERS" | tr -d '\n')
            GROUPS_NUM=$(echo "$KEYCLOAK_GROUPS" | tr -d '\n')
            if [ "${USERS_NUM:-0}" -eq 0 ]; then
                echo -e "  ${RED}⚠ Warning: No KeycloakUsers generated in chapter mode${RESET}"
            fi
            if [ "${GROUPS_NUM:-0}" -eq 0 ]; then
                echo -e "  ${RED}⚠ Warning: No KeycloakGroups generated in chapter mode${RESET}"
            fi
        else
            # Main mode: Should have Realm, NO Users or Groups
            REALM_NUM=$(echo "$KEYCLOAK_REALM" | tr -d '\n')
            USERS_NUM=$(echo "$KEYCLOAK_USERS" | tr -d '\n')
            GROUPS_NUM=$(echo "$KEYCLOAK_GROUPS" | tr -d '\n')
            if [ "${REALM_NUM:-0}" -eq 0 ]; then
                echo -e "  ${RED}⚠ Warning: No KeycloakRealm or ClusterKeycloakRealm generated in main mode${RESET}"
            fi
            if [ "${USERS_NUM:-0}" -gt 0 ]; then
                echo -e "  ${RED}⚠ Warning: KeycloakUsers should not be in main covenant${RESET}"
            fi
            if [ "${GROUPS_NUM:-0}" -gt 0 ]; then
                echo -e "  ${RED}⚠ Warning: KeycloakGroups should not be in main covenant${RESET}"
            fi
        fi

        echo ""

        # Show Vault resources
        echo -e "${BLUE}Vault Resources:${RESET}"
        VAULT_SECRETS=$(grep -c "kind: VaultSecret$" "$TEMP_OUTPUT" 2>/dev/null || echo "0")
        RANDOM_SECRETS=$(grep -c "kind: RandomSecret$" "$TEMP_OUTPUT" 2>/dev/null || echo "0")

        echo -e "  VaultSecrets: ${YELLOW}${VAULT_SECRETS}${RESET}"
        echo -e "  RandomSecrets: ${YELLOW}${RANDOM_SECRETS}${RESET}"

        echo ""

        # Show ApplicationSet (main mode only)
        APPLICATIONSETS=$(grep -c "kind: ApplicationSet$" "$TEMP_OUTPUT" 2>/dev/null || echo "0")
        APPSETS_NUM=$(echo "$APPLICATIONSETS" | tr -d '\n')
        if [ -n "$CHAPTER_FILTER" ]; then
            # Chapter mode: Should NOT have ApplicationSet
            if [ "${APPSETS_NUM:-0}" -gt 0 ]; then
                echo -e "${RED}⚠ ERROR: ApplicationSet should not be in chapter mode${RESET}"
            fi
        else
            # Main mode: Should have ApplicationSet
            echo -e "${BLUE}ArgoCD Resources:${RESET}"
            echo -e "  ApplicationSets: ${YELLOW}${APPLICATIONSETS}${RESET}"
            if [ "${APPSETS_NUM:-0}" -eq 0 ]; then
                echo -e "  ${RED}⚠ Warning: No ApplicationSet generated in main mode${RESET}"
            fi
            echo ""
        fi

        # Show Jobs (post-provisioning) - only in chapter mode
        JOBS=$(grep -c "kind: Job$" "$TEMP_OUTPUT" 2>/dev/null || echo "0")
        JOBS_NUM=$(echo "$JOBS" | tr -d '\n')
        if [ "${JOBS_NUM:-0}" -gt 0 ]; then
            echo -e "${BLUE}Post-Provisioning Jobs:${RESET}"
            echo -e "  Jobs: ${YELLOW}${JOBS}${RESET}"
            echo ""
        fi

        # List KeycloakClient names
        CLIENTS_NUM=$(echo "$KEYCLOAK_CLIENTS" | tr -d '\n')
        if [ "${CLIENTS_NUM:-0}" -gt 0 ]; then
            echo -e "${BLUE}KeycloakClients:${RESET}"
            grep -A2 "kind: KeycloakClient" "$TEMP_OUTPUT" | grep "name:" | awk '{print "  - " $2}' | head -10
            if [ "$KEYCLOAK_CLIENTS" -gt 10 ]; then
                echo -e "  ${YELLOW}... and $((KEYCLOAK_CLIENTS - 10)) more${RESET}"
            fi
            echo ""
        fi

        # List VaultSecret names
        VSECRETS_NUM=$(echo "$VAULT_SECRETS" | tr -d '\n')
        if [ "${VSECRETS_NUM:-0}" -gt 0 ]; then
            echo -e "${BLUE}VaultSecrets:${RESET}"
            grep -A2 "kind: VaultSecret" "$TEMP_OUTPUT" | grep "name:" | awk '{print "  - " $2}' | head -10
            if [ "$VAULT_SECRETS" -gt 10 ]; then
                echo -e "  ${YELLOW}... and $((VAULT_SECRETS - 10)) more${RESET}"
            fi
        fi
        ;;
esac

echo ""
echo -e "${GREEN}[OK] Covenant book test complete!${RESET}"
