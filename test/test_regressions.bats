#!/usr/bin/env bats
# Regression tests for previously identified repo drift/issues

load test_helper/common

setup() {
	setup_test_env
}

teardown() {
	cleanup_test_env
}

@test "shell configs do not use GNU-only find -printf" {
	run grep -R -n -F "-printf" .zshenv .config/zsh
	assert_failure
}

# $BAT_THEME is asserted on a booted shell in test_shell_boot.bats. bat's own
# config file has no cheap runtime observable, so it stays a text check.
@test "bat config file selects danse" {
	run grep -n '^--theme="danse"$' .config/bat/config
	assert_success
}

@test "git delta and neovim are configured for the danse palette" {
	# git's own parser, not a regex over git's syntax: this passes only if
	# the setting is in a section git actually reads.
	run git config --file .config/git/config --get delta.syntax-theme
	assert_success
	assert_output "danse"

	# nvim would need a headless boot to observe; a text check is the
	# proportionate tool here.
	run grep -E -n '"navarasu/onedark.nvim"|theme = "onedark"' .config/nvim/lua/plugins.lua
	assert_success
}

@test "dotfiles-backup completes when a single config file is present" {
	mkdir -p "$TEST_TEMP_DIR/backups"
	printf 'export TEST_BACKUP=1\n' > "$TEST_HOME/.zshrc"

	run env HOME="$TEST_HOME" BACKUP_DIR="$TEST_TEMP_DIR/backups" \
		PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
		bash bin/dotfiles-backup
	assert_success
	assert_output --partial "Backup completed successfully!"

	local backup_path
	backup_path="$(find "$TEST_TEMP_DIR/backups" -maxdepth 1 -mindepth 1 -type d | head -n 1)"
	[[ -n "$backup_path" ]]
	[[ -f "$backup_path/MANIFEST.txt" ]]
	[[ -f "$backup_path/configs/.zshrc" ]]
}

@test "dotfiles-backup cleanup keeps the latest five backups" {
	mkdir -p \
		"$TEST_TEMP_DIR/backups/20260101_000000" \
		"$TEST_TEMP_DIR/backups/20260102_000000" \
		"$TEST_TEMP_DIR/backups/20260103_000000" \
		"$TEST_TEMP_DIR/backups/20260104_000000" \
		"$TEST_TEMP_DIR/backups/20260105_000000" \
		"$TEST_TEMP_DIR/backups/20260106_000000"

	run env HOME="$TEST_HOME" BACKUP_DIR="$TEST_TEMP_DIR/backups" \
		PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
		bash bin/dotfiles-backup --cleanup
	assert_success

	local backup_count
	backup_count="$(find "$TEST_TEMP_DIR/backups" -maxdepth 1 -mindepth 1 -type d -name '20*' | wc -l | tr -d '[:space:]')"
	[[ "$backup_count" -eq 5 ]]
}

@test "dotfiles-doctor reaches the summary when issues are present" {
	run env HOME="$TEST_HOME" DOTFILES_DIR="$TEST_HOME/.dotfiles" \
		PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
		bash bin/dotfiles-doctor
	assert_failure
	assert_output --partial "Summary"
	assert_output --partial "issue(s) found"
}

# That starship is the *live* prompt is asserted on a booted shell in
# test_shell_boot.bats. What stays here are the static negatives: p10k is
# gone and nothing reintroduces it.
@test "prompt system: starship only, guarded on the binary" {
	grep -q 'command -v starship' .config/zsh/.zshrc
	[[ -f .config/starship/starship.toml ]]
	# p10k is gone: no config file, no plugin load, no prompt switch
	[[ ! -f .config/zsh/.p10k.zsh ]]
	run grep -n 'powerlevel10k\|p10k\|DOTFILES_PROMPT' .config/zsh/.zshrc
	assert_failure
}

@test "Makefile does not use GNU-only find -xtype" {
	run grep -n -- "-xtype" Makefile
	assert_failure
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

# Regression: `dotfiles-why` with no args launched fzf without a TTY and hung.
@test "dotfiles-why without a terminal prints usage and exits 1" {
	run bash -c 'bin/dotfiles-why </dev/null'
	assert_failure
	assert_output --partial "Usage:"
}

@test "dotfiles-doctor checks Zinit instead of Oh My Zsh" {
	mkdir -p "$TEST_HOME/.local/share/zinit/zinit.git"

	run env HOME="$TEST_HOME" DOTFILES_DIR="$TEST_HOME/.dotfiles" \
		XDG_DATA_HOME="$TEST_HOME/.local/share" \
		PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
		bash bin/dotfiles-doctor
	assert_output --partial "Zinit installed"
	[[ "$output" != *"Oh My Zsh"* ]]
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

@test "install.sh does not re-implement the Makefile's OS dispatch" {
	# It may read the platform to report it, but must not branch to targets.
	# Comments are exempt: the deletion is explained in one.
	run bash -c 'grep -vE "^[[:space:]]*#" install.sh | grep -nE "make (macos|arch|link)\b"'
	assert_failure
}

# Public-readiness: tracked config must carry no personal identity or hosts.
@test "tracked git, jj and ssh config contain no personal identity" {
	run git -C "$DOTFILES_DIR" grep -nE '^\s*(email|name)\s*=' -- .config/git/config
	assert_failure
	run git -C "$DOTFILES_DIR" grep -nE '^\s*(email|name)\s*=' -- .config/jj/config.toml
	assert_failure
	run git -C "$DOTFILES_DIR" ls-files -- '.config/ssh/config.d/*.conf'
	[[ -z "$output" ]]
	git -C "$DOTFILES_DIR" check-ignore -q .config/ssh/config.d/pi-lab.conf
}

# Regression: install.sh declared `readonly STRICT_PACKAGES=...` and then used
# it as an assignment prefix (`STRICT_PACKAGES="$STRICT_PACKAGES" make`). bash
# treats that as a fatal error on a readonly variable, so under `set -e` the
# curl installer exited 1 before running make at all. CI's Installer job
# caught it, but only after push: `make verify` never runs install.sh.
@test "no readonly variable is used as a command assignment prefix" {
	run bash -c '
		set -euo pipefail
		cd "$1"
		status=0
		for f in install.sh bin/*; do
			[[ -f "$f" && "$f" != *.md ]] || continue
			# Variables this file declares readonly...
			for v in $(grep -oE "^readonly [A-Z_]+=" "$f" | sed "s/^readonly //; s/=$//"); do
				# ...must not then appear as `VAR=... cmd`.
				if grep -qE "^[[:space:]]*$v=.*[[:space:]]+[a-z]" "$f" &&
				   ! grep -qE "^readonly $v=" <(grep -E "^[[:space:]]*$v=" "$f"); then
					echo "$f: $v is readonly but reassigned as a command prefix"
					status=1
				fi
			done
		done
		exit $status
	' _ "$DOTFILES_DIR"
	assert_success
}

@test "install.sh exports STRICT_PACKAGES rather than re-assigning it" {
	run grep -n "^export STRICT_PACKAGES" install.sh
	assert_success
	run grep -nE '^[[:space:]]*STRICT_PACKAGES="\$STRICT_PACKAGES"[[:space:]]+make' install.sh
	assert_failure
}

# Regression: yazi renamed [manager] to [mgr] in 25.4 and [open].rules' `name`
# key to `url`. Our config kept the old spellings, so yazi failed to parse it
# and ran on stock defaults while appearing configured. This is a text check,
# not a liveness one — yazi has no headless config probe, `--debug` needs a
# TTY, and supplying one via `script` hangs on the TUI.
@test "yazi config uses the section names this yazi version knows" {
	command -v yazi > /dev/null 2>&1 || skip "yazi not installed"
	run grep -c '^\[manager\]' .config/yazi/yazi.toml
	assert_output "0"
	run grep -c '^\[mgr\]' .config/yazi/yazi.toml
	assert_output "1"
	# Every [open].rules entry needs url or mime; `name` was the old key.
	run grep -c '{ name = ' .config/yazi/yazi.toml
	assert_output "0"
}
