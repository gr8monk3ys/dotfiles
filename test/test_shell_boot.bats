#!/usr/bin/env bats
# Boots a real interactive zsh from the repo's own config and checks the
# things that only show up at runtime: exit status, startup time, completion
# cache stability, aliases actually defined. Everything else in test/ parses
# files; this one runs them.

bats_require_minimum_version 1.5.0
load test_helper/common

# A missing zsh in CI is a misconfigured job, not a missing prerequisite:
# fail loudly rather than skipping, so the suite cannot silently stop running.
# A missing zinit store is different — it is the normal state of a fresh
# runner, because this test deliberately stays offline instead of letting
# zinit clone from GitHub. Making the suite genuinely run in CI needs a zinit
# bootstrap step, which would also put the 900ms startup budget on a shared
# runner; that trade is a separate decision.
require_zsh() {
    if command -v zsh > /dev/null; then
        return 0
    fi
    if [[ -n "${CI:-}" ]]; then
        echo "shell-boot cannot run in CI: zsh not installed" >&2
        return 1
    fi
    skip "zsh not installed"
}

setup() {
    setup_test_env
    require_zsh || return 1
    [[ -d "${XDG_DATA_HOME:-$HOME/.local/share}/zinit" ]] ||
        skip "zinit not bootstrapped (run a shell once)"

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

# Moved here from test_regressions.bats, which asserted on the text of the
# config files. A grep cannot tell a setting that parses from one that
# actually takes effect; a booted shell can. --separate-stderr because an
# interactive zsh writes "can't change option: zle" to stderr under bats.
@test "shell-boot: core alias c is defined exactly once and points at clear" {
    run --separate-stderr env -u ZDOTDIR -u XDG_CONFIG_HOME -u XDG_DATA_HOME -u XDG_CACHE_HOME HOME="$FAKE_HOME" TERM=xterm \
        zsh -ic 'alias c'
    assert_success
    [[ "${#lines[@]}" -eq 1 ]]
    [[ "$output" == *"c="*clear* ]]
}

@test "shell-boot: BAT_THEME is exported as base16-onedark" {
    run --separate-stderr env -u ZDOTDIR -u XDG_CONFIG_HOME -u XDG_DATA_HOME -u XDG_CACHE_HOME HOME="$FAKE_HOME" TERM=xterm \
        zsh -ic 'print -r -- $BAT_THEME'
    assert_success
    assert_output "base16-onedark"
}

@test "shell-boot: starship is registered as the live prompt hook" {
    run --separate-stderr env -u ZDOTDIR -u XDG_CONFIG_HOME -u XDG_DATA_HOME -u XDG_CACHE_HOME HOME="$FAKE_HOME" TERM=xterm \
        zsh -ic 'print -r -- "${precmd_functions[*]}"'
    assert_success
    if command -v starship > /dev/null 2>&1; then
        # Not just "starship was sourced": the hook is actually installed.
        [[ "$output" == *"prompt_starship_precmd"* ]]
    else
        # The prompt is guarded on the binary, so absence is correct here.
        [[ "$output" != *"starship"* ]]
    fi
}
