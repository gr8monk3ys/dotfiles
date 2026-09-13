#!/usr/bin/env bats
# Tests for bin/palette and the configs that consume it.
#
# The palette was ten copies of the same six hex literals with nothing
# connecting them, so "everything matches" was unverifiable. These tests are
# the verification: the data has one home, and no consumer re-types it.

load test_helper/common

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
        names="$("$repo/bin/palette" names | tr "[:lower:]-" "[:upper:]_")"
        status=0
        for var in $(grep -oE "\$PAL_[A-Z_]+" "$repo/.config/sketchybar/colors.sh" | sort -u); do
            want="${var#\$PAL_}"
            printf "%s\n" "$names" | grep -Fxq "$want" || { echo "colors.sh wants \$PAL_$want, palette has no such colour"; status=1; }
        done
        exit $status
    ' _ "$DOTFILES_DIR"
    assert_success
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

@test "every colour in the ghostty theme is a palette colour" {
    # ghostty/themes/danse is derived from the palette by hand-running
    # `palette get`. Nothing re-runs that, so this is what keeps it true.
    run bash -c '
        set -euo pipefail
        repo="$1"
        allowed="$("$repo/bin/palette" list | cut -f2)"
        status=0
        for hex in $(grep -oE "#[0-9a-f]{6}" "$repo/.config/ghostty/themes/danse" | sort -u); do
            printf "%s\n" "$allowed" | grep -Fxq "$hex" || { echo "ghostty theme uses $hex, which is not in the palette"; status=1; }
        done
        exit $status
    ' _ "$DOTFILES_DIR"
    assert_success
}
