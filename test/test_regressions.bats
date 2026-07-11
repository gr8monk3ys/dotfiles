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

@test "core alias c is defined exactly once" {
	local count
	count="$(grep -E -n '^alias c=' .config/zsh/.zshrc .config/zsh/aliases.zsh | wc -l | tr -d '[:space:]')"
	[[ "$count" -eq 1 ]] || {
		echo "Expected exactly one alias c definition, found: $count"
		grep -E -n '^alias c=' .config/zsh/.zshrc .config/zsh/aliases.zsh || true
		return 1
	}
}

@test "bat theme uses base16-onedark in env and bat config" {
	run grep -n 'BAT_THEME="base16-onedark"' .zshenv
	assert_success

	run grep -n '^--theme="base16-onedark"$' .config/bat/config
	assert_success
}

@test "git delta and neovim are configured for onedark" {
	run grep -n '^[[:space:]]*syntax-theme = base16-onedark$' .config/git/.gitconfig
	assert_success

	run grep -E -n '"navarasu/onedark.nvim"|theme = "onedark"' .config/nvim/lua/plugins.lua
	assert_success
}

@test "legacy theme names are absent from key configs" {
	run grep -E -n 'OneHalfDark|tokyonight' .zshenv .config/bat/config .config/git/.gitconfig .config/nvim/lua/plugins.lua
	assert_failure
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

@test "prompt system: starship default with p10k fallback wiring" {
	grep -q 'DOTFILES_PROMPT' .config/zsh/.zshrc
	grep -q 'starship init zsh' .config/zsh/.zshrc
	grep -q 'prompt.local' .config/zsh/.zshrc
	# fallback guard exists for machines without the starship binary
	grep -q 'command -v starship' .config/zsh/.zshrc
	[[ -f .config/starship/starship.toml ]]
	# p10k stays loadable for the fallback path
	grep -q 'romkatv/powerlevel10k' .config/zsh/.zshrc
}

@test "Makefile does not use GNU-only find -xtype" {
	run grep -n -- "-xtype" Makefile
	assert_failure
}

@test "make clean removes broken symlinks on BSD and GNU find" {
	mkdir -p "$TEST_HOME/.config"
	printf 'keep\n' > "$TEST_HOME/.config/real-file"
	ln -s "$TEST_HOME/.config/real-file" "$TEST_HOME/.config/valid-link"
	ln -s "$TEST_HOME/does-not-exist" "$TEST_HOME/.config/broken-link"

	run env HOME="$TEST_HOME" PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
		make clean
	assert_success

	[[ -f "$TEST_HOME/.config/real-file" ]]
	[[ -h "$TEST_HOME/.config/valid-link" ]]
	[[ ! -h "$TEST_HOME/.config/broken-link" ]]
}

@test "dotfiles-doctor does not report pacman on macOS" {
	skip_if_not_macos

	# Repo bin first on PATH, like make doctor: the bin/pacman wrapper
	# must not register as an installed package manager on macOS
	run env HOME="$TEST_HOME" DOTFILES_DIR="$TEST_HOME/.dotfiles" \
		PATH="$DOTFILES_DIR/bin:/usr/bin:/bin:/usr/sbin:/sbin" \
		bash bin/dotfiles-doctor
	[[ "$output" != *"pacman installed"* ]]
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
