#!/usr/bin/env bash

set -uo pipefail  # ⛔️ remove -e so it doesn't exit on error

# colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
PURPLE='\033[1;35m'
GREEN='\033[0;32m'
NC='\033[0m'

COMMAND="${1:-}"

# 🔁 Function to generate requirements.yaml dynamically
function generate_requirements_yaml() {
  local chart_dir="$1"
  local charts_subdir="$chart_dir/charts"
  local req_file="$chart_dir/requirements.yaml"

  [[ ! -d "$charts_subdir" ]] && return

  # Generate the new content into a temporary file
  local tmp_req
  tmp_req=$(mktemp)

  {
    echo "dependencies:"
    for subchart in "$charts_subdir"/*; do
      subchart_yaml="$subchart/Chart.yaml"
      [[ -f "$subchart_yaml" ]] || continue

      name=$(yq '.name' "$subchart_yaml")
      version=$(yq '.version' "$subchart_yaml")
      repo=$(yq '.annotations."chart-repo"' "$subchart_yaml")

      if [[ "$repo" == "null" || -z "$repo" ]]; then
        repo="file://charts/$(basename "$subchart")"
      fi

      cat <<EOF
  - name: $name
    version: "$version"
    repository: "$repo"
EOF
    done
  } > "$tmp_req"

  # Only overwrite if content changed
  if ! cmp -s "$tmp_req" "$req_file"; then
    echo -e "│   ├── ${PURPLE}📦 Updating requirements.yaml...${NC}"
    mv "$tmp_req" "$req_file"
  else
    echo -e "│   ├── ${GREEN}📦 requirements.yaml is up to date${NC}"
    rm "$tmp_req"
  fi
}


function print_chart_test_tree() {
  local chart_paths
  local failed=false

  mapfile -t chart_paths < <(find . -type f -name Chart.yaml -exec dirname {} \; | sort)

  if [ ${#chart_paths[@]} -eq 0 ]; then
    echo -e "${RED}❌ No helm charts found in path.${NC}"
    exit 1
  fi

  echo -e "${PURPLE}Helm Charts:${NC}"

  for chart in "${chart_paths[@]}"; do
    relative_chart="${chart#./}"
    echo -e "├── ${YELLOW}${relative_chart}${NC}"

    # Regenerate requirements.yaml BEFORE linting
    if [ -e "$chart/charts" ]; then
      generate_requirements_yaml "$chart"
    fi

    echo -e "│   ├── ${PURPLE}🔍 Linting...${NC}"
    if lint_output=$(helm lint "$chart" 2>&1); then
      echo -e "│   │   └── ${GREEN}✅ helm lint passed${NC}"
    else
      echo -e "│   │   └── ${RED}❌ helm lint failed${NC}"
      echo -e "${RED}${lint_output}${NC}" | sed 's/^/│   │       /'
      failed=true
    fi

    if [ -f "$chart/test.yaml" ]; then
      echo -e "│   ├── ${PURPLE}🧪 test.yaml found, testing with helm template...${NC}"
      if template_output=$(helm template "$chart" -f "$chart/test.yaml" 2>&1); then
        echo -e "│   │   └── ${GREEN}✅ helm template passed${NC}"
      else
        echo -e "│   │   └── ${RED}❌ helm template failed${NC}"
        echo -e "${RED}${template_output}${NC}" | sed 's/^/│   │       /'
        failed=true
      fi
    else
      echo -e "│   └── ℹ️  No test.yaml found"
    fi
  done

  if [ "$failed" = true ]; then
    echo -e "\n${RED}❌ Some charts failed tests.${NC}"
    exit 1
  else
    echo -e "\n${GREEN}✅ All charts passed the tests successfully.${NC}"
  fi
}

# Main
case "$COMMAND" in
  test-all)
    print_chart_test_tree
    ;;
  *)
    echo -e "${RED}Usage: $0 test-all${NC}"
    exit 1
    ;;
esac
