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
    CHECKOUT="$TEST_TEMP_DIR/wt" doctor --only sync
    [[ "$output" != *"ot a git repository"* ]]
    # A fresh worktree branch tracks nothing — the honest state for it.
    reports ⚠ "pstream"
}

@test "a clean checkout level with upstream passes" {
    make_checkout
    doctor --only sync
    reports ✓ "evel with upstream" "$CHECKOUT"
}

@test "a dirty checkout warns" {
    make_checkout
    printf 'y\n' >> "$CHECKOUT/.config/aaa/conf"
    doctor --only sync
    reports ⚠ "ncommitted change"
}

@test "a checkout with no upstream warns that it can never sync" {
    make_checkout
    git -C "$CHECKOUT" branch -q --unset-upstream
    doctor --only sync
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
    doctor --only sync
    reports ⚠ "ehind upstream by 1" "dotfiles-update"
}

@test "a directory that is not a repository warns" {
    mkdir -p "$CHECKOUT/.config"
    doctor --only sync
    reports ⚠ "ot a git repository"
}

@test "a missing checkout is an issue and fails the run" {
    doctor --only sync
    assert_failure
    reports ✗ "not found" "$CHECKOUT"
}

# ---------- link state ----------

@test "a linked directory passes" {
    make_checkout
    mkdir -p "$TEST_HOME/.config"
    ln -s "$CHECKOUT/.config/aaa" "$TEST_HOME/.config/aaa"
    doctor --only link
    reports ✓ "~/.config/aaa"
}

@test "a broken link into the checkout is an issue that names 'make clean'" {
    make_checkout
    mkdir -p "$TEST_HOME/.config"
    ln -s "$CHECKOUT/.config/gone" "$TEST_HOME/.config/gone"
    doctor --only link
    assert_failure
    reports ✗ "~/.config/gone" "broken-ours" "make clean"
}

@test "an unlinked directory is an issue that names 'make link'" {
    make_checkout
    doctor --only link
    assert_failure
    reports ✗ "~/.config/aaa" "unlinked" "make link"
}

@test "a broken link pointing elsewhere is not reported at all" {
    make_checkout
    mkdir -p "$TEST_HOME/.config"
    ln -s "$CHECKOUT/.config/aaa" "$TEST_HOME/.config/aaa"
    ln -s /nonexistent/elsewhere "$TEST_HOME/.config/foreign"
    # link-state does emit it (broken-foreign); the table says skip.
    run env DOTFILES_DIR="$CHECKOUT" HOME="$TEST_HOME" bash "$DOTFILES_DIR/bin/link-state"
    [[ "$output" == *"broken-foreign"* ]]
    doctor --only link
    [[ "$output" != *"foreign"* ]]
}

# ---------- local config ----------

@test "an incomplete local file warns, and does not fail the run" {
    make_checkout
    mkdir -p "$TEST_HOME/.config/jj/conf.d"
    printf '[user]\nname = "Ada"\n' > "$TEST_HOME/.config/jj/conf.d/user.toml"
    doctor --only local
    assert_success
    reports ⚠ "jj-identity" "missing"
    reports ℹ "make init"
}

@test "absent local config warns and points at make init" {
    make_checkout
    doctor --only local
    assert_success
    reports ⚠ "git-identity"
    reports ℹ "dotfiles-init" "make init"
}

# ---------- tools ----------

@test "a tool that is on PATH but cannot run is an issue" {
    # Regression: zathura was installed but died with a dyld error, and every
    # existence check passed because the binary was present. On PATH is not
    # the same as working.
    make_checkout
    mkdir -p "$TEST_TEMP_DIR/brokenbin"
    printf '#!/bin/sh\nexit 1\n' > "$TEST_TEMP_DIR/brokenbin/eza"
    chmod +x "$TEST_TEMP_DIR/brokenbin/eza"
    DOCTOR_PATH="$TEST_TEMP_DIR/brokenbin:/usr/bin:/bin:/usr/sbin:/sbin" doctor --only tool
    assert_failure
    reports ✗ "eza" "fails to run"
}

@test "a missing optional tool is information, not a warning" {
    # A PATH of bare utilities, not /usr/bin: after a real `make arch` (the
    # Arch container) ouch and eza live in /usr/bin, so "missing" has to be
    # built rather than assumed.
    make_checkout
    local bare="$TEST_TEMP_DIR/bare" t
    mkdir -p "$bare"
    for t in bash sh env dirname basename readlink grep tr awk sed cat cut sort head uname id git; do
        ln -s "$(command -v "$t")" "$bare/$t"
    done
    DOCTOR_PATH="$bare" doctor --only tool
    reports ℹ "ouch" "optional"
    reports ⚠ "eza" "not installed"
}

@test "pacman is only reported on Arch" {
    # Repo bin first on PATH, like make doctor: a pacman on PATH off Arch —
    # the repo once shipped a sudo wrapper named pacman — must not register.
    make_checkout
    DOCTOR_PATH="$DOTFILES_DIR/bin:/usr/bin:/bin:/usr/sbin:/sbin" doctor --only manager
    if [[ "$(bin/platform detect)" == "arch" ]]; then
        [[ "$output" == *"pacman"* ]]
    else
        [[ "$output" != *"pacman"* ]]
    fi
}

# ---------- shell and permissions ----------

@test "zinit is checked, not Oh My Zsh" {
    make_checkout
    mkdir -p "$TEST_HOME/.local/share/zinit/zinit.git"
    doctor --only shell
    reports ✓ "zinit"
    [[ "$output" != *"Oh My Zsh"* ]]
}

@test "an ssh directory with loose permissions warns" {
    make_checkout
    mkdir -p "$TEST_HOME/.ssh"
    chmod 755 "$TEST_HOME/.ssh"
    doctor --only perms
    assert_success
    reports ⚠ "~/.ssh" "755" "700"
}

# ---------- the engine ----------

@test "the state table covers every state each classifier can emit" {
    # Drift guard, through interfaces rather than by grepping case arms:
    # every classifier's own vocabulary against the doctor's --states.
    run bash "$DOTFILES_DIR/bin/dotfiles-doctor" --states
    assert_success
    local table="$output" st missing=""
    covered() { printf '%s\n' "$table" | awk -F'\t' -v v="$1" -v s="$2" '$1 == v && $2 == s { f = 1 } END { exit !f }'; }

    for st in $(bash "$DOTFILES_DIR/bin/link-state" --states); do
        covered link "$st" || missing="$missing link/$st"
    done
    for st in $(bash "$DOTFILES_DIR/bin/dotfiles-init" --states); do
        covered local "$st" || missing="$missing local/$st"
    done
    for st in $(bash -c 'source "$1/bin/lib/git-sync.sh"
        for v in ${!GIT_SYNC_@}; do
            case "$v" in GIT_SYNC_STATE | GIT_SYNC_BEHIND | GIT_SYNC_DETAIL) continue ;; esac
            echo "${!v}"
        done' _ "$DOTFILES_DIR"); do
        covered sync "$st" || missing="$missing sync/$st"
    done
    [[ -z "$missing" ]] || { echo "unmapped:$missing"; return 1; }
}

@test "every severity in the table is one the printer knows" {
    run bash -c 'bash "$1/bin/dotfiles-doctor" --states | cut -f3 | sort -u' _ "$DOTFILES_DIR"
    assert_success
    local sev
    for sev in $output; do
        case "$sev" in pass | info | warn | fail | skip) ;; *) echo "unknown severity: $sev"; return 1 ;; esac
    done
}

@test "warnings alone do not fail the run" {
    make_checkout
    printf 'y\n' >> "$CHECKOUT/.config/aaa/conf"
    doctor --only sync
    assert_success
    assert_output --partial "1 warning(s) found"
}

@test "reaches the summary when issues are present, and exits 1" {
    doctor
    assert_failure
    assert_output --partial "Summary"
    assert_output --partial "issue(s) found"
}

@test "rejects an unknown option and an unknown --only vocabulary" {
    doctor --bogus
    assert_failure
    doctor --only nonsense
    assert_failure
    assert_output --partial "nonsense"
}
