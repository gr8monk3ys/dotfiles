#!/usr/bin/env bats
# The rice switch: ~/.config/palette/rice.local picks the look that
# sketchybar, borders and the starship prompt read at start-up. Monochrome 43
# is the default; `danse` is the one value that opts back in to the older look.
# Every consumer must agree on that, so each is booted against the same fake
# config dir here.

load test_helper/common

setup() {
    FAKE_XDG="$(mktemp -d)"
    mkdir -p "$FAKE_XDG/palette"
    # The palettes and the Rice module, but never rice.local: that file is the subject.
    for f in "$DOTFILES_DIR"/.config/palette/*.conf "$DOTFILES_DIR"/.config/palette/rice.sh; do
        ln -s "$f" "$FAKE_XDG/palette/"
    done
    STUB_BIN="$(mktemp -d)"
    # borders is macOS-only; the stub prints the options it was given.
    printf '#!/bin/sh\nprintf "%%s\\n" "$@"\n' > "$STUB_BIN/borders"
    chmod +x "$STUB_BIN/borders"
}

# bats-assert's assert_line is not in the fallback helpers; this is enough.
has_line() {
    printf '%s\n' "$output" | grep -Fxq -- "$1" || {
        echo "no line '$1' in:"
        printf '%s\n' "$output"
        return 1
    }
}

teardown() {
    rm -rf "$FAKE_XDG" "$STUB_BIN"
}

bar_colour() {
    XDG_CONFIG_HOME="$FAKE_XDG" bash -c \
        '. "$1/.config/sketchybar/colors.sh"; printf "%s %s\n" "$RICE" "$BAR_COLOR"' \
        _ "$DOTFILES_DIR"
}

border_options() {
    XDG_CONFIG_HOME="$FAKE_XDG" PATH="$STUB_BIN:$PATH" \
        bash "$DOTFILES_DIR/.config/borders/bordersrc"
}

@test "rice: sketchybar defaults to monochrome-43 with no rice.local" {
    run bar_colour
    assert_success
    assert_output "monochrome-43 0xff000000"
}

@test "rice: rice.local = danse puts sketchybar back on danse" {
    echo danse > "$FAKE_XDG/palette/rice.local"
    run bar_colour
    assert_success
    assert_output "danse 0xff282c34"
}

@test "rice: an unknown rice.local value falls back to monochrome-43" {
    echo bogus > "$FAKE_XDG/palette/rice.local"
    run bar_colour
    assert_success
    assert_output "monochrome-43 0xff000000"
}

@test "rice: borders defaults to the monochrome hairline" {
    run border_options
    assert_success
    has_line "width=1.0"
    has_line "active_color=0xffffffff"
}

@test "rice: rice.local = danse puts borders back on the blue border" {
    echo danse > "$FAKE_XDG/palette/rice.local"
    run border_options
    assert_success
    has_line "width=5.0"
    has_line "active_color=0xff61afef"
}

@test "rice: the border colours are the palettes' own" {
    run border_options
    has_line "active_color=$(PALETTE=monochrome-43 "$DOTFILES_DIR/bin/palette" get fg --format 0x)"
    has_line "inactive_color=$(PALETTE=monochrome-43 "$DOTFILES_DIR/bin/palette" get inactive --format 0x)"
    echo danse > "$FAKE_XDG/palette/rice.local"
    run border_options
    has_line "active_color=$(PALETTE=danse "$DOTFILES_DIR/bin/palette" get blue --format 0x)"
    has_line "inactive_color=$(PALETTE=danse "$DOTFILES_DIR/bin/palette" get surface --format 0x)"
}

@test "rice: aerospace's top gap clears the monochrome bar plus the outer gap" {
    # TOML cannot read rice.local, so the gaps are the default rice's.
    toml="$DOTFILES_DIR/.config/aerospace/aerospace.toml"
    bar="$(sed -n '/RICE" = monochrome-43/,/^else/p' "$DOTFILES_DIR/.config/sketchybar/sketchybarrc" |
        grep -oE 'height=[0-9]+' | head -n1 | cut -d= -f2)"
    outer="$(grep -E '^outer\.left = ' "$toml" | grep -oE '[0-9]+')"
    top="$(grep -E '^outer\.top = ' "$toml" | grep -oE '[0-9]+')"
    [[ -n "$bar" && -n "$outer" ]]
    [[ "$top" -eq $((bar + outer)) ]]
    grep -qE '^inner\.horizontal = 4$' "$toml"
    grep -qE '^inner\.vertical = 4$' "$toml"
    grep -qE '^outer\.(left|right|bottom) = 8$' "$toml"
}

# shell_rice <platform> [expr]: boot rice.zsh as if on <platform> and print
# expr (default: the rice, the prompt config and the fastfetch alias).
shell_rice() {
    ln -sfn "$DOTFILES_DIR/.config/starship" "$FAKE_XDG/starship"
    ln -sfn "$DOTFILES_DIR/.config/zsh" "$FAKE_XDG/zsh"
    XDG_CONFIG_HOME="$FAKE_XDG" RICE_PLATFORM="$1" zsh -f -c '
        STARSHIP_CONFIG=default
        source "$1/.config/zsh/rice.zsh"
        eval "print -r -- \"$2\""
    ' _ "$DOTFILES_DIR" "${2:-$SHELL_RICE_DEFAULT}"
}
# shellcheck disable=SC2016  # expanded inside the booted zsh, not here
SHELL_RICE_DEFAULT='$DOTFILES_RICE $STARSHIP_CONFIG ${aliases[fastfetch]:-none}'


@test "rice: the shell keeps the default prompt with no rice.local on macOS" {
    command -v zsh > /dev/null || skip "zsh not installed"
    run shell_rice macos
    assert_success
    assert_output "monochrome-43 default none"
}

@test "rice: on Omarchy the shell wears field-notebook, the desktop's rice" {
    # The shell once asked for "any platform" and got monochrome-43 under a
    # Field Notebook desktop.
    command -v zsh > /dev/null || skip "zsh not installed"
    run shell_rice omarchy
    assert_success
    assert_output "field-notebook $FAKE_XDG/starship/field-notebook.toml none"
}

@test "rice: rice.local = danse switches the prompt, fastfetch and cava" {
    command -v zsh > /dev/null || skip "zsh not installed"
    echo danse > "$FAKE_XDG/palette/rice.local"
    run shell_rice macos
    assert_success
    assert_output "danse $FAKE_XDG/starship/danse.toml fastfetch -c $FAKE_XDG/fastfetch/danse.jsonc"
}

@test "rice: the shell points every CLI tool at the rice's own file" {
    command -v zsh > /dev/null || skip "zsh not installed"
    for platform in macos omarchy; do
        rice="$(XDG_CONFIG_HOME="$FAKE_XDG" sh -c '. "$1/.config/palette/rice.sh"; rice_select "$2"; printf %s "$RICE"' _ "$DOTFILES_DIR" "$platform")"
        run shell_rice "$platform" '$BAT_THEME $DELTA_FEATURES $ATUIN_THEME__NAME ${EZA_CONFIG_DIR#$XDG_CONFIG_HOME/} ${YAZI_CONFIG_HOME#$XDG_CONFIG_HOME/}'
        assert_success
        assert_output "$rice rice-$rice $rice eza/rices/$rice yazi/rices/$rice"
        # Each name resolves to a shipped file.
        for f in "bat/themes/$rice.tmTheme" "git/delta/$rice.gitconfig" "atuin/themes/$rice.toml" \
            "eza/rices/$rice/theme.yml" "yazi/rices/$rice/theme.toml" "yazi/rices/$rice/yazi.toml" \
            "yazi/rices/$rice/keymap.toml" "zellij/themes/$rice.kdl" "zathura/rices/$rice/zathurarc" \
            "zsh/rices/$rice.zsh"; do
            [[ -f "$DOTFILES_DIR/.config/$f" ]] || { echo "missing .config/$f"; return 1; }
        done
    done
}

@test "rice: the shell's highlight, fzf and eza colours are the rice's" {
    command -v zsh > /dev/null || skip "zsh not installed"
    run shell_rice omarchy '${ZSH_HIGHLIGHT_STYLES[command]} ${DOTFILES_FZF_COLORS%% *} ${EZA_COLORS%%:*}'
    assert_success
    pen="$(PALETTE=field-notebook "$DOTFILES_DIR/bin/palette" get pen)"
    fg="$(PALETTE=field-notebook "$DOTFILES_DIR/bin/palette" get fg)"
    assert_output "fg=$pen --color=bg:-1,fg:$fg,hl:$(PALETTE=field-notebook "$DOTFILES_DIR/bin/palette" get blue) di=38;2;$(PALETTE=field-notebook "$DOTFILES_DIR/bin/palette" get blue --format rgb)"
}

@test "rice: every file the danse switch points at is shipped" {
    for f in starship/danse.toml fastfetch/danse.jsonc cava/danse ghostty/themes/danse \
        btop/themes/danse.theme palette/danse.conf; do
        [[ -f "$DOTFILES_DIR/.config/$f" ]] || { echo "missing .config/$f"; return 1; }
    done
}

# The Rice module itself: one table, one default per platform.

rice_sh() { sh -c '. "$1/.config/palette/rice.sh"; shift; "$@"; printf "%s\n" "${RICE:-}"' _ "$DOTFILES_DIR" "$@"; }

@test "rice module: defaults are monochrome-43 on macOS and field-notebook on Omarchy" {
    XDG_CONFIG_HOME="$FAKE_XDG" run rice_sh rice_select macos
    assert_output "monochrome-43"
    XDG_CONFIG_HOME="$FAKE_XDG" run rice_sh rice_select omarchy
    assert_output "field-notebook"
}

@test "rice module: a rice that does not ship on the platform falls back to its default" {
    echo danse > "$FAKE_XDG/palette/rice.local"
    XDG_CONFIG_HOME="$FAKE_XDG" run rice_sh rice_select omarchy
    assert_output "field-notebook"
    XDG_CONFIG_HOME="$FAKE_XDG" run rice_sh rice_select macos
    assert_output "danse"
    echo vaporwave > "$FAKE_XDG/palette/rice.local"
    XDG_CONFIG_HOME="$FAKE_XDG" run rice_sh rice_select macos
    assert_output "monochrome-43"
}

@test "rice module: every rice has a palette file, under bash, sh and zsh alike" {
    local r
    for r in $(sh -c '. "$1/.config/palette/rice.sh"; rice_list' _ "$DOTFILES_DIR"); do
        [[ -f "$DOTFILES_DIR/.config/palette/$r.conf" ]] || { echo "no palette for $r"; return 1; }
    done
    command -v zsh > /dev/null || skip "zsh not installed"
    run zsh -c 'source "$1/.config/palette/rice.sh"; rice_list omarchy' _ "$DOTFILES_DIR"
    assert_output "$(printf 'monochrome-43\nfield-notebook')"
}
