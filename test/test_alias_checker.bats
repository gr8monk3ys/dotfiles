#!/usr/bin/env bats
# Unit tests for bin/check-alias-references using synthetic fixtures.
#
# These tests verify the checker correctly distinguishes resolvable
# from unresolvable aliases. They are independent of the real
# .config/zsh/aliases.zsh — that file is exercised by an integration
# test in test_shell_surface.bats once the allowlist is built.

load test_helper/common

setup() {
    setup_test_env
}

teardown() {
    cleanup_test_env
}

@test "alias-checker: passes against the good fixture" {
    run env ALIASES_FILE="$DOTFILES_DIR/test/fixtures/aliases-fixture-good.zsh" \
        bash "$DOTFILES_DIR/bin/check-alias-references"
    assert_success
}

@test "alias-checker: fails against the bad fixture and names the offender" {
    run env ALIASES_FILE="$DOTFILES_DIR/test/fixtures/aliases-fixture-bad.zsh" \
        bash "$DOTFILES_DIR/bin/check-alias-references"
    assert_failure
    assert_output --partial "definitely-not-a-real-tool"
    assert_output --partial "alias 'bad'"
}

@test "alias-checker: prints a usable fix-it message on failure" {
    run env ALIASES_FILE="$DOTFILES_DIR/test/fixtures/aliases-fixture-bad.zsh" \
        bash "$DOTFILES_DIR/bin/check-alias-references"
    assert_failure
    assert_output --partial "Fix one of"
    assert_output --partial "install/Brewfile"
    assert_output --partial "test/allowlist/system-tools.txt"
}

@test "alias-checker: exempts aliases inside if-command-v blocks" {
    run env ALIASES_FILE="$DOTFILES_DIR/test/fixtures/aliases-fixture-conditional-exempt.zsh" \
        bash "$DOTFILES_DIR/bin/check-alias-references"
    assert_success
}
