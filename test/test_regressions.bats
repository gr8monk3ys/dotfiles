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
