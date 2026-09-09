#!/usr/bin/env bash
# Shared preamble for bin/ scripts: checkout resolution and the
# command-presence predicate.
#
# SCRIPT_DIR deliberately does not live here — a script needs it to find this
# file in the first place. Every caller starts with the same two lines:
#
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "$SCRIPT_DIR/lib/preamble.sh"
#
# Non-bash callers (the Makefile, which cannot source) use `bin/platform has`
# for the same predicate.

# Guard against double-sourcing (the readonly DOTFILES_DIR would error).
[[ -n "${DOTFILES_PREAMBLE_LOADED:-}" ]] && return 0
readonly DOTFILES_PREAMBLE_LOADED=1

# Default to the checkout this library lives in (works through symlinks), so
# running bin/dotfiles-* from any clone operates on that clone. Resolved from
# this file rather than from the calling script: the library is always inside
# the checkout, whereas the script may be reached through a symlink elsewhere.
if [[ -z "${DOTFILES_DIR:-}" ]]; then
    DOTFILES_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../.." && pwd)"
fi
readonly DOTFILES_DIR

# Is this command available?
command_exists() {
    command -v "$1" > /dev/null 2>&1
}
