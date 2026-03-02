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
        file="$(find . -type f -not -path '*/.*' | fzf)" && echo "$file" | pbcopy && echo "Copied: $file"
    }

    # fv - fuzzy-find a file and open in editor
    fv() {
        local file
        file="$(find . -type f -not -path '*/.*' | fzf)" && ${EDITOR:-nvim} "$file"
    }
fi
