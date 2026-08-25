#!/usr/bin/env bats
# Tests for bin/dotfiles-sync (unattended launchd sync)

load test_helper/common

setup() {
    setup_test_env

    # Fake osascript so notify() succeeds without macOS and so we can assert
    # on what it was told to say.
    mkdir -p "$TEST_TEMP_DIR/mockbin"
    cat > "$TEST_TEMP_DIR/mockbin/osascript" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${OSASCRIPT_LOG}"
exit 0
MOCK
    chmod +x "$TEST_TEMP_DIR/mockbin/osascript"
    export OSASCRIPT_LOG="$TEST_TEMP_DIR/osascript.log"
    : > "$OSASCRIPT_LOG"

    export PATH="$TEST_TEMP_DIR/mockbin:$PATH"
    export GIT_AUTHOR_NAME="Test" GIT_AUTHOR_EMAIL="test@example.com"
    export GIT_COMMITTER_NAME="Test" GIT_COMMITTER_EMAIL="test@example.com"
}

teardown() {
    cleanup_test_env
}

# Sets up a bare "remote" repo and a working clone at $TEST_HOME/.dotfiles
# with one commit, pushed and tracked on branch "main".
make_synced_repo() {
    local remote="$TEST_TEMP_DIR/remote.git"
    local work="$TEST_HOME/.dotfiles"
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

run_sync() {
    run env HOME="$TEST_HOME" DOTFILES_DIR="$TEST_HOME/.dotfiles" \
        OSASCRIPT_LOG="$OSASCRIPT_LOG" PATH="$PATH" \
        bash "$DOTFILES_DIR/bin/dotfiles-sync"
}

@test "dotfiles-sync script exists and is executable" {
    [[ -f "$DOTFILES_DIR/bin/dotfiles-sync" ]]
    [[ -x "$DOTFILES_DIR/bin/dotfiles-sync" ]]
}

@test "dotfiles-sync errors when dotfiles directory is missing" {
    run env HOME="$TEST_HOME" DOTFILES_DIR="$TEST_HOME/nonexistent" \
        OSASCRIPT_LOG="$OSASCRIPT_LOG" PATH="$PATH" \
        bash "$DOTFILES_DIR/bin/dotfiles-sync"
    assert_failure
    grep -q "not found" "$OSASCRIPT_LOG"
}

@test "dotfiles-sync errors when directory is not a git repo" {
    mkdir -p "$TEST_HOME/.dotfiles"
    run_sync
    assert_failure
    grep -q "Not a git repository" "$OSASCRIPT_LOG"
}

@test "dotfiles-sync skips silently when there are uncommitted changes" {
    make_synced_repo
    echo "dirty" >> "$TEST_HOME/.dotfiles/seed.txt"

    run_sync
    assert_success
    grep -q "Uncommitted changes present" "$OSASCRIPT_LOG"
}

@test "dotfiles-sync is silent and succeeds when already up to date" {
    make_synced_repo

    run_sync
    assert_success
    [[ ! -s "$OSASCRIPT_LOG" ]]
}

@test "dotfiles-sync pulls and notifies when behind the remote" {
    make_synced_repo
    local remote="$TEST_TEMP_DIR/remote.git"

    # A second clone pushes a new commit that the first clone doesn't have.
    local other="$TEST_TEMP_DIR/other-clone"
    git clone -q -b main "$remote" "$other"
    (
        cd "$other"
        echo "update" > new-file.txt
        git add new-file.txt
        git commit -q -m "add new file"
        git push -q origin main
    )

    run_sync
    assert_success
    grep -q "Pulled 1 commit(s) successfully" "$OSASCRIPT_LOG"
    [[ -f "$TEST_HOME/.dotfiles/new-file.txt" ]]
}

@test "dotfiles-sync warns and fails when local and remote have diverged" {
    make_synced_repo
    local remote="$TEST_TEMP_DIR/remote.git"

    # Push a divergent commit from another clone...
    local other="$TEST_TEMP_DIR/other-clone"
    git clone -q -b main "$remote" "$other"
    (
        cd "$other"
        echo "remote change" > remote-file.txt
        git add remote-file.txt
        git commit -q -m "remote change"
        git push -q origin main
    )

    # ...while the original clone makes its own unpushed local commit.
    (
        cd "$TEST_HOME/.dotfiles"
        echo "local change" > local-file.txt
        git add local-file.txt
        git commit -q -m "local change"
    )

    run_sync
    assert_failure
    grep -q "Local and remote have diverged" "$OSASCRIPT_LOG"
    # Diverged state must not be silently rewritten by a pull.
    [[ ! -f "$TEST_HOME/.dotfiles/remote-file.txt" ]]
}

@test "dotfiles-sync errors cleanly when the remote cannot be fetched" {
    make_synced_repo
    (
        cd "$TEST_HOME/.dotfiles"
        git remote set-url origin "$TEST_TEMP_DIR/does-not-exist.git"
    )

    run_sync
    assert_failure
    grep -q "Failed to fetch from remote" "$OSASCRIPT_LOG"
}
