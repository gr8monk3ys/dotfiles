#!/usr/bin/env bats
# bin/gh-merge-local-green - merges only when the check passes on the PR head
# merged with its base. A real origin holds the base and the PR head; a stub
# `gh` answers `pr view` and logs every merge call.

load test_helper/common

GMLG="$DOTFILES_DIR/bin/gh-merge-local-green"

setup() {
    setup_test_env
    ORIGIN="$TEST_TEMP_DIR/origin.git"
    CLONE="$TEST_TEMP_DIR/clone"
    GH_LOG="$TEST_TEMP_DIR/gh.log"
    DRAFT=false
    export GH_LOG DRAFT GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t

    git init -q --bare -b main "$ORIGIN"
    git clone -q "$ORIGIN" "$CLONE" 2>/dev/null
    cd "$CLONE"
    echo base > file && git add file && git commit -qm base && git push -q origin main
    git checkout -qb feature
    echo feature > other && git add other && git commit -qm feature
    HEAD_SHA=$(git rev-parse HEAD)
    git push -q origin "HEAD:refs/pull/7/head"
    git checkout -q main
    export HEAD_SHA

    STUB_BIN="$TEST_TEMP_DIR/bin"
    mkdir -p "$STUB_BIN"
    cat > "$STUB_BIN/gh" <<'STUB'
#!/usr/bin/env bash
case "$1 $2" in
    "pr view") printf '%s\tmain\t%s\n' "$HEAD_SHA" "$DRAFT" ;;
    "pr merge") printf '%s\n' "$*" >> "$GH_LOG" ;;
esac
STUB
    chmod +x "$STUB_BIN/gh"
    export PATH="$STUB_BIN:$PATH"
}

teardown() { cleanup_test_env; }

@test "merges the exact head commit when the check passes on head plus base" {
    run "$GMLG" 7 -R o/r -C "$CLONE" -- test -f other
    [ "$status" -eq 0 ]
    [ "$(cat "$GH_LOG")" = "pr merge 7 -R o/r --match-head-commit $HEAD_SHA --squash --delete-branch" ]
}

@test "runs the check against the current base tip, not the PR's fork point" {
    echo newer > later && git add later && git commit -qm later && git push -q origin main
    run "$GMLG" 7 -R o/r -C "$CLONE" -- test -f later
    [ "$status" -eq 0 ]
}

@test "does not merge when the check fails" {
    run "$GMLG" 7 -R o/r -C "$CLONE" -- false
    [ "$status" -ne 0 ]
    [[ "$output" == *"check failed"* ]]
    [ ! -e "$GH_LOG" ]
}

@test "does not merge a head that conflicts with its base" {
    echo clash > other && git add other && git commit -qm clash && git push -q origin main
    run "$GMLG" 7 -R o/r -C "$CLONE" -- true
    [ "$status" -ne 0 ]
    [[ "$output" == *"does not merge cleanly"* ]]
    [ ! -e "$GH_LOG" ]
}

@test "does not merge a draft" {
    DRAFT=true run "$GMLG" 7 -R o/r -C "$CLONE" -- true
    [ "$status" -ne 0 ]
    [ ! -e "$GH_LOG" ]
}

@test "refuses to run without a check command" {
    run "$GMLG" 7 -R o/r -C "$CLONE"
    [ "$status" -ne 0 ]
    [ ! -e "$GH_LOG" ]
}

@test "leaves no worktree behind" {
    run "$GMLG" 7 -R o/r -C "$CLONE" -- true
    [ "$(git -C "$CLONE" worktree list | wc -l)" -eq 1 ]
}
