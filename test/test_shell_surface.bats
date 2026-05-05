#!/usr/bin/env bats
# Shell-surface validation tests.
#
# Layer B-leaf: every shell file the user authors (i.e. not third-party
# plugins) must parse and source cleanly in isolation. Sourcing in a
# clean subshell catches errors that fire at definition time —
# typo'd guard expressions, malformed function declarations,
# bad parameter expansions.

load test_helper/common

setup() {
    setup_test_env
}

teardown() {
    cleanup_test_env
}

# --- Parse checks (zsh -n) -------------------------------------------------

@test "shell-surface: .zshenv parses as valid zsh" {
    run zsh -n "$DOTFILES_DIR/.zshenv"
    assert_success
}

@test "shell-surface: aliases.zsh parses as valid zsh" {
    run zsh -n "$DOTFILES_DIR/.config/zsh/aliases.zsh"
    assert_success
}

@test "shell-surface: functions.zsh parses as valid zsh" {
    run zsh -n "$DOTFILES_DIR/.config/zsh/functions.zsh"
    assert_success
}

# --- Source checks ---------------------------------------------------------
# Source each file in a clean subshell with HOME pointed at a temp dir.
# Any error written to stderr at source time is a failure.

@test "shell-surface: .zshenv sources cleanly in a clean subshell" {
    run zsh -c "HOME='$TEST_HOME' source '$DOTFILES_DIR/.zshenv'"
    assert_success
    assert_output ""
}

@test "shell-surface: aliases.zsh sources cleanly in a clean subshell" {
    run zsh -c "HOME='$TEST_HOME' source '$DOTFILES_DIR/.config/zsh/aliases.zsh'"
    assert_success
    assert_output ""
}

@test "shell-surface: functions.zsh sources cleanly in a clean subshell" {
    run zsh -c "HOME='$TEST_HOME' source '$DOTFILES_DIR/.config/zsh/functions.zsh'"
    assert_success
    assert_output ""
}
