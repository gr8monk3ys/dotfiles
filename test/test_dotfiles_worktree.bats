#!/usr/bin/env bats
# Tests for bin/dotfiles-worktree: name sanitising, sibling path and branch
# computation, and the add/remove/list/prune verbs against a real throwaway
# git repository. Everything lives under $TEST_TEMP_DIR; HOME and git's
# global/system config are redirected so the real home dir is never read.

load test_helper/common

setup() {
    setup_test_env
    export HOME="$TEST_HOME"
    export GIT_CONFIG_GLOBAL=/dev/null
    export GIT_CONFIG_NOSYSTEM=1
    export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.invalid
    export GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.invalid

    # Worktrees are created as siblings of the repo, so the repo sits in its
    # own parent dir inside the temp tree.
    REPO="$TEST_HOME/src/dots"
    mkdir -p "$REPO"
    git -C "$REPO" init -q -b main
    echo one > "$REPO/file.txt"
    git -C "$REPO" add file.txt
    git -C "$REPO" commit -q -m init
    # Resolve symlinks (e.g. /var -> /private/var on macOS) the same way the
    # script does: git reports the physical top-level path.
    REPO="$(git -C "$REPO" rev-parse --show-toplevel)"
    PARENT="$(cd "$REPO/.." && pwd)"
    WT="$DOTFILES_DIR/bin/dotfiles-worktree"
}

teardown() {
    cleanup_test_env
}

# Run the script from inside the throwaway repo.
wt() {
    run bash -c 'cd "$1" && shift && "$@"' _ "$REPO" "$WT" "$@"
}

@test "worktree: path prints a sibling dir named <repo>-<name>" {
    wt path ghostty-pass
    assert_success
    assert_output "$PARENT/dots-ghostty-pass"
}

@test "worktree: path lowercases, turns spaces into dashes, drops unsafe chars" {
    wt path 'My Feature!$*'
    assert_success
    assert_output "$PARENT/dots-my-feature"
}

@test "worktree: path without a name fails with a hint" {
    wt path
    assert_failure
    assert_output --partial "Missing name"
}

@test "worktree: outside a git repository fails cleanly" {
    run bash -c 'cd "$1" && "$2" path x' _ "$TEST_TEMP_DIR" "$WT"
    assert_failure
    assert_output --partial "Not inside a git repository"
}

@test "worktree: no command defaults to help" {
    wt
    assert_success
    assert_output --partial "Usage: dotfiles-worktree"
}

@test "worktree: unknown command fails" {
    wt frobnicate
    assert_failure
    assert_output --partial "Unknown command: frobnicate"
}

@test "worktree: add creates ai/<name> branch from main at the sibling path" {
    wt add 'Docs Pass'
    assert_success
    assert_output --partial "path: $PARENT/dots-docs-pass"
    assert_output --partial "branch: ai/docs-pass"

    [[ -f "$PARENT/dots-docs-pass/file.txt" ]]
    [[ "$(git -C "$PARENT/dots-docs-pass" rev-parse --abbrev-ref HEAD)" == "ai/docs-pass" ]]
    [[ "$(git -C "$REPO" rev-parse ai/docs-pass)" == "$(git -C "$REPO" rev-parse main)" ]]
}

@test "worktree: add honours an explicit base ref" {
    git -C "$REPO" checkout -q -b other
    echo two > "$REPO/file.txt"
    git -C "$REPO" commit -q -am second
    git -C "$REPO" checkout -q main

    wt add feat other
    assert_success
    [[ "$(git -C "$REPO" rev-parse ai/feat)" == "$(git -C "$REPO" rev-parse other)" ]]
    [[ "$(cat "$PARENT/dots-feat/file.txt")" == "two" ]]
}

@test "worktree: add reuses an existing ai/<name> branch instead of recreating it" {
    git -C "$REPO" branch ai/reuse
    echo moved > "$REPO/file.txt"
    git -C "$REPO" commit -q -am "main moves on"

    wt add reuse
    assert_success
    # The branch still points at its original commit, not at main's new tip.
    [[ "$(git -C "$REPO" rev-parse ai/reuse)" != "$(git -C "$REPO" rev-parse main)" ]]
    [[ "$(cat "$PARENT/dots-reuse/file.txt")" == "one" ]]
}

@test "worktree: add with an unknown base fails and creates nothing" {
    wt add feat no-such-ref
    assert_failure
    assert_output --partial "Base branch/reference not found: no-such-ref"
    [[ ! -e "$PARENT/dots-feat" ]]
    run git -C "$REPO" show-ref --verify --quiet refs/heads/ai/feat
    assert_failure
}

@test "worktree: add refuses when the target path already exists" {
    mkdir -p "$PARENT/dots-taken"
    wt add taken
    assert_failure
    assert_output --partial "Target path already exists"
    run git -C "$REPO" show-ref --verify --quiet refs/heads/ai/taken
    assert_failure
}

@test "worktree: add without a name fails" {
    wt add
    assert_failure
    assert_output --partial "Missing worktree name"
}

@test "worktree: list shows a created worktree" {
    wt add listed
    assert_success
    wt list
    assert_success
    assert_output --partial "$PARENT/dots-listed"
    assert_output --partial "[ai/listed]"
}

@test "worktree: remove by name deletes the worktree but keeps the branch" {
    wt add gone
    assert_success
    wt remove gone
    assert_success
    assert_output "Removed worktree: $PARENT/dots-gone"
    [[ ! -e "$PARENT/dots-gone" ]]
    run git -C "$REPO" show-ref --verify --quiet refs/heads/ai/gone
    assert_success
}

@test "worktree: remove accepts a path as well as a name" {
    wt add bypath
    assert_success
    wt rm ../dots-bypath
    assert_success
    [[ ! -e "$PARENT/dots-bypath" ]]
}

@test "worktree: remove refuses a dirty worktree unless --force is given" {
    wt add dirty
    assert_success
    echo scratch > "$PARENT/dots-dirty/untracked.txt"

    wt remove dirty
    assert_failure
    [[ -d "$PARENT/dots-dirty" ]]

    wt remove --force dirty
    assert_success
    [[ ! -e "$PARENT/dots-dirty" ]]
}

@test "worktree: remove refuses the primary worktree" {
    wt remove .
    assert_failure
    assert_output --partial "Refusing to remove primary worktree"
    [[ -f "$REPO/file.txt" ]]
}

@test "worktree: remove of a missing worktree fails" {
    wt remove never-made
    assert_failure
    assert_output --partial "Worktree path does not exist: $PARENT/dots-never-made"
}

@test "worktree: remove --force without a target fails" {
    wt remove --force
    assert_failure
    assert_output --partial "Missing target"
}

@test "worktree: prune clears metadata for a worktree deleted by hand" {
    wt add stale
    assert_success
    rm -rf "$PARENT/dots-stale"
    [[ -d "$REPO/.git/worktrees/dots-stale" ]]

    wt prune
    assert_success
    assert_output "Pruned stale worktree metadata."
    [[ ! -e "$REPO/.git/worktrees/dots-stale" ]]
}
