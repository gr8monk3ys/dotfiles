#!/usr/bin/env bats
# Tests for bin/lib/git-sync.sh (shared git fast-forward state machine).
#
# These exercise the module through its own interface. The behaviour-level
# coverage of the two reporters lives in test_dotfiles_sync.bats.

load test_helper/common

setup() {
    setup_test_env
    export GIT_AUTHOR_NAME="Test" GIT_AUTHOR_EMAIL="test@example.com"
    export GIT_COMMITTER_NAME="Test" GIT_COMMITTER_EMAIL="test@example.com"
}

teardown() {
    cleanup_test_env
}

# A bare "remote" plus a working clone with one commit, pushed and tracked.
make_synced_repo() {
    local remote="$TEST_TEMP_DIR/remote.git"
    local work="${1:-$TEST_HOME/repo}"
    git init -q --bare "$remote"
    git init -q -b main "$work"
    (
        cd "$work"
        git remote add origin "$remote"
        echo "seed" > seed.txt
        git add seed.txt
        git commit -q -m "init"
        git push -q -u origin main
    )
}

# Push a commit from a second clone so the first falls behind.
push_remote_commit() {
    local other="$TEST_TEMP_DIR/other-clone"
    rm -rf "$other"
    git clone -q -b main "$TEST_TEMP_DIR/remote.git" "$other"
    (
        cd "$other"
        echo "update" > new-file.txt
        git add new-file.txt
        git commit -q -m "add new file"
        git push -q origin main
    )
}

# Run one git_sync_* call in a fresh bash and print "<state>|<behind>".
sync_state() {
    run env GIT_AUTHOR_NAME="Test" GIT_AUTHOR_EMAIL="test@example.com" \
        GIT_COMMITTER_NAME="Test" GIT_COMMITTER_EMAIL="test@example.com" \
        bash -c '
            set -euo pipefail
            source "$1/bin/lib/git-sync.sh"
            "$2" "$3" ${4:+"$4"}
            printf "%s|%s\n" "$GIT_SYNC_STATE" "$GIT_SYNC_BEHIND"
        ' _ "$DOTFILES_DIR" "$@"
}

@test "git-sync.sh exists and is syntactically valid" {
    [[ -f "$DOTFILES_DIR/bin/lib/git-sync.sh" ]]
    run bash -n "$DOTFILES_DIR/bin/lib/git-sync.sh"
    assert_success
}

@test "status reports missing-dir when the directory does not exist" {
    sync_state git_sync_status "$TEST_HOME/nonexistent"
    assert_success
    assert_output "missing-dir|0"
}

@test "status reports not-a-repo for a plain directory" {
    mkdir -p "$TEST_HOME/plain"
    sync_state git_sync_status "$TEST_HOME/plain"
    assert_success
    assert_output "not-a-repo|0"
}

@test "status reports not-a-repo for a subdirectory of a repo" {
    make_synced_repo
    mkdir -p "$TEST_HOME/repo/sub"
    sync_state git_sync_status "$TEST_HOME/repo/sub"
    assert_success
    assert_output "not-a-repo|0"
}

@test "status reports dirty when the tree has uncommitted changes" {
    make_synced_repo
    echo "dirty" >> "$TEST_HOME/repo/seed.txt"
    sync_state git_sync_status "$TEST_HOME/repo"
    assert_success
    assert_output "dirty|0"
}

@test "status reports no-upstream when the branch tracks nothing" {
    git init -q -b main "$TEST_HOME/lonely"
    (
        cd "$TEST_HOME/lonely"
        echo "seed" > seed.txt
        git add seed.txt
        git commit -q -m "init"
    )
    sync_state git_sync_status "$TEST_HOME/lonely"
    assert_success
    assert_output "no-upstream|0"
}

@test "status reports clean-uptodate when level with the remote" {
    make_synced_repo
    sync_state git_sync_status "$TEST_HOME/repo"
    assert_success
    assert_output "clean-uptodate|0"
}

@test "status reports clean-behind with a commit count" {
    make_synced_repo
    push_remote_commit
    sync_state git_sync_status "$TEST_HOME/repo"
    assert_success
    assert_output "clean-behind|1"
}

@test "status reports diverged when both sides have moved" {
    make_synced_repo
    push_remote_commit
    (
        cd "$TEST_HOME/repo"
        echo "local change" > local-file.txt
        git add local-file.txt
        git commit -q -m "local change"
    )
    sync_state git_sync_status "$TEST_HOME/repo"
    assert_success
    assert_output "diverged|0"
}

@test "status reports fetch-failed when the remote is unreachable" {
    make_synced_repo
    git -C "$TEST_HOME/repo" remote set-url origin "$TEST_TEMP_DIR/does-not-exist.git"
    sync_state git_sync_status "$TEST_HOME/repo"
    assert_success
    assert_output "fetch-failed|0"
}

@test "status treats a worktree as a repository, not not-a-repo" {
    # Regression: [[ -d .git ]] was false in a worktree, so every checkout
    # made by bin/dotfiles-worktree reported "Not a git repository".
    make_synced_repo
    git -C "$TEST_HOME/repo" worktree add -q --detach "$TEST_TEMP_DIR/wt" HEAD
    sync_state git_sync_status "$TEST_TEMP_DIR/wt"
    assert_success
    [[ "$output" != "not-a-repo|0" ]]
}

@test "status no-fetch does not contact the remote" {
    make_synced_repo
    # An unreachable remote would be fetch-failed if a fetch were attempted.
    git -C "$TEST_HOME/repo" remote set-url origin "$TEST_TEMP_DIR/does-not-exist.git"
    sync_state git_sync_status "$TEST_HOME/repo" no-fetch
    assert_success
    assert_output "clean-uptodate|0"
}

@test "status does not change the caller's working directory" {
    make_synced_repo
    run bash -c '
        set -euo pipefail
        source "$1/bin/lib/git-sync.sh"
        before="$PWD"
        git_sync_status "$2" > /dev/null
        [[ "$PWD" == "$before" ]]
    ' _ "$DOTFILES_DIR" "$TEST_HOME/repo"
    assert_success
}

@test "apply pulls when behind and reports pulled with the count" {
    make_synced_repo
    push_remote_commit
    sync_state git_sync_apply "$TEST_HOME/repo"
    assert_success
    assert_output "pulled|1"
    [[ -f "$TEST_HOME/repo/new-file.txt" ]]
}

@test "apply leaves a diverged checkout untouched" {
    make_synced_repo
    push_remote_commit
    (
        cd "$TEST_HOME/repo"
        echo "local change" > local-file.txt
        git add local-file.txt
        git commit -q -m "local change"
    )
    sync_state git_sync_apply "$TEST_HOME/repo"
    assert_success
    assert_output "diverged|0"
    [[ ! -f "$TEST_HOME/repo/new-file.txt" ]]
}

@test "apply leaves a dirty checkout untouched" {
    make_synced_repo
    push_remote_commit
    echo "dirty" >> "$TEST_HOME/repo/seed.txt"
    sync_state git_sync_apply "$TEST_HOME/repo"
    assert_success
    assert_output "dirty|0"
    [[ ! -f "$TEST_HOME/repo/new-file.txt" ]]
}
