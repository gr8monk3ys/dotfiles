#!/usr/bin/env bats
# Property tests for .config/palette/rice.sh, the Rice module sourced by
# POSIX sh, bash and zsh alike. test_rice.bats has the examples; these
# generate rice.local contents and platforms. See test_helper/prop.bash for
# reproducing a failure from its seed.
#
# For every rice.local (missing, empty, whitespace, a valid rice name with
# stray whitespace or extra lines, random words, CRLF) found through
# XDG_CONFIG_HOME or HOME, and every platform (an argument of macos, omarchy
# or "", the RICE_PLATFORM override with those values, or detection):
#   1. rice_select picks a rice that rice_available accepts there;
#   2. it is the file's word exactly when that word is available there,
#      and the platform's rice_default otherwise;
#   3. sh, bash and zsh (when installed) agree on every case.
#
# All cases run inside one process per shell, so the cost is a few process
# starts rather than a few per case.

load test_helper/common
load test_helper/prop

setup() {
    setup_test_env
    # Cases are cheap here (one process per shell, not per case).
    PROP_CASES=$((PROP_CASES * 4))
    prop_init
    # RICE_SH_UNDER_TEST points the property at a mutated copy, to check
    # that it notices (e.g. `read RICE` without -r).
    RICE_SH="${RICE_SH_UNDER_TEST:-$DOTFILES_DIR/.config/palette/rice.sh}"
}

teardown() {
    cleanup_test_env
}

# The driver every shell runs: one line per case in, one line per case out.
# Written in the common subset of POSIX sh and zsh.
write_driver() {
    cat > "$TEST_TEMP_DIR/driver.sh" << 'EOF'
. "$1"
while IFS='|' read -r i loc mode plat; do
    unset XDG_CONFIG_HOME RICE_PLATFORM
    HOME="$2/c$i/home"
    if [ "$loc" = xdg ]; then XDG_CONFIG_HOME="$2/c$i/xdg"; fi
    case "$mode" in
        arg) rice_select "$plat"; p="$plat" ;;
        override) RICE_PLATFORM="$plat"; rice_select; p="$plat" ;;
        detect) rice_select; p="$RICE_PLATFORM" ;;
    esac
    ok=no
    if rice_available "$RICE" "$p"; then ok=yes; fi
    printf '%s|%s|%s|%s\n' "$i" "$RICE" "$p" "$ok"
done < "$2/cases"
EOF
}

# REPLY = rice.local contents (printf %b escapes); FILE_STATE = missing|file.
gen_contents() {
    local ws1 ws2 word
    FILE_STATE="file"
    prop_string $' \t' 0 3
    ws1="$REPLY"
    prop_string $' \t' 0 3
    ws2="$REPLY"
    prop_pick monochrome-43 danse field-notebook
    word="$REPLY"
    prop_rand 11
    case "$REPLY" in
        0) FILE_STATE=missing; REPLY="" ;;
        1) REPLY="" ;;
        2) REPLY="$ws1$ws2\n" ;;
        3) REPLY="$ws1$word$ws2\n" ;;
        4) REPLY="$ws1$word$ws2" ;;                 # no trailing newline
        5) REPLY="$word\nsecond-line\n" ;;
        6) REPLY="\n$word\n" ;;                     # first line blank
        7) REPLY="$word\r\n" ;;                     # CRLF
        8) REPLY="$word $word\n" ;;                 # two words
        9)
            prop_pick Danse danse- field_notebook monochrome monochrome-43x "*" "danse:" \
                ":macos" "dan\\\\se" "-" "danse?" "field-notebook:omarchy"
            REPLY="$ws1$REPLY$ws2\n"
            ;;
        10)
            prop_string "abcdefghijklmnopqrstuvwxyz0123456789-" 1 16
            REPLY="$ws1$REPLY\n"
            ;;
    esac
}

# The word rice_select should read: the first line, IFS whitespace trimmed.
file_word() {
    local f="$1"
    [[ -r "$f" ]] || { REPLY=""; return; }
    IFS= read -r REPLY < "$f" || true
    REPLY="${REPLY#"${REPLY%%[! $'\t']*}"}"
    REPLY="${REPLY%"${REPLY##*[! $'\t']}"}"
}

@test "prop: rice_select picks an available rice, the file word when it can, identically in every shell" {
    local root="$TEST_TEMP_DIR" i loc mode plat dir shell want
    write_driver
    : > "$root/cases"
    for ((PROP_CASE = 1; PROP_CASE <= PROP_CASES; PROP_CASE++)); do
        prop_pick xdg home
        loc="$REPLY"
        prop_pick arg arg override override detect
        mode="$REPLY"
        prop_pick macos omarchy "" linux
        plat="$REPLY"
        mkdir -p "$root/c$PROP_CASE/home" "$root/c$PROP_CASE/xdg"
        if [[ "$loc" == xdg ]]; then dir="$root/c$PROP_CASE/xdg"; else dir="$root/c$PROP_CASE/home/.config"; fi
        gen_contents
        if [[ "$FILE_STATE" == file ]]; then
            mkdir -p "$dir/palette"
            printf '%b' "$REPLY" > "$dir/palette/rice.local"
        fi
        # A decoy where the other location would look, so reading the wrong
        # file shows up as a wrong answer.
        if [[ "$loc" == xdg ]]; then
            mkdir -p "$root/c$PROP_CASE/home/.config/palette"
            echo danse > "$root/c$PROP_CASE/home/.config/palette/rice.local"
        fi
        printf '%s|%s|%s|%s\n' "$PROP_CASE" "$loc" "$mode" "$plat" >> "$root/cases"
    done

    local shells=(sh bash)
    command -v zsh > /dev/null && shells+=(zsh)
    command -v dash > /dev/null && shells+=(dash)
    for shell in "${shells[@]}"; do
        if [[ "$shell" == zsh ]]; then
            zsh -f "$root/driver.sh" "$RICE_SH" "$root" > "$root/out.$shell" 2> "$root/err.$shell" || true
        else
            "$shell" "$root/driver.sh" "$RICE_SH" "$root" > "$root/out.$shell" 2> "$root/err.$shell" || true
        fi
        [[ ! -s "$root/err.$shell" ]] || prop_fail "$shell wrote to stderr: $(cat "$root/err.$shell")" || return
    done

    # 3. every shell agrees with bash, case by case.
    for shell in "${shells[@]}"; do
        if ! cmp -s "$root/out.bash" "$root/out.$shell"; then
            PROP_CASE="$(diff "$root/out.bash" "$root/out.$shell" | grep -m1 -oE '^[<>] [0-9]+' | cut -c3-)"
            prop_fail "bash and $shell disagree: $(diff "$root/out.bash" "$root/out.$shell" | head -4 | tr '\n' ' ')" || return
        fi
    done

    # 1 and 2, against bash's own reading of the same module.
    # shellcheck source=/dev/null
    . "$RICE_SH"
    local rice p ok f
    while IFS='|' read -r PROP_CASE rice p ok; do
        IFS='|' read -r _ loc mode plat < <(sed -n "${PROP_CASE}p" "$root/cases")
        if [[ "$loc" == xdg ]]; then f="$root/c$PROP_CASE/xdg/palette/rice.local"; else f="$root/c$PROP_CASE/home/.config/palette/rice.local"; fi
        [[ "$ok" == yes ]] ||
            prop_fail "$loc/$mode platform '$p': picked '$rice', which rice_available rejects" || return
        file_word "$f"
        case "$p" in macos | omarchy | "") ;; *) p="" ;; esac   # unknown platform = any
        if rice_available "$REPLY" "$p"; then
            want="$REPLY"
        else
            rice_default "$p"
            want="$RICE"
        fi
        [[ "$rice" == "$want" ]] ||
            prop_fail "$loc/$mode platform '$p', rice.local $(od -c "$f" 2> /dev/null | head -2 | tr '\n' ' ' || echo missing): picked '$rice', want '$want'" || return
    done < "$root/out.bash"
    [[ "$(wc -l < "$root/out.bash")" -eq $((PROP_CASES)) ]] || prop_fail "bash driver stopped early" || return
}
