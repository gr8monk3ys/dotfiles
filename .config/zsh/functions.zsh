#!/usr/bin/env zsh

# ============================================================================
# Shell Functions
# ============================================================================
# Fuzzy-finder productivity functions.
# Sourced from .zshrc alongside aliases.zsh.

# cx - cd into directory and list contents
cx() { cd "$@" && l; }

# Fuzzy-finder functions (require fzf)
if command -v fzf &> /dev/null; then
    # f - fuzzy-find a file and copy its path to clipboard
    f() {
        local file
        file="$(find . -type f -not -path '*/.*' | fzf)" || return
        if command -v pbcopy &> /dev/null; then
            printf '%s' "$file" | pbcopy
        elif command -v wl-copy &> /dev/null; then
            printf '%s' "$file" | wl-copy
        elif command -v xclip &> /dev/null; then
            printf '%s' "$file" | xclip -selection clipboard
        else
            echo "$file"
            return
        fi
        echo "Copied: $file"
    }

    # fv - fuzzy-find a file and open in editor
    fv() {
        local file
        file="$(find . -type f -not -path '*/.*' | fzf)" && ${EDITOR:-nvim} "$file"
    }
fi
