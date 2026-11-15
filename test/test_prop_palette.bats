#!/usr/bin/env bats
# Property tests for bin/palette, over every palette this checkout ships
# rather than the default one (test_palette.bats has the examples). See
# test_helper/prop.bash for reproducing a failure from its seed.
#
# Invariants:
#   1. Every palette file parses: each data line is name|#rrggbb|role with a
#      kebab-case name, and names are unique.
#   2. For every listed name and every --format, `palette get` round-trips:
#      hex is the listed hex, raw/0x/rgb encode the same three bytes.
#   3. `palette get` with any generated argument vector either prints exactly
#      one line and exits 0, or prints nothing on stdout, exits non-zero and
#      says why on stderr. An unknown name or format never yields an empty
#      success or a silent failure.

load test_helper/common
load test_helper/prop

setup() {
    setup_test_env
    prop_init
    PALETTE_BIN="$DOTFILES_DIR/bin/palette"
}

teardown() {
    cleanup_test_env
}

palettes() { "$PALETTE_BIN" palettes; }

@test "prop: every palette file parses as name|#rrggbb|role with unique names" {
    local p f lineno line names
    for p in $(palettes); do
        f="$DOTFILES_DIR/.config/palette/$p.conf"
        lineno=0
        names=" "
        while IFS= read -r line || [[ -n "$line" ]]; do
            lineno=$((lineno + 1))
            [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue
            [[ "$line" =~ ^([a-z][a-z0-9-]*)\|#[0-9a-fA-F]{6}\|[^|]+$ ]] ||
                prop_fail "$p.conf:$lineno does not parse: $line" || return
            [[ "$names" != *" ${BASH_REMATCH[1]} "* ]] ||
                prop_fail "$p.conf:$lineno repeats ${BASH_REMATCH[1]}" || return
            names+="${BASH_REMATCH[1]} "
        done < "$f"
        [[ "$names" != " " ]] || prop_fail "$p.conf has no colours" || return
    done
}

@test "prop: palette get round-trips every listed name in every format" {
    local p name hex role raw got r g b
    for p in $(palettes); do
        [[ "$(PALETTE="$p" "$PALETTE_BIN" names)" == "$(PALETTE="$p" "$PALETTE_BIN" list | cut -f1)" ]] ||
            prop_fail "$p: names and list disagree" || return
        while IFS=$'\t' read -r name hex role; do
            raw="${hex#\#}"
            got="$(PALETTE="$p" "$PALETTE_BIN" get "$name")"
            [[ "$got" == "$hex" ]] || prop_fail "$p $name: hex '$got', list says '$hex'" || return
            got="$(PALETTE="$p" "$PALETTE_BIN" get "$name" --format raw)"
            [[ "$got" == "$raw" ]] || prop_fail "$p $name: raw '$got', want '$raw'" || return
            got="$(PALETTE="$p" "$PALETTE_BIN" get "$name" --format 0x)"
            [[ "$got" == "0xff$raw" ]] || prop_fail "$p $name: 0x '$got', want '0xff$raw'" || return
            got="$(PALETTE="$p" "$PALETTE_BIN" get "$name" --format rgb)"
            IFS=';' read -r r g b <<< "$got"
            [[ "$r" =~ ^[0-9]+$ && "$g" =~ ^[0-9]+$ && "$b" =~ ^[0-9]+$ ]] &&
                ((r < 256 && g < 256 && b < 256)) ||
                prop_fail "$p $name: rgb '$got' is not three bytes" || return
            [[ "$(printf '%02x%02x%02x' "$r" "$g" "$b")" == "$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]')" ]] ||
                prop_fail "$p $name: rgb '$got' does not encode $hex" || return
        done < <(PALETTE="$p" "$PALETTE_BIN" list)
    done
}

@test "prop: palette get prints one line or fails loudly, for any argument vector" {
    local p names argv n k rc out err
    for ((PROP_CASE = 1; PROP_CASE <= PROP_CASES; PROP_CASE++)); do
        # shellcheck disable=SC2046 # palette names are single words
        prop_pick $(palettes)
        p="$REPLY"
        # shellcheck disable=SC2207 # names are kebab-case words
        names=($(PALETTE="$p" "$PALETTE_BIN" names))
        argv=()
        prop_rand 4
        n="$REPLY"
        for ((k = 0; k < n; k++)); do
            prop_rand 4
            case "$REPLY" in
                0) prop_pick "${names[@]}" ;;
                1) prop_pick --format --format hex raw 0x rgb ;;
                2) prop_string "abcdefghijklmnopqrstuvwxyz-" 1 10 ;;
                3) prop_pick "" " " "-" "--" "--formats" "HEX" "bg|#000000" "*" "-h" $'\n' ;;
            esac
            argv+=("$REPLY")
        done
        rc=0
        out="$(PALETTE="$p" "$PALETTE_BIN" get "${argv[@]+"${argv[@]}"}" 2> "$TEST_TEMP_DIR/err")" || rc=$?
        err="$(cat "$TEST_TEMP_DIR/err")"
        local shown
        shown="$(printf '%q ' "${argv[@]+"${argv[@]}"}")"
        if ((rc == 0)); then
            [[ -n "$out" && "$out" != *$'\n'* ]] ||
                prop_fail "PALETTE=$p palette get $shown: exit 0 with output [$out]" || return
        else
            [[ -z "$out" ]] || prop_fail "PALETTE=$p palette get $shown: exit $rc but printed [$out]" || return
            [[ -n "$err" ]] || prop_fail "PALETTE=$p palette get $shown: exit $rc with no message" || return
        fi
    done
}
