#!/usr/bin/env bash
# Shared preamble for bin/ scripts: checkout resolution, the command-presence
# predicate, the truthiness rule for boolean knobs, and root escalation.
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

# Is the boolean knob named $1 on? The one rule for every boolean environment
# knob: `1` or `true` is on; unset, empty, `0` or `false` is off. Before this,
# install-kind treated any non-empty value as on (so STRICT_PACKAGES=0 was
# strict) while install.sh compared against "1" (so STRICT_PACKAGES=true was
# not) — one variable meant two things depending on who read it.
#
# Takes the variable's *name* so the warning can say which knob is wrong.
# Anything else is a typo: reported, and read as off.
knob_on() {
    local name="$1" value="${!1:-}"
    case "$value" in
        1 | true) return 0 ;;
        "" | 0 | false) return 1 ;;
    esac
    echo "warning: $name='$value' is not 1/true or 0/false; treating it as off" >&2
    return 1
}

# Run a command as root: directly when already root, through sudo otherwise.
# This replaces bin/pacman, a wrapper that shadowed the real pacman on PATH to
# add sudo and so needed a self-recursion guard, a doctor special case and a
# regression test of its own. Escalation is the caller's decision, made at the
# call site. Asks `id -u` rather than $EUID so a test can stand in for root.
as_root() {
    if [[ "$(id -u)" -eq 0 ]]; then
        "$@"
    else
        sudo "$@"
    fi
}
