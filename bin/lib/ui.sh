#!/usr/bin/env bash
# Shared terminal UI helpers for bin/ scripts.
#
# Plain ANSI output by default so test/CI output stays stable; headers are
# upgraded via gum (https://github.com/charmbracelet/gum) when it is
# installed and stdout is a terminal. Accent hexes match the repo's OneDark
# theme (see README.md "Theme").
#
# Usage:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "$SCRIPT_DIR/lib/ui.sh"

# Guard against double-sourcing (the readonly colors would error).
[[ -n "${DOTFILES_UI_LOADED:-}" ]] && return 0
readonly DOTFILES_UI_LOADED=1

readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m' # No Color

_ui_use_gum() {
    [[ -t 1 ]] && command -v gum > /dev/null 2>&1
}

print_header() {
    if _ui_use_gum; then
        echo ""
        gum style --border rounded --padding "0 2" \
            --border-foreground "#61afef" --foreground "#61afef" "$1"
    else
        echo ""
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BLUE}  $1${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    fi
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}
