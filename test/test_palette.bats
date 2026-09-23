#!/usr/bin/env bats
# Tests for bin/palette and the configs that consume it.
#
# The palette was ten copies of the same six hex literals with nothing
# connecting them, so "everything matches" was unverifiable. These tests are
# the verification: the data has one home, and no consumer re-types it.

load test_helper/common

# A fixture checkout: a two-colour palette and one template of each kind, so
# the render/check contract is tested against something a retune of the real
# palette cannot move.
make_fixture() {
    FIXTURE="$TEST_TEMP_DIR/checkout"
    mkdir -p "$FIXTURE/.config/palette/templates/app" "$FIXTURE/.config/palette/templates/mixed"
    cat > "$FIXTURE/.config/palette/danse.conf" <<'CONF'
# fixture palette
blue|#61afef|accent
red|#e06a51|error
CONF
    # Whole-file template.
    printf 'accent = {{blue}}\nerror = {{red}}\nbar = {{blue:0x}}\nsgr = {{red:rgb}}\n' \
        > "$FIXTURE/.config/palette/templates/app/theme"
    # Region template, and the hand-edited file it renders into.
    printf 'fg={{blue}}\n' > "$FIXTURE/.config/palette/templates/mixed/rc"
    mkdir -p "$FIXTURE/mixed"
    printf 'hand-written top\n# palette:begin\nstale\n# palette:end\nhand-written bottom\n' \
        > "$FIXTURE/mixed/rc"
}

palette_in() { env DOTFILES_DIR="$FIXTURE" "$DOTFILES_DIR/bin/palette" "$@"; }

setup() {
    setup_test_env
}

teardown() {
    cleanup_test_env
}

@test "render writes whole files and fills regions, and check then passes" {
    make_fixture
    run palette_in render
    assert_success
    assert_output --partial "2 file(s) changed"

    run cat "$FIXTURE/app/theme"
    assert_output "$(printf 'accent = #61afef\nerror = #e06a51\nbar = 0xff61afef\nsgr = 224;106;81')"

    # Only the region is the template's; the rest of the file is left alone.
    run cat "$FIXTURE/mixed/rc"
    assert_output "$(printf 'hand-written top\n# palette:begin\nfg=#61afef\n# palette:end\nhand-written bottom')"

    run palette_in check
    assert_success

    # Idempotent: a second render touches nothing.
    run palette_in render
    assert_output --partial "0 file(s) changed"
}

@test "check fails with a diff when a rendered file is hand-edited" {
    make_fixture
    palette_in render
    sed -i.bak 's/#e06a51/#ff0000/' "$FIXTURE/app/theme" && rm "$FIXTURE/app/theme.bak"
    run palette_in check
    assert_failure
    assert_output --partial "app/theme (committed)"
    assert_output --partial "+error = #e06a51"
}

@test "check fails when two palette colours are swapped in a rendered file" {
    # The old membership test passed this: both hexes were on the palette.
    make_fixture
    palette_in render
    printf 'accent = #e06a51\nerror = #61afef\nbar = 0xff61afef\nsgr = 224;106;81\n' \
        > "$FIXTURE/app/theme"
    run palette_in check
    assert_failure
}

@test "check fails when a region is edited, but not when the rest of the file is" {
    make_fixture
    palette_in render
    printf 'more hand-written\n' >> "$FIXTURE/mixed/rc"
    run palette_in check
    assert_success

    sed -i.bak 's/^fg=.*/fg=#000000/' "$FIXTURE/mixed/rc" && rm "$FIXTURE/mixed/rc.bak"
    run palette_in check
    assert_failure
}

@test "check reports a rendered file that does not exist yet" {
    make_fixture
    palette_in render
    rm "$FIXTURE/app/theme"
    run palette_in check
    assert_failure
    assert_output --partial "missing: app/theme"
}

@test "a region with no end marker is refused, not guessed at" {
    make_fixture
    printf 'top\n# palette:begin\nstale\n' > "$FIXTURE/mixed/rc"
    run palette_in render
    assert_failure
    assert_output --partial "malformed palette region"
}

@test "a literal colour in a template is refused" {
    # That is how off-palette colours got in: typed straight into a theme.
    make_fixture
    printf 'x = #6d8086\n' > "$FIXTURE/.config/palette/templates/app/theme"
    run palette_in check
    assert_failure
    assert_output --partial "literal colour"
}

@test "an unknown colour or format in a template is refused" {
    make_fixture
    printf 'x = {{blu}}\n' > "$FIXTURE/.config/palette/templates/app/theme"
    run palette_in check
    assert_failure
    assert_output --partial "unknown slot"

    printf 'x = {{blue:raw}}\n' > "$FIXTURE/.config/palette/templates/app/theme"
    run palette_in check
    assert_failure
    assert_output --partial "unknown slot"
}

@test "a malformed or duplicated palette entry fails every command" {
    make_fixture
    printf 'blue|#61AFEF|accent\n' > "$FIXTURE/.config/palette/danse.conf"
    run palette_in check
    assert_failure
    assert_output --partial "bad hex"

    printf 'blue|#61afef|accent\nblue|#e06a51|error\n' > "$FIXTURE/.config/palette/danse.conf"
    run palette_in check
    assert_failure
    assert_output --partial "defined twice"

    printf 'blue|#61afef|\n' > "$FIXTURE/.config/palette/danse.conf"
    run palette_in check
    assert_failure
    assert_output --partial "no role"
}

@test "fill expands the three slot formats for scripts" {
    make_fixture
    run bash -c 'printf "{{blue}} {{blue:0x}} {{red:rgb}}\n" | DOTFILES_DIR="$1" "$2/bin/palette" fill' \
        _ "$FIXTURE" "$DOTFILES_DIR"
    assert_success
    assert_output "#61afef 0xff61afef 224;106;81"
}

@test "a retune gives the wallpaper a new cache key; an unchanged palette reuses it" {
    # The wallpaper matte is painted in bg-dark and ultramarine. Keyed on
    # screen size alone, a retune reused the old image. magick is stubbed and
    # the source scan pre-seeded, so nothing is fetched and no desktop is set.
    make_fixture
    printf 'bg-dark|#21252b|ground\nultramarine|#2b4468|fill\n' > "$FIXTURE/.config/palette/danse.conf"
    mkdir -p "$TEST_TEMP_DIR/stub" "$TEST_HOME/.cache/wallpaper"
    printf 'jpg' > "$TEST_HOME/.cache/wallpaper/danse-source.jpg"
    cat > "$TEST_TEMP_DIR/stub/magick" <<'STUB'
#!/bin/sh
for last; do :; done
echo run >> "$HOME/magick-calls"
printf png > "$last"
STUB
    chmod +x "$TEST_TEMP_DIR/stub/magick"
    build() {
        env HOME="$TEST_HOME" DOTFILES_DIR="$FIXTURE" XDG_CACHE_HOME="$TEST_HOME/.cache" \
            XDG_DATA_HOME="$TEST_HOME/.local/share" WALLPAPER_WIDTH=100 WALLPAPER_HEIGHT=50 \
            PATH="$TEST_TEMP_DIR/stub:$PATH" "$DOTFILES_DIR/bin/wallpaper" build 2> /dev/null
    }

    first="$(build)"
    [[ "$(build)" == "$first" ]]
    [[ "$(wc -l < "$TEST_HOME/magick-calls")" -eq 1 ]]

    printf 'bg-dark|#21252b|ground\nultramarine|#31486d|fill\n' > "$FIXTURE/.config/palette/danse.conf"
    second="$(build)"
    [[ -n "$second" && "$second" != "$first" ]]
    [[ "$(wc -l < "$TEST_HOME/magick-calls")" -eq 2 ]]
}

@test "the checkout's rendered files match their templates" {
    run "$DOTFILES_DIR/bin/palette" check
    assert_success
}

@test "palette is executable" {
    [[ -x "$DOTFILES_DIR/bin/palette" ]]
}

@test "get returns the hex for a known colour" {
    run "$DOTFILES_DIR/bin/palette" get blue
    assert_success
    assert_output "#61afef"
}

@test "get on an unknown colour fails rather than returning empty" {
    # A typo in a theme should be loud. Returning "" paints something black
    # and looks like a design choice.
    run "$DOTFILES_DIR/bin/palette" get nosuchcolour
    assert_failure
    assert_output --partial "no such colour"
}

@test "the 0x format is what sketchybar wants" {
    run "$DOTFILES_DIR/bin/palette" get blue --format 0x
    assert_success
    assert_output "0xff61afef"
}

@test "the rgb format is what EZA_COLORS wants" {
    run "$DOTFILES_DIR/bin/palette" get blue --format rgb
    assert_success
    assert_output "97;175;239"
}

@test "an unknown format is rejected" {
    run "$DOTFILES_DIR/bin/palette" get blue --format bogus
    assert_failure
    assert_output --partial "unknown format"
}

@test "every palette entry is a valid six-digit hex" {
    run bash -c '
        set -euo pipefail
        status=0
        while IFS="	" read -r name hex role; do
            [[ "$hex" =~ ^\#[0-9a-f]{6}$ ]] || { echo "bad hex for $name: $hex"; status=1; }
            [[ -n "$role" ]] || { echo "no role documented for $name"; status=1; }
        done < <("$1/bin/palette" list)
        exit $status
    ' _ "$DOTFILES_DIR"
    assert_success
}

@test "palette names are unique" {
    run bash -c '"$1/bin/palette" names | sort | uniq -d' _ "$DOTFILES_DIR"
    assert_success
    assert_output ""
}

@test "a sourced sketchybar colors.sh defines its roles from the palette" {
    # Asserted on the sourced file, not by grepping it: the old runtime parser
    # left every role empty when the palette file was unreachable, which
    # sketchybar draws as black. env -i is the minimal environment sketchybar
    # gives its scripts.
    run env -i bash -c 'source "$1/.config/sketchybar/colors.sh"; printf "%s %s %s %s\n" "$BAR_COLOR" "$BLUE" "$RED" "$ULTRAMARINE"' \
        _ "$DOTFILES_DIR"
    assert_success
    assert_output "$(printf '{{bg:0x}} {{blue:0x}} {{vermilion:0x}} {{ultramarine:0x}}\n' | "$DOTFILES_DIR/bin/palette" fill)"
}

@test "every truecolor triple in EZA_COLORS is a palette colour" {
    # EZA_COLORS encodes colours as decimal SGR triples, so a hex-based grep
    # cannot see them: a retune that rewrote every "#e06c75" left "224;108;117"
    # behind in .zshenv and the listing kept the old red.
    run bash -c '
        set -euo pipefail
        repo="$1"
        allowed=""
        while IFS="	" read -r name hex role; do
            allowed="$allowed $(printf "%d;%d;%d" "0x${hex:1:2}" "0x${hex:3:2}" "0x${hex:5:2}")"
        done < <("$repo/bin/palette" list)
        status=0
        for triple in $(grep -oE "38;2;[0-9]+;[0-9]+;[0-9]+" "$repo/.zshenv" | sed "s/^38;2;//" | sort -u); do
            case " $allowed " in
                *" $triple "*) ;;
                *) echo "EZA_COLORS uses $triple, which is not in the palette"; status=1 ;;
            esac
        done
        exit $status
    ' _ "$DOTFILES_DIR"
    assert_success
}

@test "every colour in a generated theme is a palette colour" {
    # ghostty/themes/danse, btop/themes/danse.theme and cava/config are all
    # derived from the palette by hand-running `palette get`. Nothing re-runs
    # that, so this is what keeps them true — and it is what catches a colour
    # typed straight into a theme instead of taken from the palette.
    run bash -c '
        set -euo pipefail
        repo="$1"
        allowed="$("$repo/bin/palette" list | cut -f2)"
        status=0
        for f in .config/ghostty/themes/danse \
                 .config/btop/themes/danse.theme \
                 .config/cava/config; do
            [[ -f "$repo/$f" ]] || { echo "missing generated theme: $f"; status=1; continue; }
            for hex in $(grep -oE "#[0-9a-f]{6}" "$repo/$f" | sort -u); do
                printf "%s\n" "$allowed" | grep -Fxq "$hex" \
                    || { echo "$f uses $hex, which is not in the palette"; status=1; }
            done
        done
        exit $status
    ' _ "$DOTFILES_DIR"
    assert_success
}

@test "a booted neovim renders the palette, not onedark.nvim's own hexes" {
    # Boots the checkout under test, not whatever ~/.config/nvim points at:
    # XDG_CONFIG_HOME is this checkout's .config. Plugins still load from the
    # real data dir (read-only here); state and cache go to the test's temp
    # dir so the boot writes nothing outside it.
    command -v nvim > /dev/null || skip "nvim not installed"
    want="$(printf '{{vermilion}} {{bg}} {{diff-add}}\n' | "$DOTFILES_DIR/bin/palette" fill)"
    run env XDG_CONFIG_HOME="$DOTFILES_DIR/.config" \
        XDG_STATE_HOME="$TEST_TEMP_DIR/state" XDG_CACHE_HOME="$TEST_TEMP_DIR/cache" \
        nvim --headless -i NONE -c 'lua
            local function hl(name, key)
                local v = vim.api.nvim_get_hl(0, { name = name, link = false })[key]
                return v and string.format("#%06x", v) or "none"
            end
            io.stderr:write(hl("ErrorMsg", "fg") .. " " .. hl("Normal", "bg") .. " " .. hl("DiffAdd", "bg"))' \
        -c qa
    assert_success
    assert_output "$want"
}

@test "every workspace sketchybar draws is declared persistent in aerospace" {
    # config-version 2 made persistent-workspaces the source of truth: an
    # undeclared workspace disappears when its last window closes. SketchyBar's
    # items/spaces.sh draws one indicator per workspace regardless, so a
    # workspace dropped from that list leaves a dead indicator on the bar and
    # a keybinding that lands nowhere.
    run bash -c '
        set -euo pipefail
        repo="$1"
        toml="$repo/.config/aerospace/aerospace.toml"
        # The declared list, one name per line.
        declared="$(sed -n "/^persistent-workspaces = \[/,/^\]/p" "$toml" \
            | grep -oE "\"[^\"]+\"" | tr -d "\"")"
        status=0
        # SPACE_ICONS in spaces.sh is what the bar actually draws.
        drawn="$(grep -oE "^SPACE_ICONS=\(.*\)" "$repo/.config/sketchybar/items/spaces.sh" \
            | grep -oE "\"[^\"]+\"" | tr -d "\"")"
        [[ -n "$drawn" ]] || { echo "could not read SPACE_ICONS from spaces.sh"; exit 1; }
        for ws in $drawn; do
            printf "%s\n" "$declared" | grep -Fxq "$ws" \
                || { echo "sketchybar draws workspace $ws, aerospace does not persist it"; status=1; }
        done
        exit $status
    ' _ "$DOTFILES_DIR"
    assert_success
}
