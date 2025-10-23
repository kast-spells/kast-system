#!/bin/bash
# Render a spell using values from ArgoCD Application in cluster
# Usage: ./render-spell-from-cluster.sh <spell-name>

set -euo pipefail

SPELL_NAME="${1:-}"

if [ -z "$SPELL_NAME" ]; then
  echo "Usage: $0 <spell-name>"
  echo "Example: $0 stalwart"
  exit 1
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Searching for Application: ${SPELL_NAME}${NC}"

# Check if Application exists
if ! kubectl get application "$SPELL_NAME" -n argocd &>/dev/null; then
  echo -e "${RED}❌ Application '$SPELL_NAME' not found in argocd namespace${NC}"
  exit 1
fi

echo -e "${GREEN}✅ Found Application: ${SPELL_NAME}${NC}"

# Extract Application spec
APP_SPEC=$(kubectl get application "$SPELL_NAME" -n argocd -o json)

# Get repository URL from first source
REPO_URL=$(echo "$APP_SPEC" | jq -r '.spec.sources[0].repoURL // .spec.source.repoURL')
TARGET_REVISION=$(echo "$APP_SPEC" | jq -r '.spec.sources[0].targetRevision // .spec.source.targetRevision')
CHART_PATH=$(echo "$APP_SPEC" | jq -r '.spec.sources[0].path // .spec.source.path')

echo -e "${BLUE}📦 Repository: ${REPO_URL}${NC}"
echo -e "${BLUE}🔖 Revision: ${TARGET_REVISION}${NC}"
echo -e "${BLUE}📁 Path: ${CHART_PATH}${NC}"

# Check if it's a local repository (kast-system)
if [[ ! "$REPO_URL" =~ github.com/kast-spells/kast-system ]]; then
  echo -e "${YELLOW}⚠️  This is not a local kast-system repository${NC}"
  echo -e "${YELLOW}   Repository: ${REPO_URL}${NC}"
  echo -e "${YELLOW}   This script only works with local kast-system repos${NC}"
  exit 1
fi

echo -e "${GREEN}✅ Local kast-system repository detected${NC}"

# Extract values from first source (main spell configuration)
VALUES=$(echo "$APP_SPEC" | jq -r '.spec.sources[0].helm.values // .spec.source.helm.values')

# Determine chart to use based on path and values content
# If values contain glyphs, use kaster (even if path is summon)
# This mimics librarian's trinket detection behavior
if echo "$VALUES" | grep -q "^glyphs:"; then
  CHART="kaster"
  echo -e "${BLUE}🎭 Detected glyphs in values, using kaster chart${NC}"
elif [[ "$CHART_PATH" == *"kaster"* ]]; then
  CHART="kaster"
else
  CHART="summon"  # Fallback to summon for simple workloads
fi

if [ -z "$VALUES" ] || [ "$VALUES" == "null" ]; then
  echo -e "${RED}❌ No helm values found in Application${NC}"
  exit 1
fi

# Create temporary values file
TEMP_VALUES=$(mktemp /tmp/spell-values-XXXXXX.yaml)
echo "$VALUES" > "$TEMP_VALUES"

echo -e "${BLUE}💾 Values saved to: ${TEMP_VALUES}${NC}"

# Show values summary
echo -e "${BLUE}📊 Values summary:${NC}"
echo "$VALUES" | head -30
if [ $(echo "$VALUES" | wc -l) -gt 30 ]; then
  echo -e "${YELLOW}... (truncated, full values in ${TEMP_VALUES})${NC}"
fi

# Render with helm template
echo -e "${BLUE}🎨 Rendering spell with helm template...${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CHART_DIR="${REPO_ROOT}/charts/${CHART}"

if [ ! -d "$CHART_DIR" ]; then
  echo -e "${RED}❌ Chart directory not found: ${CHART_DIR}${NC}"
  rm -f "$TEMP_VALUES"
  exit 1
fi

echo -e "${BLUE}📂 Chart: ${CHART_DIR}${NC}"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}📝 Helm Template Output:${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Run helm template
helm template "$SPELL_NAME" "$CHART_DIR" -f "$TEMP_VALUES"

# Cleanup
rm -f "$TEMP_VALUES"

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Rendering complete${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
