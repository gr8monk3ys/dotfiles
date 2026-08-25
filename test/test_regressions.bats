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

@test "prompt system: starship only, guarded on the binary" {
	grep -q 'starship init zsh' .config/zsh/.zshrc
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
	run make -n macos SKIP_BREW=1 SKIP_CASKS=1 SKIP_NPM=1 SKIP_RUST=1
	assert_success
	[[ "$output" != *"chsh"* ]]
	[[ "$output" != *"sudo -v"* ]]
	[[ "$output" == *"Codefile"* ]]
}

# Regression: `stow-macos: brew` made "symlinks only" install Homebrew via
# curl on a fresh Mac. With stow present, `make link` must touch nothing else.
@test "make link does not bootstrap Homebrew when stow is present" {
	command -v stow >/dev/null 2>&1 || skip "stow not installed"
	run make -n OS=macos link
	assert_success
	[[ "$output" != *"curl"* ]]
	[[ "$output" != *"brew install"* ]]
}

# Regression: `dotfiles-why` with no args launched fzf without a TTY and hung.
@test "dotfiles-why without a terminal prints usage and exits 1" {
	run bash -c 'bin/dotfiles-why </dev/null'
	assert_failure
	assert_output --partial "Usage:"
}

@test "dotfiles-update npm check survives outdated packages under set -e" {
	# Minimal clean git repo so update_dotfiles passes
	git -C "$TEST_HOME" init -q -b main dotfiles-repo
	git -C "$TEST_HOME/dotfiles-repo" -c user.email=t@t.t -c user.name=t \
		commit -q --allow-empty -m init
	git -C "$TEST_HOME/dotfiles-repo" remote add origin "$TEST_HOME/dotfiles-repo"

	# Stub npm: like the real one, outdated exits 1 when packages are stale
	mkdir -p "$TEST_TEMP_DIR/bin"
	cat > "$TEST_TEMP_DIR/bin/npm" <<'EOS'
#!/usr/bin/env bash
case "${1:-}" in
	outdated) printf 'Package Current Wanted\nfoo 1.0.0 2.0.0\n'; exit 1 ;;
	*) exit 0 ;;
esac
EOS
	chmod +x "$TEST_TEMP_DIR/bin/npm"

	run env HOME="$TEST_HOME" DOTFILES_DIR="$TEST_HOME/dotfiles-repo" \
		PATH="$TEST_TEMP_DIR/bin:/usr/bin:/bin:/usr/sbin:/sbin" \
		bash bin/dotfiles-update --skip-brew --skip-cargo
	assert_success
	assert_output --partial "npm packages updated"
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

# Regression: Makefile used $(shell cat install/npmfile), which flattens the
# file onto one line so the leading "# comment" turned every package name
# into a shell comment. `make node-packages` installed nothing and
# `make rust-packages` ran a bare `cargo install`.
@test "make node-packages expands real package names, not a comment" {
    run make -n node-packages SKIP_BREW=1
    assert_success
    [[ "$output" == *"install/npmfile"* ]]
    [[ "$output" != *"global # npm"* ]]
}

@test "make rust-packages does not run a bare cargo install" {
    run make -n rust-packages SKIP_BREW=1
    assert_success
    [[ "$output" != *"cargo install # Rust"* ]]
    [[ "$output" == *"install/Rustfile"* ]]
}

# Regression: `link: stow-$(OS)` had no stow-linux target, so `make link`
# on any non-Arch Linux failed with "No rule to make target 'stow-linux'".
@test "make link has a rule for generic linux" {
	run make -n OS=linux link
	assert_success
	[[ "$output" == *"stow -t"* ]]
}
