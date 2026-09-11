#!/usr/bin/env zsh

# ============================================================================
# Shared Shell Helpers
# ============================================================================
# Things both aliases.zsh and functions.zsh need. Sourced from .zshrc BEFORE
# either of them — that ordering is load-bearing, not incidental: aliases.zsh
# builds the `copy` alias out of _dotfiles_clipboard, and zsh expands aliases
# when a function body is parsed, so functions.zsh must come after too.
# test_shell_boot.bats asserts the helper is live, which is what makes the
# ordering a checked constraint rather than a comment.

# _dotfiles_clipboard - copy stdin to the system clipboard.
#
# Returns 1 when no clipboard tool is available, so each caller decides what
# that means: `copy` fails loudly (you asked to copy and it could not), while
# `f` degrades to printing the path (you asked to find a file and still get
# it). Previously this chain was written out twice, in aliases.zsh and
# functions.zsh, and the two had drifted to different fallbacks by accident.
_dotfiles_clipboard() {
    if command -v pbcopy &> /dev/null; then
        pbcopy
    elif command -v wl-copy &> /dev/null; then
        wl-copy
    elif command -v xclip &> /dev/null; then
        xclip -selection clipboard
    else
        return 1
    fi
}
