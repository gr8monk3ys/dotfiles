#!/usr/bin/env bats
# Boots a real interactive zsh from the repo's own config and checks the
# things that only show up at runtime: exit status, startup time, completion
# cache stability, aliases actually defined. Everything else in test/ parses
# files; this one runs them.

bats_require_minimum_version 1.5.0
load test_helper/common

setup() {
    setup_test_env
    command -v zsh >/dev/null || skip "zsh not installed"
    # zinit self-bootstraps by cloning from GitHub on first start; only run
    # when a bootstrapped plugin store exists so the test stays offline.
    [[ -d "${XDG_DATA_HOME:-$HOME/.local/share}/zinit" ]] || skip "zinit not bootstrapped (run a shell once)"

    FAKE_HOME="$(mktemp -d)"
    mkdir -p "$FAKE_HOME/.config" "$FAKE_HOME/.local"
    ln -s "$DOTFILES_DIR/.config/zsh" "$FAKE_HOME/.config/zsh"
    ln -s "$DOTFILES_DIR/.config/starship" "$FAKE_HOME/.config/starship"
    ln -s "$DOTFILES_DIR/.config/atuin" "$FAKE_HOME/.config/atuin"
    ln -s "${XDG_DATA_HOME:-$HOME/.local/share}" "$FAKE_HOME/.local/share"
    ln -s "${XDG_CACHE_HOME:-$HOME/.cache}" "$FAKE_HOME/.cache"
    cp "$DOTFILES_DIR/.zshenv" "$FAKE_HOME/.zshenv"
    # ZDOTDIR/XDG_* may be exported by the calling shell; zsh reads
    # $ZDOTDIR/.zshenv in preference to $HOME/.zshenv, so drop them.
    # Use a private compdump so the repo checkout is not written to.
    rm -f "$DOTFILES_DIR/.config/zsh/.zcompdump"*
}

teardown() {
    rm -f "$DOTFILES_DIR/.config/zsh/.zcompdump"*
    rm -rf "$FAKE_HOME"
}

@test "shell-boot: interactive zsh exits 0" {
    run env -u ZDOTDIR -u XDG_CONFIG_HOME -u XDG_DATA_HOME -u XDG_CACHE_HOME HOME="$FAKE_HOME" TERM=xterm zsh -ic exit
    assert_success
}

@test "shell-boot: second start is under the 900ms budget and reuses the completion dump" {
    env -u ZDOTDIR -u XDG_CONFIG_HOME -u XDG_DATA_HOME -u XDG_CACHE_HOME HOME="$FAKE_HOME" TERM=xterm zsh -ic exit
    local dump="$DOTFILES_DIR/.config/zsh/.zcompdump"
    [[ -f "$dump" ]]
    local m1 m2 ms
    m1=$(stat -f %m "$dump" 2>/dev/null || stat -c %Y "$dump")
    ms=$(env -u ZDOTDIR -u XDG_CONFIG_HOME -u XDG_DATA_HOME -u XDG_CACHE_HOME HOME="$FAKE_HOME" TERM=xterm \
        zsh -c 'zmodload zsh/datetime; s=$EPOCHREALTIME; zsh -ic exit; e=$EPOCHREALTIME; printf "%.0f" $(( (e-s)*1000 ))')
    m2=$(stat -f %m "$dump" 2>/dev/null || stat -c %Y "$dump")
    echo "startup: ${ms}ms"
    [[ "$ms" -lt 900 ]]
    [[ "$m1" == "$m2" ]]
}

@test "shell-boot: aliases and completions are live" {
    run --separate-stderr env -u ZDOTDIR -u XDG_CONFIG_HOME -u XDG_DATA_HOME -u XDG_CACHE_HOME HOME="$FAKE_HOME" TERM=xterm \
        zsh -ic 'alias g; print ${#_comps}; whence -w _git'
    assert_success
    [[ "$output" == *"g="*git* ]]
    local comps
    comps=$(echo "$output" | sed -n 2p)
    [[ "$comps" -gt 500 ]]
    [[ "$output" == *"_git: function"* ]]
}
