#!/usr/bin/env bats
# Tests for bin/link-state.
#
# This classification used to live inside dotfiles-doctor with no test at all:
# the only way to exercise it was to run the whole health check and read its
# output. Here it runs against a fixture home with every state present.

load test_helper/common

setup() {
    setup_test_env
    export FAKE_REPO="$TEST_TEMP_DIR/checkout"
    mkdir -p "$FAKE_REPO/.config"
    mkdir -p "$TEST_HOME/.config"
}

teardown() {
    cleanup_test_env
}

# Ship a directory in the fake checkout with one file in it.
ship() {
    local name="$1"
    mkdir -p "$FAKE_REPO/.config/$name"
    printf 'x\n' > "$FAKE_REPO/.config/$name/conf"
}

state_of() {
    local want="$1"
    run env DOTFILES_DIR="$FAKE_REPO" HOME="$TEST_HOME" \
        bash "$DOTFILES_DIR/bin/link-state" "$TEST_HOME"
    assert_success
    # Emit just the state column for the row whose path ends in $want.
    printf '%s\n' "$output" | awk -F'\t' -v w="$want" '$2 ~ w"$" { print $1 }'
}

rows() {
    run env DOTFILES_DIR="$FAKE_REPO" HOME="$TEST_HOME" \
        bash "$DOTFILES_DIR/bin/link-state" "$TEST_HOME"
}

@test "link-state is executable" {
    [[ -x "$DOTFILES_DIR/bin/link-state" ]]
}

@test "a folded directory link is linked" {
    ship ghostty
    ln -s "$FAKE_REPO/.config/ghostty" "$TEST_HOME/.config/ghostty"
    run state_of ".config/ghostty"
    assert_output "linked"
}

@test "an unfolded directory with every file linked is linked" {
    ship zsh
    mkdir -p "$TEST_HOME/.config/zsh"
    ln -s "$FAKE_REPO/.config/zsh/conf" "$TEST_HOME/.config/zsh/conf"
    run state_of ".config/zsh"
    assert_output "linked"
}

@test "an unfolded directory missing a shipped file is partial" {
    ship atuin
    printf 'y\n' > "$FAKE_REPO/.config/atuin/theme"
    mkdir -p "$TEST_HOME/.config/atuin"
    ln -s "$FAKE_REPO/.config/atuin/conf" "$TEST_HOME/.config/atuin/conf"
    # theme is shipped but not linked
    run state_of ".config/atuin"
    assert_output "partial"
}

@test "an unfolded directory holding a real file instead of a link is partial" {
    ship atuin
    mkdir -p "$TEST_HOME/.config/atuin"
    printf 'x\n' > "$TEST_HOME/.config/atuin/conf"
    run state_of ".config/atuin"
    assert_output "partial"
}

@test "a folded subdirectory link counts as linked, not partial" {
    # Regression: stow folds subdirectories, so .config/atuin/themes can be a
    # single link into the checkout and themes/*.toml are real files at the
    # end of a correctly linked path. classify_unfolded required a symlink at
    # each leaf and called that `partial` — a false positive that cost a
    # tracked file when acted on.
    ship atuin
    mkdir -p "$FAKE_REPO/.config/atuin/themes"
    printf 'theme\n' > "$FAKE_REPO/.config/atuin/themes/onedark.toml"

    mkdir -p "$TEST_HOME/.config/atuin"
    ln -s "$FAKE_REPO/.config/atuin/conf" "$TEST_HOME/.config/atuin/conf"
    # The whole themes dir is one link, as stow leaves it.
    ln -s "$FAKE_REPO/.config/atuin/themes" "$TEST_HOME/.config/atuin/themes"

    run state_of ".config/atuin"
    assert_output "linked"
}

@test "a folded subdirectory pointing elsewhere is still partial" {
    # The fix must not make classification unconditionally permissive.
    ship atuin
    mkdir -p "$FAKE_REPO/.config/atuin/themes"
    printf 'theme\n' > "$FAKE_REPO/.config/atuin/themes/onedark.toml"
    mkdir -p "$TEST_TEMP_DIR/impostor/themes"
    printf 'other\n' > "$TEST_TEMP_DIR/impostor/themes/onedark.toml"

    mkdir -p "$TEST_HOME/.config/atuin"
    ln -s "$FAKE_REPO/.config/atuin/conf" "$TEST_HOME/.config/atuin/conf"
    ln -s "$TEST_TEMP_DIR/impostor/themes" "$TEST_HOME/.config/atuin/themes"

    run state_of ".config/atuin"
    assert_output "partial"
}

@test "a shipped directory with nothing at the target is unlinked" {
    ship npm
    run state_of ".config/npm"
    assert_output "unlinked"
}

@test "a link pointing outside the checkout is unmanaged" {
    ship git
    mkdir -p "$TEST_TEMP_DIR/elsewhere"
    ln -s "$TEST_TEMP_DIR/elsewhere" "$TEST_HOME/.config/git"
    run state_of ".config/git"
    assert_output "unmanaged"
}

@test "a broken link into the checkout is broken-ours" {
    ship yazi
    rm -rf "$TEST_HOME/.config/yazi"
    ln -s "$FAKE_REPO/.config/yazi/gone" "$TEST_HOME/.config/stray"
    run state_of ".config/stray"
    assert_output "broken-ours"
}

@test "a stow-style relative broken link into the checkout is broken-ours" {
    # ../../checkout/.config/gone from $TEST_HOME/.config reaches
    # $TEST_TEMP_DIR/checkout. Resolved lexically, because a broken link
    # cannot be canonicalised on disk.
    ln -s "../../checkout/.config/gone" "$TEST_HOME/.config/relative-stray"
    run state_of ".config/relative-stray"
    assert_output "broken-ours"
}

@test "a broken link owned by another tool is broken-foreign" {
    ln -s "/nowhere/at/all" "$TEST_HOME/.config/someone-elses"
    run state_of ".config/someone-elses"
    assert_output "broken-foreign"
}

@test ".zshenv is reported" {
    ln -s "$FAKE_REPO/.zshenv" "$TEST_HOME/.zshenv"
    printf 'x\n' > "$FAKE_REPO/.zshenv"
    run state_of ".zshenv"
    assert_output "linked"
}

@test "a real .zshenv that is not a link is unmanaged" {
    printf 'x\n' > "$TEST_HOME/.zshenv"
    run state_of ".zshenv"
    assert_output "unmanaged"
}

@test "a missing .zshenv is unlinked" {
    run state_of ".zshenv"
    assert_output "unlinked"
}

@test "output is tab separated and sorted deterministically" {
    ship aaa
    ship zzz
    ship mmm

    rows
    assert_success
    local first="$output"

    # Every row is state<TAB>path.
    run bash -c 'printf "%s\n" "$1" | grep -cv "^[a-z-]*	/"' _ "$first"
    assert_output "0"

    # Shipped dirs come out alphabetically.
    run bash -c 'printf "%s\n" "$1" | grep -oE "/\\.config/(aaa|mmm|zzz)$" | tr "\n" " "' _ "$first"
    assert_output --partial "aaa"

    # A second run agrees with the first.
    rows
    [[ "$output" == "$first" ]]
}

@test "make clean removes broken symlinks on BSD and GNU find" {
    local fake="$TEST_HOME/fake-dotfiles"
    mkdir -p "$TEST_HOME/.config"
    printf 'keep\n' > "$TEST_HOME/.config/real-file"
    ln -s "$TEST_HOME/.config/real-file" "$TEST_HOME/.config/valid-link"
    # Broken links that pointed into the dotfiles checkout: absolute and
    # stow-style relative (../fake-dotfiles/.config/...)
    ln -s "$fake/.config/gone" "$TEST_HOME/.config/broken-link"
    ln -s "../fake-dotfiles/.config/gone-too" "$TEST_HOME/.config/broken-relative"

    run env HOME="$TEST_HOME" PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
        make clean DOTFILES_DIR="$fake"
    assert_success

    [[ -f "$TEST_HOME/.config/real-file" ]]
    [[ -h "$TEST_HOME/.config/valid-link" ]]
    [[ ! -h "$TEST_HOME/.config/broken-link" ]]
    [[ ! -h "$TEST_HOME/.config/broken-relative" ]]
}

# Regression: `make clean` deleted every broken symlink under ~/.config,
# including ones other tools own. Only links into the checkout are ours.
@test "make clean leaves broken symlinks that do not point into the checkout" {
    mkdir -p "$TEST_HOME/.config"
    ln -s "$TEST_HOME/does-not-exist" "$TEST_HOME/.config/foreign-broken"

    run env HOME="$TEST_HOME" PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
        make clean DOTFILES_DIR="$TEST_HOME/fake-dotfiles"
    assert_success
    [[ -h "$TEST_HOME/.config/foreign-broken" ]]
}
