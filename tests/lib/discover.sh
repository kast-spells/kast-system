#!/bin/bash
# Auto-discovery Library
# Discovers kast-system components (glyphs, trinkets, charts, books)

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

REPO_ROOT="$(get_repo_root)"

# Discover all glyphs
discover_glyphs() {
    local glyphs=()
    for glyph_dir in "$REPO_ROOT/charts/glyphs"/*/; do
        if [ -d "$glyph_dir" ]; then
            glyphs+=("$(basename "$glyph_dir")")
        fi
    done
    echo "${glyphs[@]}"
}

# Discover glyphs with examples
discover_tested_glyphs() {
    local glyphs=()
    for glyph_dir in "$REPO_ROOT/charts/glyphs"/*/; do
        if [ -d "$glyph_dir" ] && [ -d "$glyph_dir/examples" ]; then
            local example_count=$(find "$glyph_dir/examples" -name "*.yaml" -type f 2>/dev/null | wc -l)
            if [ "$example_count" -gt 0 ]; then
                glyphs+=("$(basename "$glyph_dir")")
            fi
        fi
    done
    echo "${glyphs[@]}"
}

# Discover untested glyphs
discover_untested_glyphs() {
    local glyphs=()
    for glyph_dir in "$REPO_ROOT/charts/glyphs"/*/; do
        if [ -d "$glyph_dir" ]; then
            local glyph_name=$(basename "$glyph_dir")
            if [ ! -d "$glyph_dir/examples" ]; then
                glyphs+=("$glyph_name")
            else
                local example_count=$(find "$glyph_dir/examples" -name "*.yaml" -type f 2>/dev/null | wc -l)
                if [ "$example_count" -eq 0 ]; then
                    glyphs+=("$glyph_name")
                fi
            fi
        fi
    done
    echo "${glyphs[@]}"
}

# Discover all trinkets
discover_trinkets() {
    local trinkets=()
    for trinket_dir in "$REPO_ROOT/charts/trinkets"/*/; do
        if [ -d "$trinket_dir" ] && [ -f "$trinket_dir/Chart.yaml" ]; then
            trinkets+=("$(basename "$trinket_dir")")
        fi
    done
    echo "${trinkets[@]}"
}

# Discover main charts
discover_charts() {
    local charts=()
    for chart_file in $(find "$REPO_ROOT/charts" -maxdepth 2 -name "Chart.yaml" -not -path "*/glyphs/*" -not -path "*/trinkets/*" 2>/dev/null); do
        local chart_dir=$(dirname "$chart_file")
        charts+=("$(basename "$chart_dir")")
    done
    # Add librarian
    if [ -f "$REPO_ROOT/librarian/Chart.yaml" ]; then
        charts+=("librarian")
    fi
    echo "${charts[@]}"
}

# Discover books
discover_books() {
    local books=()
    local bookrack_path="${BOOKRACK_PATH:-$REPO_ROOT/bookrack}"

    if [ -d "$bookrack_path" ]; then
        for book_dir in "$bookrack_path"/*/; do
            if [ -f "$book_dir/index.yaml" ]; then
                books+=("$(basename "$book_dir")")
            fi
        done
    fi
    echo "${books[@]}"
}

# Discover covenant books
discover_covenant_books() {
    local books=()
    local bookrack_path="${COVENANT_BOOKRACK_PATH:-$HOME/_home/the.yaml.life/proto-the-yaml-life/bookrack}"

    if [ -d "$bookrack_path" ]; then
        for book_file in $(find "$bookrack_path" -maxdepth 2 -name "index.yaml" -exec grep -l "realm:" {} \; 2>/dev/null); do
            local book_dir=$(dirname "$book_file")
            books+=("$(basename "$book_dir")")
        done
    fi
    echo "${books[@]}"
}

# Check if component exists
glyph_exists() {
    local glyph="$1"
    [ -d "$REPO_ROOT/charts/glyphs/$glyph" ]
}

trinket_exists() {
    local trinket="$1"
    [ -d "$REPO_ROOT/charts/trinkets/$trinket" ] && [ -f "$REPO_ROOT/charts/trinkets/$trinket/Chart.yaml" ]
}

chart_exists() {
    local chart="$1"
    [ -f "$REPO_ROOT/charts/$chart/Chart.yaml" ] || [ -f "$REPO_ROOT/$chart/Chart.yaml" ]
}

book_exists() {
    local book="$1"
    local bookrack_path="${BOOKRACK_PATH:-$REPO_ROOT/bookrack}"
    [ -f "$bookrack_path/$book/index.yaml" ]
}

# Get component path
get_glyph_path() {
    echo "$REPO_ROOT/charts/glyphs/$1"
}

get_trinket_path() {
    echo "$REPO_ROOT/charts/trinkets/$1"
}

get_chart_path() {
    local chart="$1"
    if [ -f "$REPO_ROOT/charts/$chart/Chart.yaml" ]; then
        echo "$REPO_ROOT/charts/$chart"
    elif [ -f "$REPO_ROOT/$chart/Chart.yaml" ]; then
        echo "$REPO_ROOT/$chart"
    fi
}

get_book_path() {
    local bookrack_path="${BOOKRACK_PATH:-$REPO_ROOT/bookrack}"
    echo "$bookrack_path/$1"
}

# Get examples for component
get_glyph_examples() {
    local glyph="$1"
    local glyph_path=$(get_glyph_path "$glyph")

    if [ -d "$glyph_path/examples" ]; then
        find "$glyph_path/examples" -name "*.yaml" -type f 2>/dev/null | sort
    fi
}

get_trinket_examples() {
    local trinket="$1"
    local trinket_path=$(get_trinket_path "$trinket")

    if [ -d "$trinket_path/examples" ]; then
        find "$trinket_path/examples" -name "*.yaml" -type f 2>/dev/null | sort
    fi
}

get_chart_examples() {
    local chart="$1"
    local chart_path=$(get_chart_path "$chart")

    if [ -d "$chart_path/examples" ]; then
        find "$chart_path/examples" -name "*.yaml" -type f 2>/dev/null | sort
    fi
}

# Export functions
export -f discover_glyphs discover_tested_glyphs discover_untested_glyphs
export -f discover_trinkets discover_charts discover_books discover_covenant_books
export -f glyph_exists trinket_exists chart_exists book_exists
export -f get_glyph_path get_trinket_path get_chart_path get_book_path
export -f get_glyph_examples get_trinket_examples get_chart_examples
