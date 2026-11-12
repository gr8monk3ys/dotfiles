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
    # The palettes themselves, but never rice.local: that file is the subject.
    for f in "$DOTFILES_DIR"/.config/palette/*.conf; do
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
    has_line "active_color=$("$DOTFILES_DIR/bin/palette" get blue --format 0x)"
    has_line "inactive_color=$("$DOTFILES_DIR/bin/palette" get surface --format 0x)"
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

shell_rice() {
    XDG_CONFIG_HOME="$FAKE_XDG" zsh -f -c '
        STARSHIP_CONFIG=default
        source "$1/.config/zsh/rice.zsh"
        print -r -- "$DOTFILES_RICE $STARSHIP_CONFIG ${aliases[fastfetch]:-none}"
    ' _ "$DOTFILES_DIR"
}

@test "rice: the shell keeps the default prompt with no rice.local" {
    command -v zsh > /dev/null || skip "zsh not installed"
    run shell_rice
    assert_success
    assert_output "monochrome-43 default none"
}

@test "rice: rice.local = danse switches the prompt, fastfetch and cava" {
    command -v zsh > /dev/null || skip "zsh not installed"
    echo danse > "$FAKE_XDG/palette/rice.local"
    run shell_rice
    assert_success
    assert_output "danse $FAKE_XDG/starship/danse.toml fastfetch -c $FAKE_XDG/fastfetch/danse.jsonc"
}

@test "rice: every file the danse switch points at is shipped" {
    for f in starship/danse.toml fastfetch/danse.jsonc cava/danse ghostty/themes/danse \
        btop/themes/danse.theme palette/danse.conf; do
        [[ -f "$DOTFILES_DIR/.config/$f" ]] || { echo "missing .config/$f"; return 1; }
    done
}
