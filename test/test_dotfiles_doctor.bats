#!/usr/bin/env bats
# Tests for bin/dotfiles-doctor.
#
# The doctor runs for real against a fixture: a git checkout with a bare
# "remote", a fixture HOME with its own XDG_CONFIG_HOME, and a PATH with
# nothing on it but the system directories. The assertions are on what it
# prints — the severity glyph and the subject — because that is the interface
# a person reads. The classification itself is tested in each classifier's own
# file (test_git_sync.bats, test_link_state.bats, test_dotfiles_init.bats);
# what is tested here is that the doctor reports each state at the right
# severity.

load test_helper/common

setup() {
    setup_test_env
    export GIT_AUTHOR_NAME="Test" GIT_AUTHOR_EMAIL="test@example.com"
    export GIT_COMMITTER_NAME="Test" GIT_COMMITTER_EMAIL="test@example.com"
    # The checkout under inspection. Not DOTFILES_DIR: the helper already uses
    # that name for the checkout the tests (and the doctor) run from.
    export CHECKOUT="$TEST_TEMP_DIR/checkout"
    export REMOTE="$TEST_TEMP_DIR/remote.git"
}

teardown() {
    cleanup_test_env
}

# A checkout shipping one .config directory, pushed to a bare remote and
# tracking it — so it starts out clean-uptodate.
make_checkout() {
    git init -q --bare "$REMOTE"
    git init -q -b main "$CHECKOUT"
    mkdir -p "$CHECKOUT/.config/aaa"
    printf 'x\n' > "$CHECKOUT/.config/aaa/conf"
    (
        cd "$CHECKOUT"
        git remote add origin "$REMOTE"
        git add .config
        git commit -q -m init
        git push -q -u origin main
    )
}

# Run the doctor against the fixture and strip colour, so assertions can
# anchor on the glyph at the start of a line. Everything that could leak the
# real machine into the result is pinned or unset.
doctor() {
    run env -u ZDOTDIR -u XDG_DATA_HOME \
        HOME="$TEST_HOME" XDG_CONFIG_HOME="$TEST_HOME/.config" \
        GIT_CONFIG_NOSYSTEM=1 DOTFILES_DIR="$CHECKOUT" \
        PATH="${DOCTOR_PATH:-/usr/bin:/bin:/usr/sbin:/sbin}" \
        bash "$DOTFILES_DIR/bin/dotfiles-doctor" "$@"
    output="$(printf '%s\n' "$output" | sed $'s/\033\\[[0-9;]*m//g')"
}

# Assert some line starting with this glyph mentions every given fragment.
#   reports ⚠ "no upstream"
reports() {
    local glyph="$1" line frag ok
    shift
    while IFS= read -r line; do
        [[ "$line" == "$glyph "* ]] || continue
        ok=1
        for frag in "$@"; do
            [[ "$line" == *"$frag"* ]] || { ok=0; break; }
        done
        [[ "$ok" -eq 1 ]] && return 0
    done <<< "$output"
    echo "no '$glyph' line mentioning: $*"
    echo "--- output ---"
    echo "$output"
    return 1
}

# ---------- sync state ----------

@test "a worktree checkout is reported as a repository, not 'not a git repository'" {
    # Regression: doctor probed `[[ -d .git ]]`, and in a worktree .git is a
    # file — so every dotfiles-worktree checkout was "Not a git repository".
    make_checkout
    git -C "$CHECKOUT" worktree add -q -b wt "$TEST_TEMP_DIR/wt"
    CHECKOUT="$TEST_TEMP_DIR/wt" doctor
    [[ "$output" != *"ot a git repository"* ]]
    # A fresh worktree branch tracks nothing — the honest state for it.
    reports ⚠ "pstream"
}

@test "a clean checkout level with upstream passes" {
    make_checkout
    doctor
    reports ✓ "evel with upstream" "$CHECKOUT"
}

@test "a dirty checkout warns" {
    make_checkout
    printf 'y\n' >> "$CHECKOUT/.config/aaa/conf"
    doctor
    reports ⚠ "ncommitted change"
}

@test "a checkout with no upstream warns that it can never sync" {
    make_checkout
    git -C "$CHECKOUT" branch -q --unset-upstream
    doctor
    reports ⚠ "never sync"
}

@test "a checkout behind its upstream warns and names the fix" {
    make_checkout
    git clone -q "$REMOTE" "$TEST_TEMP_DIR/other"
    (
        cd "$TEST_TEMP_DIR/other"
        echo more > more.txt
        git add more.txt
        git commit -q -m more
        git push -q origin main
    )
    git -C "$CHECKOUT" fetch -q origin
    doctor
    reports ⚠ "ehind upstream by 1" "dotfiles-update"
}

@test "a directory that is not a repository warns" {
    mkdir -p "$CHECKOUT/.config"
    doctor
    reports ⚠ "ot a git repository"
}

@test "a missing checkout is an issue and fails the run" {
    doctor
    assert_failure
    reports ✗ "not found" "$CHECKOUT"
}
