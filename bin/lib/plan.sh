#!/usr/bin/env bash
# plan.sh - the dry-run / apply engine shared by every script that changes a
# machine only when asked (omarchy/setup.sh, bin/claude-sync,
# bin/hermes-offline, bin/dotfiles-link).
#
# Each of those scripts used to carry its own copy of these helpers, and the
# copies drifted: three backup naming schemes, and one copy whose
# second-resolution backup name collided when two steps ran in the same
# second. They live here so a fix lands once.
#
# Interface:
#   APPLY=0|1        set by the caller before any step runs (0 = dry run)
#   PLAN_NAME        prefix for die(); defaults to the script's basename
#   ok|note|skip|warn <msg>      report a line
#   die <msg>                    report and exit 1
#   change <msg>     count a change and announce it; returns 0 only under
#                    APPLY=1, so callers write `change "..." && do_it`
#                    (or `if change ...; then ...`)
#   plan_backup <path>           print a backup name for <path> that does
#                    not exist yet: <path>.dotfiles-bak, then
#                    <path>.dotfiles-bak.<epoch>[.n]
#   plan_link <src> <dest>       make <dest> a symlink to <src>; see below
#   plan_summary                 the closing line; reads CHANGES
#
# plan_link's rules, in order:
#   - already a link to <src>: ok
#   - a link into this checkout (a path the dotfiles moved): replaced, no
#     backup, since it was ours
#   - a regular file or dir identical to <src>: replaced, no backup
#   - anything else: moved to plan_backup's name, then linked

[[ -n "${DOTFILES_PLAN_LOADED:-}" ]] && return 0
readonly DOTFILES_PLAN_LOADED=1

APPLY="${APPLY:-0}"
CHANGES=0
PLAN_NAME="${PLAN_NAME:-$(basename "$0")}"

ok() { printf '  ok      %s\n' "$*"; }
note() { printf '  note    %s\n' "$*"; }
skip() { printf '  skip    %s\n' "$*"; }
warn() { printf '  WARN    %s\n' "$*" >&2; }
die() { printf '%s: %s\n' "$PLAN_NAME" "$*" >&2; exit 1; }

change() {
    CHANGES=$((CHANGES + 1))
    if ((APPLY)); then
        printf '  do      %s\n' "$*"
        return 0
    fi
    printf '  would   %s\n' "$*"
    return 1
}

plan_backup() {
    local path="$1" candidate n=0
    candidate="$path.dotfiles-bak"
    if [[ -e "$candidate" || -L "$candidate" ]]; then
        candidate="$path.dotfiles-bak.$(date +%s)"
        while [[ -e "$candidate" || -L "$candidate" ]]; do
            n=$((n + 1))
            candidate="$path.dotfiles-bak.$(date +%s).$n"
        done
    fi
    printf '%s\n' "$candidate"
}

plan_link() {
    local src="$1" dest="$2" target backup
    if [[ -L "$dest" ]]; then
        target="$(readlink "$dest")"
        if [[ "$target" == "$src" ]]; then
            ok "$dest"
            return 0
        fi
        if [[ -n "${DOTFILES_DIR:-}" && "$target" == "$DOTFILES_DIR"/* ]]; then
            change "repoint $dest -> $src (was $target)" || return 0
            rm "$dest"
            ln -s "$src" "$dest"
            return 0
        fi
    fi
    if [[ ! -L "$dest" ]] && { { [[ -f "$dest" ]] && cmp -s "$src" "$dest"; } ||
        { [[ -d "$dest" ]] && diff -rq "$src" "$dest" > /dev/null 2>&1; }; }; then
        change "replace identical copy $dest with a link" || return 0
        rm -rf "$dest"
    elif [[ -e "$dest" || -L "$dest" ]]; then
        backup="$(plan_backup "$dest")"
        change "move $dest -> $backup, then link it" || return 0
        mv "$dest" "$backup"
    else
        change "link $dest -> $src" || return 0
    fi
    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
}

plan_summary() {
    if ((CHANGES == 0)); then
        echo "Everything already in place."
    elif ((!APPLY)); then
        echo "$CHANGES change(s) pending; run with --apply."
    fi
}
