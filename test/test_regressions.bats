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
@test "bat config file selects base16-onedark" {
	run grep -n '^--theme="base16-onedark"$' .config/bat/config
	assert_success
}

@test "git delta and neovim are configured for onedark" {
	# git's own parser, not a regex over git's syntax: this passes only if
	# the setting is in a section git actually reads.
	run git config --file .config/git/.gitconfig --get delta.syntax-theme
	assert_success
	assert_output "base16-onedark"

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
#
# The package list now comes from bin/manifest, so these assert the outcome
# (real names, no comment leaking in) rather than which file the recipe names.
@test "make node-packages expands real package names, not a comment" {
    run make -n node-packages SKIP_BREW=1
    assert_success
    [[ "$output" != *"global # npm"* ]]

    run bin/manifest list npm
    assert_success
    [[ "${#lines[@]}" -gt 0 ]]
    run bash -c 'bin/manifest list npm | grep -c "^#"'
    assert_output "0"
}

@test "make rust-packages does not run a bare cargo install" {
    run make -n rust-packages SKIP_BREW=1
    assert_success
    [[ "$output" != *"cargo install # Rust"* ]]

    run bin/manifest list rust
    assert_success
    [[ "${#lines[@]}" -gt 0 ]]
    run bash -c 'bin/manifest list rust | grep -c "^#"'
    assert_output "0"
}

# Regression: `link: stow-$(OS)` had no stow-linux target, so `make link`
# on any non-Arch Linux failed with "No rule to make target 'stow-linux'".
@test "make link has a rule for generic linux" {
	run make -n OS=linux link
	assert_success
	[[ "$output" == *"stow -t"* ]]
}

# Regression: Homebrew >= 5 refuses third-party taps until `brew trust`ed,
# so `brew bundle` on a fresh Mac died on the first tapped cask (aerospace).
#
# Trusting taps moved inside bin/install-kind, where it is asserted by running
# the real thing against stub binaries ("brew kinds trust the declared taps
# first", test_install_kind.bats). What stays here is the make-level claim:
# the brew kinds are still routed through install-kind at all.
@test "brew and cask targets route through install-kind" {
	run make -n brew-packages
	assert_success
	[[ "$output" == *"install-kind brew"* ]]
	run make -n cask-apps
	assert_success
	[[ "$output" == *"install-kind cask"* ]]
}

# Public-readiness: tracked config must carry no personal identity or hosts.
@test "tracked git, jj and ssh config contain no personal identity" {
	run git -C "$DOTFILES_DIR" grep -nE '^\s*(email|name)\s*=' -- .config/git/.gitconfig
	assert_failure
	run git -C "$DOTFILES_DIR" grep -nE '^\s*(email|name)\s*=' -- .config/jj/config.toml
	assert_failure
	run git -C "$DOTFILES_DIR" ls-files -- '.config/ssh/config.d/*.conf'
	[[ -z "$output" ]]
	git -C "$DOTFILES_DIR" check-ignore -q .config/ssh/config.d/pi-lab.conf
}

# Regression: `link` and `link-dry-run` each carried their own copy of the
# SSH-include pattern with different escaping. Make does not collapse `\\`, so
# `link`'s grep received an escaped backslash plus a quantifier rather than a
# literal `*`, never matched an existing Include, and appended another block
# on every run. A real ~/.ssh/config had accumulated three.
@test "make link is idempotent: the SSH Include is appended exactly once" {
	command -v stow >/dev/null 2>&1 || skip "stow not installed"
	mkdir -p "$TEST_HOME/.config"

	run make -C "$DOTFILES_DIR" link HOME="$TEST_HOME" XDG_CONFIG_HOME="$TEST_HOME/.config"
	assert_success
	run make -C "$DOTFILES_DIR" link HOME="$TEST_HOME" XDG_CONFIG_HOME="$TEST_HOME/.config"
	assert_success

	run grep -c 'Include ~/.config/ssh/config.d' "$TEST_HOME/.ssh/config"
	assert_output "1"
}

@test "link and link-dry-run agree about the SSH Include" {
	command -v stow >/dev/null 2>&1 || skip "stow not installed"
	mkdir -p "$TEST_HOME/.config"

	# Before linking, the dry run must say it would append.
	run make -C "$DOTFILES_DIR" link-dry-run HOME="$TEST_HOME" XDG_CONFIG_HOME="$TEST_HOME/.config"
	assert_success
	[[ "$output" == *"Would append"* ]]

	run make -C "$DOTFILES_DIR" link HOME="$TEST_HOME" XDG_CONFIG_HOME="$TEST_HOME/.config"
	assert_success

	# After linking, it must say it is already present.
	run make -C "$DOTFILES_DIR" link-dry-run HOME="$TEST_HOME" XDG_CONFIG_HOME="$TEST_HOME/.config"
	assert_success
	[[ "$output" == *"already present"* ]]
}
