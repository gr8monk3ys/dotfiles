#!/usr/bin/env bats
# Tests for bin/link, the write side of link state.
#
# Everything runs against a fixture checkout and a fixture home. Linking used
# to be three Makefile recipes that could only be tested by grepping `make -n`
# or by running `make link` whole; the dry-run recipe was a hand-written
# mirror that had already drifted from the real one.

load test_helper/common

setup() {
    setup_test_env
    export FAKE_REPO="$TEST_TEMP_DIR/checkout"
    mkdir -p "$FAKE_REPO/.config"
    printf 'export ZDOTDIR=x\n' > "$FAKE_REPO/.zshenv"
    # An ordinary directory stow folds, and a tool-owned one (cava is in
    # bin/link's list) with a subdirectory, the shape cava used to have.
    mkdir -p "$FAKE_REPO/.config/ghostty" "$FAKE_REPO/.config/cava/shaders"
    printf 'theme = x\n' > "$FAKE_REPO/.config/ghostty/config"
    printf 'method = ncurses\n' > "$FAKE_REPO/.config/cava/config"
    printf 'void main() {}\n' > "$FAKE_REPO/.config/cava/shaders/bars.frag"
}

teardown() {
    cleanup_test_env
}

needs_stow() {
    command -v stow > /dev/null 2>&1 || skip "stow not installed"
}

# Run bin/link against the fixture; stdout only, the plan rows.
link() {
    env DOTFILES_DIR="$FAKE_REPO" HOME="$TEST_HOME" \
        XDG_CONFIG_HOME="$TEST_HOME/.config" \
        bash "$DOTFILES_DIR/bin/link" "$@" 2> "$TEST_TEMP_DIR/stderr"
}

# Everything under the fixture home, with link targets and modes, so a
# before/after comparison sees any change at all.
snapshot() {
    (cd "$TEST_HOME" && find . -print0 | sort -z | xargs -0 ls -ld) \
        | awk '{ $6=$7=$8=""; print }'
}

resolves_to() {
    [[ "$(readlink -f "$1")" == "$(readlink -f "$2")" ]]
}

@test "link is executable" {
    [[ -x "$DOTFILES_DIR/bin/link" ]]
}

# ---------- apply ----------

@test "apply links .zshenv, stows .config, and links tool-owned dirs unfolded" {
    needs_stow
    run link apply
    assert_success

    [[ -L "$TEST_HOME/.zshenv" ]]
    resolves_to "$TEST_HOME/.zshenv" "$FAKE_REPO/.zshenv"
    # Folded, as stow does for anything that is not tool-owned.
    [[ -L "$TEST_HOME/.config/ghostty" ]]
    # Unfolded: real directories, one link per shipped file.
    [[ -d "$TEST_HOME/.config/cava" && ! -L "$TEST_HOME/.config/cava" ]]
    [[ -d "$TEST_HOME/.config/cava/shaders" && ! -L "$TEST_HOME/.config/cava/shaders" ]]
    [[ -L "$TEST_HOME/.config/cava/config" ]]
    resolves_to "$TEST_HOME/.config/cava/shaders/bars.frag" "$FAKE_REPO/.config/cava/shaders/bars.frag"
    [[ -d "$TEST_HOME/.local/runtime" ]]

    # And the read side agrees that everything is linked.
    run env DOTFILES_DIR="$FAKE_REPO" bash "$DOTFILES_DIR/bin/link-state" "$TEST_HOME"
    assert_success
    [[ "$(printf '%s\n' "$output" | awk -F'\t' '$1 != "linked"')" == "" ]]
}

@test "a tool's own writes land outside the checkout" {
    needs_stow
    link apply
    printf 'generated\n' > "$TEST_HOME/.config/cava/shaders/new.frag"
    [[ ! -e "$FAKE_REPO/.config/cava/shaders/new.frag" ]]
}

@test "apply is idempotent: a second run has nothing to do" {
    needs_stow
    link apply
    run link apply
    assert_success
    assert_output ""
    grep -q "nothing to do" "$TEST_TEMP_DIR/stderr"
}

# Regression: `link` and `link-dry-run` each carried their own copy of the
# SSH-include pattern with different escaping. Make does not collapse `\\`, so
# `link`'s grep received an escaped backslash plus a quantifier rather than a
# literal `*`, never matched an existing Include, and appended another block
# on every run. A real ~/.ssh/config had accumulated three.
@test "the SSH Include is appended exactly once across repeated applies" {
    needs_stow
    mkdir -p "$TEST_HOME/.ssh"
    printf 'Host example\n  User me\n' > "$TEST_HOME/.ssh/config"
    link apply
    link apply
    link apply
    run grep -cF "$(bash "$DOTFILES_DIR/bin/link" include-line)" "$TEST_HOME/.ssh/config"
    assert_output "1"
    # The user's own content is kept.
    grep -q '^Host example' "$TEST_HOME/.ssh/config"
}

@test "apply sets the SSH and runtime directory permissions" {
    needs_stow
    mkdir -p "$TEST_HOME/.ssh" "$TEST_HOME/.local/runtime"
    chmod 755 "$TEST_HOME/.ssh" "$TEST_HOME/.local/runtime"
    link apply
    [[ -n "$(find "$TEST_HOME/.ssh" -maxdepth 0 -perm 700)" ]]
    [[ -n "$(find "$TEST_HOME/.ssh/config" -maxdepth 0 -perm 600)" ]]
    [[ -n "$(find "$TEST_HOME/.local/runtime" -maxdepth 0 -perm 700)" ]]
}

@test "has-include recognises an indented Include with a trailing comment" {
    printf 'Host x\n  Include ~/.config/ssh/config.d/*.conf # mine\n' > "$TEST_TEMP_DIR/ssh_config"
    run bash "$DOTFILES_DIR/bin/link" has-include "$TEST_TEMP_DIR/ssh_config"
    assert_success
    # The glob star is literal: a different directory does not count.
    printf 'Include ~/.config/ssh/config.d/x.conf\n' > "$TEST_TEMP_DIR/ssh_config"
    run bash "$DOTFILES_DIR/bin/link" has-include "$TEST_TEMP_DIR/ssh_config"
    assert_failure
}

# ---------- dry-run ----------

@test "dry-run changes nothing" {
    needs_stow
    printf 'mine\n' > "$TEST_HOME/.zshenv"
    local before
    before="$(snapshot)"
    run link dry-run
    assert_success
    [[ "$(snapshot)" == "$before" ]]
}

@test "dry-run lists exactly the actions apply takes" {
    needs_stow
    printf 'mine\n' > "$TEST_HOME/.zshenv"
    link dry-run > "$TEST_TEMP_DIR/dry"
    link apply > "$TEST_TEMP_DIR/apply"
    [[ -s "$TEST_TEMP_DIR/apply" ]]
    run diff "$TEST_TEMP_DIR/dry" "$TEST_TEMP_DIR/apply"
    assert_success
    # The old mirror never mentioned these.
    grep -q '^mkdir .*/.local/runtime (700)$' "$TEST_TEMP_DIR/apply"
    grep -q '^backup .*/.zshenv -> .*/.zshenv.bak$' "$TEST_TEMP_DIR/apply"
}

@test "dry-run and apply agree after a partial link too" {
    needs_stow
    link apply
    rm "$TEST_HOME/.config/cava/config"
    sed -i.orig '/Include/d' "$TEST_HOME/.ssh/config"
    link dry-run > "$TEST_TEMP_DIR/dry"
    link apply > "$TEST_TEMP_DIR/apply"
    run diff "$TEST_TEMP_DIR/dry" "$TEST_TEMP_DIR/apply"
    assert_success
    run cat "$TEST_TEMP_DIR/apply"
    assert_output --partial "cava/config"
    assert_output --partial "append"
}

# ---------- .zshenv and undo ----------

@test "apply backs up a real .zshenv and undo restores it" {
    needs_stow
    printf 'mine\n' > "$TEST_HOME/.zshenv"
    link apply
    [[ -L "$TEST_HOME/.zshenv" ]]
    [[ "$(cat "$TEST_HOME/.zshenv.bak")" == "mine" ]]

    run link undo
    assert_success
    [[ ! -L "$TEST_HOME/.zshenv" ]]
    [[ "$(cat "$TEST_HOME/.zshenv")" == "mine" ]]
    [[ ! -e "$TEST_HOME/.zshenv.bak" ]]
}

@test "apply refuses rather than overwrite an existing .zshenv.bak" {
    printf 'mine\n' > "$TEST_HOME/.zshenv"
    printf 'older\n' > "$TEST_HOME/.zshenv.bak"
    run link apply
    assert_failure
    [[ "$(cat "$TEST_HOME/.zshenv.bak")" == "older" ]]
    [[ "$(cat "$TEST_HOME/.zshenv")" == "mine" ]]
}

@test "undo removes every link apply made and keeps what a tool wrote" {
    needs_stow
    link apply
    printf 'generated\n' > "$TEST_HOME/.config/cava/shaders/new.frag"
    run link undo
    assert_success
    [[ ! -e "$TEST_HOME/.zshenv" ]]
    [[ ! -e "$TEST_HOME/.config/ghostty" ]]
    [[ ! -e "$TEST_HOME/.config/cava/config" ]]
    [[ "$(cat "$TEST_HOME/.config/cava/shaders/new.frag")" == "generated" ]]
    # And the checkout is untouched.
    [[ -f "$FAKE_REPO/.config/cava/config" && -f "$FAKE_REPO/.zshenv" ]]
}

@test "undo leaves a .zshenv that is not ours alone" {
    printf 'mine\n' > "$TEST_HOME/.zshenv"
    run link undo
    assert_success
    [[ "$(cat "$TEST_HOME/.zshenv")" == "mine" ]]
}

# ---------- migration from a folded tool-owned link ----------

@test "a folded link for a tool-owned dir is unfolded without losing anything" {
    needs_stow
    mkdir -p "$TEST_HOME/.config"
    ln -s "$FAKE_REPO/.config/cava" "$TEST_HOME/.config/cava"
    # What cava wrote into the checkout while the directory was folded.
    printf 'written by cava\n' > "$FAKE_REPO/.config/cava/shaders/generated.frag"

    run link apply
    assert_success
    assert_output --partial "unfold   $TEST_HOME/.config/cava"

    [[ -d "$TEST_HOME/.config/cava" && ! -L "$TEST_HOME/.config/cava" ]]
    [[ -L "$TEST_HOME/.config/cava/config" ]]
    # Everything visible before is still visible, through a file link.
    [[ "$(cat "$TEST_HOME/.config/cava/shaders/generated.frag")" == "written by cava" ]]
    # The checkout itself was not touched.
    [[ -f "$FAKE_REPO/.config/cava/shaders/generated.frag" ]]
    [[ -f "$FAKE_REPO/.config/cava/config" ]]

    run link apply
    assert_success
    assert_output ""
}

@test "undo removes a folded legacy link for a tool-owned dir" {
    needs_stow
    mkdir -p "$TEST_HOME/.config"
    ln -s "$FAKE_REPO/.config/cava" "$TEST_HOME/.config/cava"
    run link undo
    assert_success
    [[ ! -e "$TEST_HOME/.config/cava" && ! -L "$TEST_HOME/.config/cava" ]]
    [[ -f "$FAKE_REPO/.config/cava/config" ]]
}

@test "a conflict aborts before anything is changed" {
    needs_stow
    printf 'mine\n' > "$TEST_HOME/.zshenv"
    mkdir -p "$TEST_HOME/.config/cava"
    printf 'the user wrote this\n' > "$TEST_HOME/.config/cava/config"
    local before
    before="$(snapshot)"

    run link apply
    assert_failure
    grep -q "cava/config exists" "$TEST_TEMP_DIR/stderr"
    [[ "$(snapshot)" == "$before" ]]
}

@test "a stow conflict also aborts before anything is changed" {
    needs_stow
    printf 'mine\n' > "$TEST_HOME/.zshenv"
    mkdir -p "$TEST_HOME/.config/ghostty"
    printf 'not ours\n' > "$TEST_HOME/.config/ghostty/config"
    local before
    before="$(snapshot)"

    run link apply
    assert_failure
    grep -q "stow:" "$TEST_TEMP_DIR/stderr"
    [[ "$(snapshot)" == "$before" ]]
}

# ---------- what it must never do ----------

@test "linking never runs a package manager" {
    needs_stow
    local stubs="$TEST_TEMP_DIR/stubs" cmd
    mkdir -p "$stubs"
    for cmd in pacman brew sudo apt-get dnf curl; do
        printf '#!/bin/sh\necho "%s $*" >> "%s"\nexit 1\n' "$cmd" "$TEST_TEMP_DIR/calls" > "$stubs/$cmd"
        chmod +x "$stubs/$cmd"
    done
    PATH="$stubs:$PATH" link dry-run
    PATH="$stubs:$PATH" link apply
    PATH="$stubs:$PATH" link undo
    [[ ! -e "$TEST_TEMP_DIR/calls" ]]
}

# ---------- the tool-owned list ----------

@test "every tool-owned entry is a directory this checkout ships" {
    run bash "$DOTFILES_DIR/bin/link" tool-owned
    assert_success
    [[ "${#lines[@]}" -gt 0 ]]
    local name
    for name in "${lines[@]}"; do
        [[ -d "$DOTFILES_DIR/.config/$name" ]] || {
            echo "tool-owned entry not shipped: $name"
            return 1
        }
    done
}

@test "karabiner is not tool-owned: it needs its directory folded" {
    # Karabiner-Elements does not notice changes to a symlinked karabiner.json.
    run bash "$DOTFILES_DIR/bin/link" tool-owned
    [[ "$output" != *karabiner* ]]
}
