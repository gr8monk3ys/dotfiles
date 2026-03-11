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
	run grep -R -n --fixed-strings "-printf" .zshenv .config/zsh
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
