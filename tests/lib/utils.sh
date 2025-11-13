#!/bin/bash
# Common Utilities Library
# Provides shared functions for all test scripts

# Colors (no emojis, professional output)
export BLUE='\033[36m'
export GREEN='\033[32m'
export YELLOW='\033[33m'
export RED='\033[31m'
export RESET='\033[0m'

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${RESET} $*"
}

log_success() {
    echo -e "${GREEN}[PASS]${RESET} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${RESET} $*"
}

log_error() {
    echo -e "${RED}[FAIL]${RESET} $*"
}

log_header() {
    echo ""
    echo -e "${BLUE}=================================================================${RESET}"
    echo -e "${BLUE}$*${RESET}"
    echo -e "${BLUE}=================================================================${RESET}"
}

log_section() {
    echo ""
    echo -e "${BLUE}--- $* ---${RESET}"
}

# Result tracking
declare -g TESTS_PASSED=0
declare -g TESTS_FAILED=0
declare -g TESTS_SKIPPED=0

increment_passed() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

increment_failed() {
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

increment_skipped() {
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
}

print_summary() {
    local total=$((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))
    echo ""
    log_header "Test Summary"
    echo "Total:   $total"
    echo -e "${GREEN}Passed:  $TESTS_PASSED${RESET}"
    echo -e "${RED}Failed:  $TESTS_FAILED${RESET}"
    echo -e "${YELLOW}Skipped: $TESTS_SKIPPED${RESET}"

    if [ $TESTS_FAILED -gt 0 ]; then
        return 1
    fi
    return 0
}

# Path utilities
get_repo_root() {
    git rev-parse --show-toplevel 2>/dev/null || echo "."
}

# Check dependencies
check_command() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        log_error "Required command not found: $cmd"
        return 1
    fi
    return 0
}

check_required_commands() {
    local missing=0
    for cmd in "$@"; do
        if ! check_command "$cmd"; then
            missing=1
        fi
    done
    return $missing
}

# File operations
file_exists() {
    [ -f "$1" ]
}

dir_exists() {
    [ -d "$1" ]
}

# Parse flags from arguments
parse_flag() {
    local flag="$1"
    shift
    for arg in "$@"; do
        if [[ "$arg" == "--$flag="* ]]; then
            echo "${arg#--$flag=}"
            return 0
        elif [[ "$arg" == "--$flag" ]]; then
            # Look for next arg as value
            return 0
        fi
    done
    return 1
}

get_flag_value() {
    local flag="$1"
    shift
    local args=("$@")

    for i in "${!args[@]}"; do
        if [[ "${args[$i]}" == "--$flag="* ]]; then
            echo "${args[$i]#--$flag=}"
            return 0
        elif [[ "${args[$i]}" == "--$flag" ]]; then
            # Next arg is the value
            if [ $((i + 1)) -lt ${#args[@]} ]; then
                echo "${args[$((i + 1))]}"
                return 0
            fi
        fi
    done
    return 1
}

# Export all functions
export -f log_info log_success log_warning log_error log_header log_section
export -f increment_passed increment_failed increment_skipped print_summary
export -f get_repo_root check_command check_required_commands
export -f file_exists dir_exists parse_flag get_flag_value
