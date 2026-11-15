#!/usr/bin/env bash
# ssh-include.sh - the one Include line that hands OpenSSH the gitignored host
# snippets in ~/.config/ssh/config.d/, and the pattern that recognises it.
#
# bin/dotfiles-link appends the line; bin/dotfiles-init reports whether it is
# there. They used to carry their own copies (and the Makefile a third, whose
# escaping never matched, so `make link` appended a fresh block every run).
#
# The pattern matches the line with leading whitespace and trailing text, so a
# hand-edited Include still counts and is not appended again.

[[ -n "${DOTFILES_SSH_INCLUDE_LOADED:-}" ]] && return 0
readonly DOTFILES_SSH_INCLUDE_LOADED=1

# shellcheck disable=SC2034 # used by the scripts that source this
readonly SSH_INCLUDE_LINE='Include ~/.config/ssh/config.d/*.conf'
# shellcheck disable=SC2034
readonly SSH_INCLUDE_RE='^[[:space:]]*Include[[:space:]]+~/\.config/ssh/config\.d/\*\.conf([[:space:]]|$)'
