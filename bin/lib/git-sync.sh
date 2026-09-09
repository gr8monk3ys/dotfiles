#!/usr/bin/env bash
# Shared git fast-forward state machine for bin/ scripts.
#
# One module answers "is this checkout safe to fast-forward, and did it
# work"; callers own the policy and the reporting. dotfiles-update,
# dotfiles-sync and dotfiles-doctor map the same states to different output.
#
# Usage:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "$SCRIPT_DIR/lib/git-sync.sh"
#
#   git_sync_status "$DOTFILES_DIR"           # diagnose only; fetches
#   git_sync_status "$DOTFILES_DIR" no-fetch  # diagnose against the last fetch
#   git_sync_apply  "$DOTFILES_DIR"           # diagnose, then pull when safe
#
# Both always return 0: the result is the state, not the exit code, so a
# caller running under `set -e` reads it without a guard. Both set:
#
#   GIT_SYNC_STATE   one of the states below
#   GIT_SYNC_BEHIND  commits behind upstream (0 when not applicable)
#   GIT_SYNC_DETAIL  git's stderr, or a human-readable reason ("" when none)
#
# Neither ever cd's; the caller's working directory is untouched. Neither
# suppresses git's stderr: it is captured into GIT_SYNC_DETAIL so each
# reporter can decide whether to show it.

# Guard against double-sourcing (the readonly state names would error).
[[ -n "${DOTFILES_GIT_SYNC_LOADED:-}" ]] && return 0
readonly DOTFILES_GIT_SYNC_LOADED=1

# The state vocabulary. readonly so a typo'd comparison fails loudly instead
# of silently taking the wrong branch.
readonly GIT_SYNC_MISSING_DIR="missing-dir"
readonly GIT_SYNC_NOT_A_REPO="not-a-repo"
readonly GIT_SYNC_DIRTY="dirty"
readonly GIT_SYNC_NO_UPSTREAM="no-upstream"
readonly GIT_SYNC_FETCH_FAILED="fetch-failed"
readonly GIT_SYNC_CLEAN_UPTODATE="clean-uptodate"
readonly GIT_SYNC_CLEAN_BEHIND="clean-behind"
readonly GIT_SYNC_DIVERGED="diverged"
readonly GIT_SYNC_PULLED="pulled"
readonly GIT_SYNC_PULL_FAILED="pull-failed"

_git_sync_reset() {
    GIT_SYNC_STATE=""
    GIT_SYNC_BEHIND=0
    GIT_SYNC_DETAIL=""
}

# git_sync_status <dir> [no-fetch]
#
# Classifies the checkout without mutating it. Pass "no-fetch" to compare
# against the last fetch instead of contacting the remote; callers that only
# want to report (dotfiles-doctor) use it to stay offline and fast.
git_sync_status() {
    local dir="${1:?git_sync_status: directory required}"
    local fetch_mode="${2:-fetch}"
    _git_sync_reset

    if [[ ! -d "$dir" ]]; then
        GIT_SYNC_STATE="$GIT_SYNC_MISSING_DIR"
        GIT_SYNC_DETAIL="Dotfiles directory not found: $dir"
        return 0
    fi

    # --show-prefix, not [[ -d .git ]]: in a worktree .git is a file, so the
    # old check reported every `dotfiles-worktree` checkout as "not a git
    # repository". The prefix is empty at a repo root and non-empty in a
    # subdirectory, which rejects a plain dir nested inside another repo
    # without comparing paths (and so without tripping over /tmp vs /private/tmp).
    local prefix
    if ! prefix="$(git -C "$dir" rev-parse --show-prefix 2>/dev/null)" || [[ -n "$prefix" ]]; then
        GIT_SYNC_STATE="$GIT_SYNC_NOT_A_REPO"
        GIT_SYNC_DETAIL="Not a git repository: $dir"
        return 0
    fi

    if [[ -n "$(git -C "$dir" status --porcelain)" ]]; then
        GIT_SYNC_STATE="$GIT_SYNC_DIRTY"
        GIT_SYNC_DETAIL="$(git -C "$dir" status --short)"
        return 0
    fi

    # A checkout with no upstream can never sync. Both earlier copies
    # collapsed REMOTE to LOCAL here and reported "up to date", so an
    # unsyncable checkout looked healthy forever.
    if ! git -C "$dir" rev-parse --abbrev-ref '@{u}' > /dev/null 2>&1; then
        GIT_SYNC_STATE="$GIT_SYNC_NO_UPSTREAM"
        GIT_SYNC_DETAIL="No upstream configured for $(git -C "$dir" rev-parse --abbrev-ref HEAD)"
        return 0
    fi

    if [[ "$fetch_mode" != "no-fetch" ]]; then
        local fetch_err
        if ! fetch_err="$(git -C "$dir" fetch origin 2>&1)"; then
            GIT_SYNC_STATE="$GIT_SYNC_FETCH_FAILED"
            GIT_SYNC_DETAIL="$fetch_err"
            return 0
        fi
    fi

    local local_sha remote_sha base_sha
    local_sha="$(git -C "$dir" rev-parse @)"
    remote_sha="$(git -C "$dir" rev-parse '@{u}')"
    # Unrelated histories have no merge base; treat that as diverged rather
    # than letting the failed substitution abort a `set -e` caller.
    base_sha="$(git -C "$dir" merge-base @ '@{u}' 2>/dev/null || true)"

    if [[ "$local_sha" == "$remote_sha" ]]; then
        GIT_SYNC_STATE="$GIT_SYNC_CLEAN_UPTODATE"
    elif [[ -n "$base_sha" && "$local_sha" == "$base_sha" ]]; then
        GIT_SYNC_STATE="$GIT_SYNC_CLEAN_BEHIND"
        GIT_SYNC_BEHIND="$(git -C "$dir" rev-list --count "$local_sha".."$remote_sha")"
    else
        GIT_SYNC_STATE="$GIT_SYNC_DIVERGED"
        GIT_SYNC_DETAIL="Local and remote have diverged"
    fi

    return 0
}

# git_sync_apply <dir>
#
# Diagnoses, then fast-forwards when — and only when — the state is
# clean-behind. Every other state is passed through untouched for the caller
# to interpret. Calls git_sync_status itself, so there is no ordering
# constraint and no second fetch.
git_sync_apply() {
    local dir="${1:?git_sync_apply: directory required}"

    git_sync_status "$dir"

    [[ "$GIT_SYNC_STATE" == "$GIT_SYNC_CLEAN_BEHIND" ]] || return 0

    local pull_err
    if pull_err="$(git -C "$dir" pull --rebase 2>&1)"; then
        GIT_SYNC_STATE="$GIT_SYNC_PULLED"
    else
        GIT_SYNC_STATE="$GIT_SYNC_PULL_FAILED"
    fi
    GIT_SYNC_DETAIL="$pull_err"

    return 0
}
