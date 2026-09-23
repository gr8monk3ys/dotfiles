#!/usr/bin/env bats
#
# The Makefile's own preamble and dispatch: how it finds its tools, hands PATH
# to recipes, and picks a target per platform. Behaviour that belongs to a
# target lives with that target's module.

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

@test "Makefile does not use GNU-only find -xtype" {
	run grep -n -- "-xtype" Makefile
	assert_failure
}

# Regression: `make macos` ran a `bash` target whose guard was always true
# and whose body would have `chsh`'d the login shell to bash.
@test "Makefile has no bash/sudo targets and macos never touches the login shell" {
	run grep -E -n '^(bash|sudo):' Makefile
	assert_failure
	run make -n macos SKIP_KINDS="brew cask npm rust"
	assert_success
	[[ "$output" != *"chsh"* ]]
	[[ "$output" != *"sudo -v"* ]]
	# macos still reaches the editor-extension step. Asserting on `make -n`
	# is right here and only here: this is a claim about make's dependency
	# graph, which is make's job. What install-kind then *does* is asserted
	# by running it, in test_install_kind.bats.
	[[ "$output" == *"install-kind code"* ]]
}

# Regression: install.sh cased on `bin/platform detect` and called make
# macos/arch/link itself, duplicating the Makefile's own OS dispatch. The two
# disagreed: platform detect can return "unknown", and make had no target for
# it, so only the curl installer covered that platform.
@test "make has a target for every value bin/platform detect can return" {
	local os
	for os in macos arch linux unknown; do
		run make -n "$os"
		assert_success
	done
}

# Regression: make help advertised `daily` as running shell checks it no
# longer ran, and omitted a dozen real targets. Both directions are checked:
# every target help names exists, and every .PHONY target is either named in
# help or listed here as internal plumbing.
@test "make help names every public target and only real ones" {
	local internal=" all core-macos core-arch packages-macos packages-arch"
	internal+=" stow-macos stow-arch stow-linux linux unknown brew git help "
	run make -s -C "$DOTFILES_DIR" help
	assert_success
	local help="$output" t status=0
	for t in $(printf '%s\n' "$help" | grep -oE '(make |\| )[a-z][a-z-]*' | awk '{print $2}' | sort -u); do
		grep -qE "^$t:" "$DOTFILES_DIR/Makefile" || { echo "help names a missing target: $t"; status=1; }
	done
	for t in $(sed -n '/^\.PHONY:/,/^$/p' "$DOTFILES_DIR/Makefile" | tr -d '\\' | tr ' ' '\n' | grep -E '^[a-z]'); do
		[[ "$internal" == *" $t "* ]] && continue
		printf '%s\n' "$help" | grep -qwE -- "$t" || { echo "public target missing from help: $t"; status=1; }
	done
	return $status
}
