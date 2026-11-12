#!/usr/bin/env bats
#
# The Makefile's own preamble: how it finds its tools and hands PATH to
# recipes. Behaviour that belongs to a target lives with that target's module.

load 'test_helper/common'

@test "recipes run when a PATH entry contains a space" {
	# Regression: SHELL was `env PATH=$(PATH) /bin/bash`, unquoted, so one
	# spaced entry (the Claude desktop app adds several under
	# "Application Support") split the value and every recipe exited 127.
	mkdir -p "$BATS_TEST_TMPDIR/with space"
	PATH="$BATS_TEST_TMPDIR/with space:$PATH" run make -s -C "$DOTFILES_DIR" help
	assert_success
	[[ "$output" != *"No such file or directory"* ]]
}

@test "make -f from another directory still detects the platform" {
	# Regression: bin/platform was invoked relative to the cwd, so OS came out
	# empty and `link` depended on a target named `stow-`.
	cd "$BATS_TEST_TMPDIR"
	run make -f "$DOTFILES_DIR/Makefile" -n link
	assert_success
	[[ "$output" != *"stow-'"* ]]
}

# Regression: stow-arch depended on core-arch, so on Arch `make link-dry-run`
# — a preview — ran `pacman -Syu`. OS is forced so this holds on every runner.
@test "link-dry-run on Arch never upgrades the system" {
	run make -n -C "$DOTFILES_DIR" link-dry-run OS=arch
	assert_success
	[[ "$output" != *"-Syu"* ]]
}

@test "link on Arch never upgrades the system" {
	run make -n -C "$DOTFILES_DIR" link OS=arch
	assert_success
	[[ "$output" != *"-Syu"* ]]
}

@test "link on Arch installs only stow when stow is missing" {
	run make -n -C "$DOTFILES_DIR" link OS=arch HAVE_STOW=
	assert_success
	[[ "$output" == *"pacman -S --needed --noconfirm stow"* ]]
	[[ "$output" != *"-Syu"* ]]
}

@test "make arch still runs the full upgrade" {
	run make -n -C "$DOTFILES_DIR" arch OS=arch
	assert_success
	[[ "$output" == *"pacman -Syu --noconfirm"* ]]
}
