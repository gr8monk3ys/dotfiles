#!/usr/bin/env bats
# Tests for bin/dotfiles-init.
#
# Every run happens against a fixture HOME with its own XDG_CONFIG_HOME, so the
# real ~/.gitconfig, ~/.config/jj and ~/.ssh are never read and never written —
# the subject of these tests is a machine that does not exist yet.
#
# GIT_CONFIG_NOSYSTEM is set on every run: /etc/gitconfig is real on the
# machine running the tests, and an identity there would make a fixture that
# has none look configured.

load test_helper/common

setup() {
    setup_test_env
    export FIXTURE_CONFIG="$TEST_HOME/.config"
    mkdir -p "$FIXTURE_CONFIG"
}

teardown() {
    cleanup_test_env
}

# Run dotfiles-init against the fixture HOME. stdin is /dev/null so the
# non-interactive path is the one under test — a prompt would hang the suite.
run_init() {
    run env HOME="$TEST_HOME" XDG_CONFIG_HOME="$FIXTURE_CONFIG" \
        GIT_CONFIG_NOSYSTEM=1 \
        GIT_USER_NAME="${GIT_USER_NAME:-}" GIT_USER_EMAIL="${GIT_USER_EMAIL:-}" \
        GIT_SIGNING_KEY="${GIT_SIGNING_KEY:-}" \
        JJ_USER_NAME="${JJ_USER_NAME:-}" JJ_USER_EMAIL="${JJ_USER_EMAIL:-}" \
        bash "$DOTFILES_DIR/bin/dotfiles-init" "$@" < /dev/null
}

git_local() { echo "$FIXTURE_CONFIG/git/config.local"; }
jj_local() { echo "$FIXTURE_CONFIG/jj/conf.d/user.toml"; }

# Assertions about what git tracks need a repository git can actually open.
# The Docker image copies the checkout in, so when it was made from a git
# worktree its `.git` is a pointer file naming a gitdir that is not there.
require_git_repo() {
    git -C "$DOTFILES_DIR" rev-parse --git-dir > /dev/null 2>&1 \
        || skip "checkout is not a git repository git can open here"
}

# The state a subject is reported in, from the --status rows.
state_of() {
    local subject="$1" line
    line="$(printf '%s\n' "$output" | grep "	$subject	" || true)"
    printf '%s' "${line%%	*}"
}

# Make git's include chain live, the way it is on a checkout whose config sits
# at a path git actually reads. Without this the fixture reproduces the
# repository's current layout, where .config/git/.gitconfig is read by nothing.
link_git_include_chain() {
    mkdir -p "$FIXTURE_CONFIG/git"
    {
        echo "[include]"
        printf '\tpath = %s\n' "$(git_local)"
    } > "$FIXTURE_CONFIG/git/config"
}

# ---------- interface ----------

@test "dotfiles-init --help succeeds and documents the modes" {
    run_init --help
    assert_success
    assert_output --partial "--check"
    assert_output --partial "--status"
    assert_output --partial "GIT_USER_NAME"
}

@test "dotfiles-init rejects an unknown option" {
    run_init --not-an-option
    [ "$status" -eq 2 ]
    assert_output --partial "Unknown option"
}

@test "dotfiles-init --states lists the state vocabulary" {
    run_init --states
    assert_success
    assert_output --partial "configured"
    assert_output --partial "unconfigured"
    assert_output --partial "incomplete"
    assert_output --partial "ineffective"
    assert_output --partial "optional"
}

@test "dotfiles-init --status emits one row per subject" {
    run_init --status
    assert_success
    [ "$(printf '%s\n' "$output" | grep -c '	')" -eq 4 ]
    assert_output --partial "git-identity"
    assert_output --partial "jj-identity"
    assert_output --partial "ssh-include"
    assert_output --partial "ssh-hosts"
}

# ---------- it detects an unconfigured machine ----------

@test "a fresh fixture reports git and jj identity as unconfigured" {
    run_init --status
    assert_success
    [ "$(state_of git-identity)" = "unconfigured" ]
    [ "$(state_of jj-identity)" = "unconfigured" ]
}

@test "a fresh fixture reports the SSH include as unconfigured and hosts as optional" {
    run_init --status
    assert_success
    [ "$(state_of ssh-include)" = "unconfigured" ]
    [ "$(state_of ssh-hosts)" = "optional" ]
}

@test "--check exits non-zero on a fresh fixture" {
    run_init --check
    assert_failure
    assert_output --partial "git-identity"
}

@test "an SSH config carrying the Include line reports ssh-include configured" {
    mkdir -p "$TEST_HOME/.ssh"
    echo 'Include ~/.config/ssh/config.d/*.conf' > "$TEST_HOME/.ssh/config"
    run_init --status
    [ "$(state_of ssh-include)" = "configured" ]
}

@test "a host snippet reports ssh-hosts configured" {
    mkdir -p "$FIXTURE_CONFIG/ssh/config.d"
    echo "Host example" > "$FIXTURE_CONFIG/ssh/config.d/example.conf"
    run_init --status
    [ "$(state_of ssh-hosts)" = "configured" ]
}

# ---------- it configures, non-interactively ----------

@test "flags configure git and jj without a prompt" {
    run_init --git-name "Ada Lovelace" --git-email ada@example.com
    assert_success
    [ -f "$(git_local)" ]
    [ -f "$(jj_local)" ]
    run git -C "$TEST_HOME" config --file "$(git_local)" user.name
    assert_output "Ada Lovelace"
    run git -C "$TEST_HOME" config --file "$(git_local)" user.email
    assert_output "ada@example.com"
    run grep -F 'email = "ada@example.com"' "$(jj_local)"
    assert_success
}

@test "environment variables configure git and jj without a prompt" {
    GIT_USER_NAME="Grace Hopper" GIT_USER_EMAIL=grace@example.com run_init
    assert_success
    run git -C "$TEST_HOME" config --file "$(git_local)" user.name
    assert_output "Grace Hopper"
    run grep -F 'name = "Grace Hopper"' "$(jj_local)"
    assert_success
}

@test "a flag beats the environment variable" {
    GIT_USER_EMAIL=env@example.com run_init --git-name Ada --git-email flag@example.com
    assert_success
    run git -C "$TEST_HOME" config --file "$(git_local)" user.email
    assert_output "flag@example.com"
}

@test "jj identity defaults to the git identity, and its own flags override" {
    run_init --git-name Ada --git-email ada@example.com --jj-email jj@example.com
    assert_success
    run grep -F 'name = "Ada"' "$(jj_local)"
    assert_success
    run grep -F 'email = "jj@example.com"' "$(jj_local)"
    assert_success
}

@test "a signing key is written, and without one commit signing is turned off" {
    run_init --git-name Ada --git-email ada@example.com --git-signing-key DEADBEEF
    assert_success
    run git -C "$TEST_HOME" config --file "$(git_local)" user.signingkey
    assert_output "DEADBEEF"
    run git -C "$TEST_HOME" config --file "$(git_local)" commit.gpgsign
    assert_failure
}

@test "without a signing key it disables commit signing, which the tracked config turns on" {
    run_init --git-name Ada --git-email ada@example.com
    assert_success
    run git -C "$TEST_HOME" config --file "$(git_local)" commit.gpgsign
    assert_output "false"
}

@test "a missing value with no terminal fails naming the flag and the variable" {
    run_init
    assert_failure
    assert_output --partial "--git-name"
    assert_output --partial "GIT_USER_NAME"
    [ ! -f "$(git_local)" ]
}

@test "the local files are written from their tracked templates" {
    run_init --git-name Ada --git-email ada@example.com
    assert_success
    run grep -F "Copy this file to config.local" "$(git_local)"
    assert_success
    run grep -F "jj reads every *.toml in this directory" "$(jj_local)"
    assert_success
}

# ---------- it is idempotent, and never clobbers ----------

@test "a second run changes nothing" {
    run_init --git-name Ada --git-email ada@example.com
    assert_success
    local git_before jj_before
    git_before="$(cat "$(git_local)")"
    jj_before="$(cat "$(jj_local)")"

    run_init --git-name Ada --git-email ada@example.com
    assert_success
    [ "$(cat "$(git_local)")" = "$git_before" ]
    [ "$(cat "$(jj_local)")" = "$jj_before" ]
}

@test "a second run with different values still changes nothing" {
    run_init --git-name Ada --git-email ada@example.com
    assert_success
    run_init --git-name Somebody --git-email else@example.com
    assert_success
    run git -C "$TEST_HOME" config --file "$(git_local)" user.email
    assert_output "ada@example.com"
}

@test "an existing config.local is left byte-for-byte alone" {
    mkdir -p "$FIXTURE_CONFIG/git"
    printf '# hand written\n[user]\n\tname = Mine\n\temail = mine@example.com\n' > "$(git_local)"
    local before
    before="$(cat "$(git_local)")"

    run_init --git-name Ada --git-email ada@example.com
    assert_success
    assert_output --partial "left untouched"
    [ "$(cat "$(git_local)")" = "$before" ]
}

@test "an existing jj user.toml is left byte-for-byte alone" {
    mkdir -p "$FIXTURE_CONFIG/jj/conf.d"
    printf '[user]\nname = "Mine"\nemail = "mine@example.com"\n' > "$(jj_local)"
    local before
    before="$(cat "$(jj_local)")"

    run_init --git-name Ada --git-email ada@example.com
    assert_success
    [ "$(cat "$(jj_local)")" = "$before" ]
}

@test "an incomplete local file is reported, not patched" {
    mkdir -p "$FIXTURE_CONFIG/jj/conf.d"
    printf '[user]\nname = "Mine"\n' > "$(jj_local)"
    run_init --status
    [ "$(state_of jj-identity)" = "incomplete" ]

    run_init --git-name Ada --git-email ada@example.com
    assert_success
    run grep -c . "$(jj_local)"
    assert_output "2"
}

# ---------- --check exit codes ----------

@test "--check passes once git and jj identity are live" {
    link_git_include_chain
    run_init --git-name Ada --git-email ada@example.com
    assert_success

    # The SSH Include line is bin/link's job, not this module's, so put it
    # where a linked machine has it before asserting a clean check.
    mkdir -p "$TEST_HOME/.ssh"
    "$DOTFILES_DIR/bin/link" include-line > "$TEST_HOME/.ssh/config"

    run_init --check
    assert_success
    assert_output --partial "ada@example.com"
}

@test "--check still fails when only the SSH include is missing" {
    link_git_include_chain
    run_init --git-name Ada --git-email ada@example.com
    assert_success
    run_init --check
    assert_failure
    assert_output --partial "ssh-include"
}

@test "host snippets being absent never fails --check" {
    link_git_include_chain
    run_init --git-name Ada --git-email ada@example.com
    mkdir -p "$TEST_HOME/.ssh"
    echo 'Include ~/.config/ssh/config.d/*.conf' > "$TEST_HOME/.ssh/config"
    [ ! -d "$FIXTURE_CONFIG/ssh/config.d" ]
    run_init --check
    assert_success
}

@test "git identity written into a config.local nothing includes is reported ineffective" {
    run_init --git-name Ada --git-email ada@example.com
    assert_success
    run_init --status
    [ "$(state_of git-identity)" = "ineffective" ]
    assert_output --partial "does not read it"

    run_init --check
    assert_failure
}

@test "git identity reached through the include chain is reported configured" {
    link_git_include_chain
    run_init --git-name Ada --git-email ada@example.com
    run_init --status
    [ "$(state_of git-identity)" = "configured" ]
}

# ---------- nothing it writes is tracked ----------

@test "the files dotfiles-init writes are all gitignored" {
    require_git_repo
    run git -C "$DOTFILES_DIR" check-ignore -q .config/git/config.local
    assert_success
    run git -C "$DOTFILES_DIR" check-ignore -q .config/jj/conf.d/user.toml
    assert_success
    run git -C "$DOTFILES_DIR" check-ignore -q .config/ssh/config.d/example.conf
    assert_success
}

@test "no local file dotfiles-init writes is tracked" {
    require_git_repo
    run git -C "$DOTFILES_DIR" ls-files -- '.config/git/config.local' '.config/jj/conf.d/user.toml'
    [ -z "$output" ]
}

# The counterpart to the rule above: ignoring the conf.d directory itself would
# stop git descending into it and silently swallow the template with it.
@test "the jj template is present and trackable" {
    [ -f "$DOTFILES_DIR/.config/jj/conf.d/user.toml.example" ]
    require_git_repo
    run git -C "$DOTFILES_DIR" check-ignore -q .config/jj/conf.d/user.toml.example
    assert_failure
}

@test "the jj template carries no real identity" {
    require_git_repo
    run git -C "$DOTFILES_DIR" grep -nE '^\s*(name|email)\s*=' -- .config/jj/conf.d/user.toml.example
    assert_failure
}

# ---------- it does not drift from its callers ----------

@test "every identity variable the Makefile reads appears in make help" {
    run bash -c '
        set -euo pipefail
        cd "$1"
        help="$(make help 2>/dev/null)"
        status=0
        for v in $(grep -oE "\$\((GIT|JJ)_[A-Z_]+\)" Makefile | tr -d "\$()" | sort -u); do
            printf "%s" "$help" | grep -q "$v" || { echo "undocumented in make help: $v"; status=1; }
        done
        exit $status
    ' _ "$DOTFILES_DIR"
    assert_success
}

@test "make init is a phony target that runs dotfiles-init" {
    run grep -E '^\.PHONY|^ +doctor init update' "$DOTFILES_DIR/Makefile"
    assert_success
    run grep -A6 '^init:' "$DOTFILES_DIR/Makefile"
    assert_output --partial "bin/dotfiles-init"
}
