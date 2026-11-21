#!/usr/bin/env bats
# Tests for bin/palette and the configs that consume it.
#
# The palette was ten copies of the same six hex literals with nothing
# connecting them, so "everything matches" was unverifiable. These tests are
# the verification: the data has one home, and no consumer re-types it.

load test_helper/common

# bin/palette's default is the machine's active Rice (ADR 0003), so a test
# that wants a particular palette names it. The default has its own tests.
setup() {
    export PALETTE=danse
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

# Found by test_prop_palette.bats: `get <name> --format` with no value exited
# 1 with nothing on stderr (set -e killed the script at `shift 2`).
@test "get --format with no value says so" {
    run "$DOTFILES_DIR/bin/palette" get blue --format
    assert_failure
    assert_output --partial "--format needs a value"
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

@test "sketchybar colors.sh contains no literal hex colours" {
    # Drift guard: the bar's colours must come from the palette, not from a
    # copy that silently stops matching the prompt and the background.
    run grep -nE '0x[0-9a-fA-F]{8}|#[0-9a-fA-F]{6}' \
        "$DOTFILES_DIR/.config/sketchybar/colors.sh"
    # grep exits 1 when it finds nothing, which is what we want — except for
    # the fully transparent sentinel, which is not a palette colour.
    if [[ "$status" -eq 0 ]]; then
        run bash -c 'printf "%s\n" "$1" | grep -v "0x00000000"' _ "$output"
        assert_output ""
    fi
}

@test "every colour sketchybar references exists in the palette" {
    run bash -c '
        set -euo pipefail
        repo="$1"
        # colors.sh maps danse by default and monochrome-43 when opted in
        # (palette/rice.local), so a name must exist in one of the two.
        names="$({ "$repo/bin/palette" names; PALETTE=monochrome-43 "$repo/bin/palette" names; } | tr "[:lower:]-" "[:upper:]_")"
        status=0
        for var in $(grep -oE "\$PAL_[A-Z_]+" "$repo/.config/sketchybar/colors.sh" | sort -u); do
            want="${var#\$PAL_}"
            grep -Fxq "$want" <<< "$names" || { echo "colors.sh wants \$PAL_$want, palette has no such colour"; status=1; }
        done
        exit $status
    ' _ "$DOTFILES_DIR"
    assert_success
}

@test "every truecolor triple in each rice's EZA_COLORS is that rice's colour" {
    # EZA_COLORS encodes colours as decimal SGR triples, so a hex-based grep
    # cannot see them: a retune that rewrote every "#e06c75" left "224;108;117"
    # behind and the listing kept the old red. EZA_COLORS now lives in each
    # rice's rendered zsh file.
    run bash -c '
        set -euo pipefail
        repo="$1"
        status=0
        for rice in danse field-notebook monochrome-43; do
            f="$repo/.config/zsh/rices/$rice.zsh"
            grep -q "^export EZA_COLORS=" "$f" || { echo "$f sets no EZA_COLORS"; status=1; continue; }
            allowed=""
            while IFS="	" read -r name hex role; do
                allowed="$allowed $(printf "%d;%d;%d" "0x${hex:1:2}" "0x${hex:3:2}" "0x${hex:5:2}")"
            done < <(PALETTE="$rice" "$repo/bin/palette" list)
            for triple in $(grep -oE "38;2;[0-9]+;[0-9]+;[0-9]+" "$f" | sed "s/^38;2;//" | sort -u); do
                case " $allowed " in
                    *" $triple "*) ;;
                    *) echo "$rice EZA_COLORS uses $triple, which is not in its palette"; status=1 ;;
                esac
            done
        done
        exit $status
    ' _ "$DOTFILES_DIR"
    assert_success
}

@test "rice-themes: every rendered theme is up to date with its template" {
    # The outputs are committed so a fresh clone needs no render step; this is
    # what stops one drifting from its template or being edited by hand.
    run "$DOTFILES_DIR/bin/rice-themes" check
    assert_success
}

@test "rice-themes: every rendered theme uses only its own rice's colours" {
    # The rendered set is rice-themes' own explicit table (ADR 0001); each
    # file is checked against the palette of the rice it was rendered for.
    run bash -c '
        set -euo pipefail
        repo="$1"
        status=0 n=0
        while IFS="	" read -r template rice f; do
            n=$((n + 1))
            allowed="$(PALETTE="$rice" "$repo/bin/palette" list | cut -f2)"
            [[ -f "$repo/$f" ]] || { echo "missing rendered theme: $f"; status=1; continue; }
            for hex in $(grep -oiE "#[0-9a-f]{6}" "$repo/$f" | tr "[:upper:]" "[:lower:]" | sort -u); do
                grep -Fxq "$hex" <<< "$allowed" \
                    || { echo "$f uses $hex, which is not in the $rice palette"; status=1; }
            done
        done < <("$repo/bin/rice-themes" list)
        [[ "$n" -ge 26 ]] || { echo "rice-themes lists only $n files"; status=1; }
        exit $status
    ' _ "$DOTFILES_DIR"
    assert_success
}

@test "rice-themes: two rices render the same template differently" {
    # A role map that silently fell back to danse would pass every check
    # above; the rice switch has to actually change the colours.
    run diff -q "$DOTFILES_DIR/.config/bat/themes/danse.tmTheme" \
        "$DOTFILES_DIR/.config/bat/themes/field-notebook.tmTheme"
    assert_failure
    run grep -c "$(PALETTE=field-notebook "$DOTFILES_DIR/bin/palette" get pen)" \
        "$DOTFILES_DIR/.config/zsh/rices/field-notebook.zsh"
    assert_success
}

@test "roles: every rice maps every role to one of its own colours" {
    run bash -c '
        set -euo pipefail
        repo="$1"
        roles="$(PALETTE=danse "$repo/bin/palette" names | sort)"
        status=0
        for rice in $(sh -c ". \"\$1/.config/palette/rice.sh\"; rice_list \"\"" _ "$repo"); do
            mapped="$(PALETTE="$rice" "$repo/bin/palette" roles)" \
                || { echo "$rice: role map unreadable"; status=1; continue; }
            got="$(printf "%s\n" "$mapped" | cut -f1 | sort)"
            [[ "$got" == "$roles" ]] || { echo "$rice: roles differ from danse names:"; diff <(echo "$roles") <(echo "$got") || true; status=1; }
        done
        exit $status
    ' _ "$DOTFILES_DIR"
    assert_success
}

@test "roles: danse's role map is the identity" {
    # This is what makes danse render exactly as it did before the templates.
    run bash -c 'PALETTE=danse "$1/bin/palette" roles | awk -F "\t" "\$1 != \$2"' _ "$DOTFILES_DIR"
    assert_success
    assert_output ""
}

@test "role resolves through the rice's map" {
    PALETTE=field-notebook run "$DOTFILES_DIR/bin/palette" role green
    assert_success
    assert_output "$(PALETTE=field-notebook "$DOTFILES_DIR/bin/palette" get pen)"
    PALETTE=field-notebook run "$DOTFILES_DIR/bin/palette" role nosuchrole
    assert_failure
}

@test "every colour in a generated theme is a palette colour" {
    # The theme files below are all derived from a palette by hand-running
    # `palette get`. Nothing re-runs that, so this is what keeps them true —
    # and it is what catches a colour typed straight into a theme instead of
    # taken from the palette. Each file is checked against its own palette.
    run bash -c '
        set -euo pipefail
        repo="$1"
        status=0
        while read -r pal f; do
            [[ -n "$pal" ]] || continue
            allowed="$(PALETTE="$pal" "$repo/bin/palette" list | cut -f2)"
            [[ -f "$repo/$f" ]] || { echo "missing generated theme: $f"; status=1; continue; }
            for hex in $(grep -oE "#[0-9a-f]{6}" "$repo/$f" | sort -u); do
                grep -Fxq "$hex" <<< "$allowed" \
                    || { echo "$f uses $hex, which is not in the $pal palette"; status=1; }
            done
        done <<THEMES
danse         .config/ghostty/themes/danse
danse         .config/btop/themes/danse.theme
danse         .config/cava/danse
danse         windows/glazewm/config.yaml
danse         windows/zebar/danse/styles.css
danse         windows/windows-terminal/danse.json.tpl
monochrome-43 .config/ghostty/themes/monochrome-43
monochrome-43 .config/btop/themes/monochrome-43.theme
monochrome-43 .config/cava/config
monochrome-43 omarchy/rices/monochrome-43/theme/colors.toml
field-notebook omarchy/rices/field-notebook/theme/colors.toml
field-notebook omarchy/rices/field-notebook/share/make-wallpapers.sh
monochrome-43 .config/starship/starship.toml
monochrome-43 .config/ghostty/config
monochrome-43 .config/starship/monochrome-43.toml
THEMES
        exit $status
    ' _ "$DOTFILES_DIR"
    assert_success
}

@test "every colour in the spicetify theme is a monochrome-43 colour" {
    # Spicetify wants bare hex, so the generated-theme check above (which
    # looks for #rrggbb) cannot see these values.
    run bash -c '
        set -euo pipefail
        allowed="$(PALETTE=monochrome-43 "$1/bin/palette" list | cut -f2)"
        status=0
        for hex in $(sed -nE "s/^[a-z-]+[[:space:]]*=[[:space:]]*([0-9a-f]{6})[[:space:]]*$/\1/p" \
                "$1/spicetify/Themes/monochrome-43/color.ini" | sort -u); do
            grep -Fxq "#$hex" <<< "$allowed" \
                || { echo "color.ini uses $hex, not in monochrome-43"; status=1; }
        done
        n="$(grep -cE "^[a-z-]+[[:space:]]*=" "$1/spicetify/Themes/monochrome-43/color.ini")"
        [[ "$n" -gt 0 ]] || { echo "no values parsed from color.ini"; status=1; }
        exit $status
    ' _ "$DOTFILES_DIR"
    assert_success
}

# Boot this checkout's Neovim config against a fake config dir whose
# rice.local says $1, and print "<Normal bg> <ErrorMsg fg> <String fg>".
# Plugins come from the real data dir; RICE_PLATFORM="" makes every rice
# available whatever machine runs this.
nvim_colours() {
    local xdg
    xdg="$(mktemp -d)"
    mkdir -p "$xdg/palette"
    # Never link a rice.local: writing it below would write into the checkout.
    ln -s "$DOTFILES_DIR"/.config/palette/*.conf "$DOTFILES_DIR"/.config/palette/*.roles \
        "$DOTFILES_DIR"/.config/palette/rice.sh "$xdg/palette/"
    ln -s "$DOTFILES_DIR/.config/nvim" "$xdg/nvim"
    printf '%s\n' "$1" > "$xdg/palette/rice.local"
    XDG_CONFIG_HOME="$xdg" RICE_PLATFORM="" nvim --headless \
        -c 'lua local function hl(n, k) local v = vim.api.nvim_get_hl(0, { name = n, link = false })[k]; return v and string.format("#%06x", v) or "none" end; io.stderr:write(hl("Normal", "bg") .. " " .. hl("ErrorMsg", "fg") .. " " .. hl("String", "fg"))' \
        -c qa 2>&1
    rm -rf "$xdg"
}

@test "a booted neovim wears each rice's own colours" {
    # Computed against the palette rather than a literal, so retuning a colour
    # fails here instead of silently leaving the editor behind. nvim was once
    # the one window where "everything matches" was false; then it stayed on
    # danse whatever the desktop rice was (ADR 0003 ended that).
    command -v nvim > /dev/null || skip "nvim not installed"
    [[ -d "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/onedark.nvim" ]] || skip "onedark.nvim not installed"
    for rice in danse field-notebook monochrome-43; do
        role() { PALETTE="$rice" "$DOTFILES_DIR/bin/palette" role "$1"; }
        # danse keeps onedark's own ground (#282c34, which is danse's bg).
        run nvim_colours "$rice"
        assert_success
        assert_output "$(role bg) $(role vermilion) $(role green)"
    done
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
            grep -Fxq "$ws" <<< "$declared" \
                || { echo "sketchybar draws workspace $ws, aerospace does not persist it"; status=1; }
        done
        exit $status
    ' _ "$DOTFILES_DIR"
    assert_success
}

@test "PALETTE selects another palette file by name" {
    PALETTE=monochrome-43 run "$DOTFILES_DIR/bin/palette" get bg
    assert_success
    assert_output "#000000"
    PALETTE=danse run "$DOTFILES_DIR/bin/palette" get bg
    assert_output "#282c34"
}

@test "with no PALETTE, palette reads the active rice's palette" {
    # ADR 0003: the default describes what the machine shows.
    unset PALETTE
    xdg="$(mktemp -d)"
    mkdir -p "$xdg/palette"
    XDG_CONFIG_HOME="$xdg" RICE_PLATFORM=omarchy run "$DOTFILES_DIR/bin/palette" get bg
    assert_output "$(PALETTE=field-notebook "$DOTFILES_DIR/bin/palette" get bg)"
    XDG_CONFIG_HOME="$xdg" RICE_PLATFORM=macos run "$DOTFILES_DIR/bin/palette" get bg
    assert_output "$(PALETTE=monochrome-43 "$DOTFILES_DIR/bin/palette" get bg)"
    echo danse > "$xdg/palette/rice.local"
    XDG_CONFIG_HOME="$xdg" RICE_PLATFORM=macos run "$DOTFILES_DIR/bin/palette" get bg
    assert_output "$(PALETTE=danse "$DOTFILES_DIR/bin/palette" get bg)"
    rm -rf "$xdg"
}

@test "PALETTE refuses a name that is a path" {
    PALETTE=../danse run "$DOTFILES_DIR/bin/palette" get bg
    assert_failure
    assert_output --partial "bad palette name"
}

@test "palettes lists every shipped palette" {
    run "$DOTFILES_DIR/bin/palette" palettes
    assert_success
    assert_output --partial "danse"
    assert_output --partial "monochrome-43"
}

@test "every entry in every palette is a valid six-digit hex with a role" {
    run bash -c '
        set -euo pipefail
        status=0
        for p in $("$1/bin/palette" palettes); do
            while IFS="	" read -r name hex role; do
                [[ "$hex" =~ ^\#[0-9a-f]{6}$ ]] || { echo "$p: bad hex for $name: $hex"; status=1; }
                [[ -n "$role" ]] || { echo "$p: no role documented for $name"; status=1; }
            done < <(PALETTE="$p" "$1/bin/palette" list)
            dupes="$(PALETTE="$p" "$1/bin/palette" names | sort | uniq -d)"
            [[ -z "$dupes" ]] || { echo "$p: duplicate names: $dupes"; status=1; }
        done
        exit $status
    ' _ "$DOTFILES_DIR"
    assert_success
}
