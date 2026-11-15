#!/usr/bin/env bats
# bin/gh-merge-green - merges only when the PR head has checks and all pass.
# A stub `gh` answers from files and logs every merge call.

load test_helper/common

GMG="$DOTFILES_DIR/bin/gh-merge-green"
SHA=0123456789abcdef0123456789abcdef01234567

setup() {
    setup_test_env
    STUB_BIN="$TEST_TEMP_DIR/bin"
    GH_LOG="$TEST_TEMP_DIR/gh.log"
    N_CHECKS=2
    WATCH_RC=0
    export GH_LOG N_CHECKS WATCH_RC SHA
    mkdir -p "$STUB_BIN"
    cat > "$STUB_BIN/gh" <<'STUB'
#!/usr/bin/env bash
case "$1 $2 $*" in
    "pr view"*) echo "$SHA" ;;
    "pr checks"*--json*) echo "$N_CHECKS" ;;
    "pr checks"*--watch*) exit "$WATCH_RC" ;;
    "pr merge"*) printf '%s\n' "$*" >> "$GH_LOG" ;;
esac
STUB
    chmod +x "$STUB_BIN/gh"
    export PATH="$STUB_BIN:$PATH"
}

teardown() { cleanup_test_env; }

@test "merges the exact head commit once every check passes" {
    run "$GMG" 7 -R o/r
    [ "$status" -eq 0 ]
    [ "$(cat "$GH_LOG")" = "pr merge 7 -R o/r --match-head-commit $SHA --squash --delete-branch" ]
}

@test "refuses a head with no checks" {
    N_CHECKS=0 run "$GMG" 7
    [ "$status" -eq 1 ]
    [[ "$output" == *"has no checks"* ]]
    [ ! -e "$GH_LOG" ]
}

@test "refuses when a check fails" {
    WATCH_RC=1 run "$GMG" 7
    [ "$status" -eq 1 ]
    [[ "$output" == *"did not all pass"* ]]
    [ ! -e "$GH_LOG" ]
}

@test "passes merge flags through" {
    run "$GMG" 7 --rebase
    [ "$status" -eq 0 ]
    [ "$(cat "$GH_LOG")" = "pr merge 7 --match-head-commit $SHA --rebase" ]
}

@test "needs a PR argument" {
    run "$GMG"
    [ "$status" -eq 1 ]
    [[ "$output" == *usage* ]]
}
