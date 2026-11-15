#!/usr/bin/env bats
# bin/dotfiles-link - what `make link` does: ~/.zshenv, stow of .config, the
# ~/.ssh Include and ~/.local/runtime. Every run is against a fixture HOME
# with its own XDG_CONFIG_HOME; the real home is never read or written.
#
# stow is real when installed. Without it, a stub on PATH stands in that
# reports nothing to do, so the non-stow steps are still covered.

load test_helper/common

setup() {
	setup_test_env
	export FIXTURE_CONFIG="$TEST_HOME/.config"
	if ! command -v stow > /dev/null 2>&1; then
		mkdir -p "$TEST_TEMP_DIR/stub-bin"
		printf '#!/bin/sh\nexit 0\n' > "$TEST_TEMP_DIR/stub-bin/stow"
		chmod +x "$TEST_TEMP_DIR/stub-bin/stow"
		export PATH="$TEST_TEMP_DIR/stub-bin:$PATH"
		export STOW_STUBBED=1
	fi
}

teardown() {
	cleanup_test_env
}

run_link() {
	run env HOME="$TEST_HOME" XDG_CONFIG_HOME="$FIXTURE_CONFIG" \
		"$DOTFILES_DIR/bin/dotfiles-link" "$@"
}

# Every path under the fixture HOME, with its type and target, so a dry run
# can be shown to have changed nothing at all.
snapshot() {
	(cd "$TEST_HOME" && find . -exec ls -ld {} + | awk '{ $6 = $7 = $8 = ""; print }' | sort)
}

@test "dry run is the default and writes nothing" {
	echo 'export FROM_BEFORE=1' > "$TEST_HOME/.zshenv"
	before="$(snapshot)"

	run_link
	assert_success
	assert_output --partial "Dry run: nothing will change"
	assert_output --partial "would   move $TEST_HOME/.zshenv -> $TEST_HOME/.zshenv.dotfiles-bak"
	assert_output --partial "would   append Include ~/.config/ssh/config.d/*.conf"
	assert_output --partial "change(s) pending; run with --apply."
	[[ "$(snapshot)" == "$before" ]]

	run_link --dry-run
	assert_success
	[[ "$(snapshot)" == "$before" ]]
}

@test "dry run against an existing XDG_CONFIG_HOME lists stow's links and writes nothing" {
	[[ -z "${STOW_STUBBED:-}" ]] || skip "stow not installed"
	mkdir -p "$FIXTURE_CONFIG"
	before="$(snapshot)"

	run_link
	assert_success
	assert_output --partial "would   stow LINK: zsh"
	[[ "$(snapshot)" == "$before" ]]
}

@test "--apply links .zshenv and backs up a real one" {
	echo 'export FROM_BEFORE=1' > "$TEST_HOME/.zshenv"

	run_link --apply
	assert_success
	[[ -L "$TEST_HOME/.zshenv" ]]
	[[ "$(readlink "$TEST_HOME/.zshenv")" == "$DOTFILES_DIR/.zshenv" ]]
	run cat "$TEST_HOME/.zshenv.dotfiles-bak"
	assert_output "export FROM_BEFORE=1"
	# The pre-dotfiles-link name is no longer used.
	[[ ! -e "$TEST_HOME/.zshenv.bak" ]]
}

@test "--apply creates ~/.ssh (700), its config (600) and ~/.local/runtime (700)" {
	run_link --apply
	assert_success
	[[ -n "$(find "$TEST_HOME/.ssh" -prune -perm 700)" ]]
	[[ -n "$(find "$TEST_HOME/.ssh/config" -prune -perm 600)" ]]
	[[ -n "$(find "$TEST_HOME/.local/runtime" -prune -perm 700)" ]]
}

@test "--apply stows .config into XDG_CONFIG_HOME" {
	[[ -z "${STOW_STUBBED:-}" ]] || skip "stow not installed"
	run_link --apply
	assert_success
	[[ "$(cd "$FIXTURE_CONFIG/zsh" && pwd -P)" == "$(cd "$DOTFILES_DIR/.config/zsh" && pwd -P)" ]]
}

@test "--apply appends the SSH Include once across two runs, then has nothing to do" {
	mkdir -p "$TEST_HOME/.ssh"
	printf 'Host example\n    User me\n' > "$TEST_HOME/.ssh/config"

	run_link --apply
	assert_success
	run_link --apply
	assert_success
	assert_output --partial "SSH Include already present"
	assert_output --partial "Everything already in place."

	run grep -c 'Include ~/.config/ssh/config.d' "$TEST_HOME/.ssh/config"
	assert_output "1"
	# What was there is kept.
	grep -q '^Host example$' "$TEST_HOME/.ssh/config"
}

@test "an indented Include already in ~/.ssh/config is recognised" {
	mkdir -p "$TEST_HOME/.ssh"
	printf '  Include ~/.config/ssh/config.d/*.conf  # mine\n' > "$TEST_HOME/.ssh/config"

	run_link --apply
	assert_success
	assert_output --partial "SSH Include already present"
	run grep -c 'Include' "$TEST_HOME/.ssh/config"
	assert_output "1"
}

@test "rejects an unknown argument" {
	run_link --bogus
	assert_failure
	assert_output --partial "dotfiles-link: unknown argument: --bogus"
}
