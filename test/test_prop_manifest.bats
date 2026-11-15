#!/usr/bin/env bats
# Property tests for bin/manifest: invariants checked against generated
# manifests rather than the real ones (test_manifest.bats has the examples,
# test_packages.bats checks the real files). See test_helper/prop.bash for
# the generator and how to reproduce a failure from its seed.
#
# Invariants:
#   1. For a manifest of valid entries, comments, blank and whitespace-only
#      lines, `manifest list <kind>` prints exactly the entries' names, in
#      file order, and nothing on stderr.
#   2. Any invalid line makes it exit non-zero and name that line
#      (<file>:<lineno>:) on stderr; it never names a valid line.
#   3. `list rice-pacman|rice-aur [rice]` prints that rice's names, or every
#      rice's in directory order when none is named.
#   4. A rice argument that is not a plain name (path characters, spaces,
#      upper case, a trailing newline) is refused with status 2 and no
#      output, even when the path it spells exists.

load test_helper/common
load test_helper/prop

setup() {
    setup_test_env
    FIXTURE="$TEST_TEMP_DIR/root"
    mkdir -p "$FIXTURE/install" "$FIXTURE/omarchy/rices"
    prop_init
}

teardown() {
    cleanup_test_env
}

# Characters no kind's name grammar allows.
BAD_CHARS='!$*;=,'

kind_file() {
    case "$1" in
        brew) echo Brewfile ;;
        cask) echo Caskfile ;;
        cask-extra) echo Caskfile.extra ;;
        npm) echo npmfile ;;
        rust) echo Rustfile ;;
        pacman) echo pacmanfile ;;
        code) echo Codefile ;;
        winget) echo wingetfile ;;
    esac
}

LOWER=abcdefghijklmnopqrstuvwxyz
UPPER=ABCDEFGHIJKLMNOPQRSTUVWXYZ
DIGIT=0123456789

# REPLY = a name valid for <kind>, built from that kind's grammar.
gen_name() {
    local head tail first
    case "$1" in
        brew | cask | cask-extra)
            prop_string "$LOWER$UPPER$DIGIT@._+-" 1 14
            ;;
        npm)
            prop_string "@$LOWER$DIGIT" 1 1
            first="$REPLY"
            prop_string "$LOWER$DIGIT._/-" 0 14
            REPLY="$first$REPLY"
            ;;
        rust)
            prop_string "$LOWER$DIGIT" 1 1
            first="$REPLY"
            prop_string "$LOWER${DIGIT}_-" 0 14
            REPLY="$first$REPLY"
            ;;
        pacman | rice-pacman | rice-aur)
            prop_string "$LOWER$DIGIT" 1 1
            first="$REPLY"
            prop_string "$LOWER$DIGIT._+-" 0 14
            REPLY="$first$REPLY"
            ;;
        code)
            prop_string "$LOWER$UPPER$DIGIT-" 1 10
            head="$REPLY"
            prop_string "$LOWER$UPPER$DIGIT-" 1 10
            REPLY="$head.$REPLY"
            ;;
        winget)
            prop_string "$LOWER$UPPER$DIGIT" 1 1
            first="$REPLY"
            prop_string "$LOWER$UPPER$DIGIT-" 0 8
            head="$first$REPLY"
            prop_string "$LOWER$UPPER$DIGIT" 1 1
            first="$REPLY"
            prop_string "$LOWER$UPPER$DIGIT.+_-" 0 10
            tail="$first$REPLY"
            REPLY="$head.$tail"
            ;;
    esac
}

# REPLY = 0-3 spaces/tabs.
gen_ws() { prop_string $' \t' 0 3; }

# REPLY = a line every kind skips: blank, whitespace-only or a comment. A
# comment may itself look like an entry; it must still be skipped.
gen_filler() {
    local ws
    gen_ws
    ws="$REPLY"
    prop_rand 4
    case "$REPLY" in
        0) REPLY="" ;;
        1) REPLY="$ws" ;;
        2)
            prop_string "$LOWER$UPPER $DIGIT\"/" 0 20
            REPLY="$ws# $REPLY"
            ;;
        3)
            prop_pick 'brew "commented-out"' 'cask "x"' 'tap "a/b"' 'name' ''
            REPLY="$ws#$REPLY"
            ;;
    esac
}

is_dsl() { [[ "$1" == brew || "$1" == cask || "$1" == cask-extra ]]; }

keyword() { [[ "$1" == brew ]] && echo brew || echo cask; }

# Sets LINE to a valid entry for <kind> and NAME to what list should print.
gen_entry() {
    local kind="$1" lead trail tap
    gen_name "$kind"
    NAME="$REPLY"
    gen_ws
    lead="$REPLY"
    gen_ws
    trail="$REPLY"
    if is_dsl "$kind"; then
        LINE="$lead$(keyword "$kind") "
        prop_rand 3
        if ((REPLY == 0)); then
            # Tap-qualified: list prints the last segment.
            prop_string "$LOWER$DIGIT-" 1 8
            tap="$REPLY"
            LINE+="\"$tap/$tap/$NAME\""
        else
            LINE+="\"$NAME\""
        fi
        prop_pick "" ", args: [\"no-quarantine\"]" " # trailing comment" ", link: false # x"
        LINE+="$REPLY$trail"
    else
        LINE="$lead$NAME$trail"
    fi
}

# Sets LINE to a line <kind> must reject.
gen_invalid() {
    local kind="$1" name bad
    gen_name "$kind"
    name="$REPLY"
    prop_string "$BAD_CHARS" 1 1
    bad="$REPLY"
    prop_rand 3
    if is_dsl "$kind"; then
        case "$REPLY" in
            0) LINE="$(keyword "$kind") \"${name%%/*}$bad\"" ;;
            1) LINE="$(keyword "$kind") $name" ;;   # unquoted
            2) LINE="brw \"$name\"" ;;              # not the keyword
        esac
    else
        case "$REPLY" in
            0) LINE="$name$bad" ;;
            1) LINE="$name $name" ;;                # two words
            2) LINE="$name # inline comments are not allowed" ;;
        esac
    fi
}

# Writes <path> from LINES[] (no trailing newline half the time).
write_lines() {
    local path="$1"
    : > "$path"
    local i n=${#LINES[@]}
    for ((i = 0; i < n; i++)); do
        printf '%s' "${LINES[i]}" >> "$path"
        if ((i < n - 1)); then printf '\n' >> "$path"; fi
    done
    prop_rand 2
    if ((REPLY)) && ((n)); then printf '\n' >> "$path"; fi
}

# Runs bin/manifest; sets OUT, ERR, RC.
run_manifest() {
    RC=0
    OUT="$(env DOTFILES_DIR="$FIXTURE" "$DOTFILES_DIR/bin/manifest" "$@" 2> "$TEST_TEMP_DIR/err")" || RC=$?
    ERR="$(cat "$TEST_TEMP_DIR/err")"
}

join_lines() { [[ $# -eq 0 ]] || printf '%s\n' "$@"; }

@test "prop: list returns exactly the valid names, in order, for any mix of entries, comments and blanks" {
    local kinds=(brew cask cask-extra npm rust pacman code winget)
    local kind file n expected
    for ((PROP_CASE = 1; PROP_CASE <= PROP_CASES; PROP_CASE++)); do
        prop_pick "${kinds[@]}"
        kind="$REPLY"
        file="$(kind_file "$kind")"
        LINES=()
        local names=()
        prop_rand 15
        local count="$REPLY"
        for ((n = 0; n < count; n++)); do
            prop_rand 3
            if ((REPLY == 0)); then
                gen_filler
                LINES+=("$REPLY")
            else
                gen_entry "$kind"
                LINES+=("$LINE")
                names+=("$NAME")
            fi
        done
        if [[ "$kind" == brew ]]; then
            prop_rand 2
            ((REPLY)) && LINES+=('tap "some/tap"')
        fi
        write_lines "$FIXTURE/install/$file"
        run_manifest list "$kind"
        expected="$(join_lines "${names[@]+"${names[@]}"}")"
        [[ $RC -eq 0 ]] || prop_fail "$kind: exit $RC on a valid manifest: $ERR" || return
        [[ -z "$ERR" ]] || prop_fail "$kind: stderr on a valid manifest: $ERR" || return
        [[ "$OUT" == "$expected" ]] ||
            prop_fail "$kind: got [$OUT], want [$expected] from $(cat -A "$FIXTURE/install/$file")" || return
    done
}

@test "prop: any invalid line makes list fail and name that line, never a valid one" {
    local kinds=(brew cask cask-extra npm rust pacman code winget)
    local kind file n count lineno
    for ((PROP_CASE = 1; PROP_CASE <= PROP_CASES; PROP_CASE++)); do
        prop_pick "${kinds[@]}"
        kind="$REPLY"
        file="$(kind_file "$kind")"
        LINES=()
        local bad=() good=()
        prop_rand 12
        count=$((REPLY + 1))
        for ((n = 0; n < count; n++)); do
            prop_rand 4
            case "$REPLY" in
                0) gen_filler; LINES+=("$REPLY") ;;
                1) gen_invalid "$kind"; LINES+=("$LINE"); bad+=($((n + 1))) ;;
                *) gen_entry "$kind"; LINES+=("$LINE"); good+=($((n + 1))) ;;
            esac
        done
        # At least one invalid line, at a random position.
        if ((${#bad[@]} == 0)); then
            gen_invalid "$kind"
            LINES+=("$LINE")
            bad+=(${#LINES[@]})
        fi
        write_lines "$FIXTURE/install/$file"
        run_manifest list "$kind"
        [[ $RC -ne 0 ]] ||
            prop_fail "$kind: exit 0 despite invalid lines ${bad[*]}: $(cat -A "$FIXTURE/install/$file")" || return
        for lineno in "${bad[@]}"; do
            [[ "$ERR" == *"$file:$lineno:"* ]] ||
                prop_fail "$kind: line $lineno ('${LINES[lineno - 1]}') not named; stderr: $ERR" || return
        done
        for lineno in "${good[@]+"${good[@]}"}"; do
            [[ "$ERR" != *"$file:$lineno:"* ]] ||
                prop_fail "$kind: valid line $lineno ('${LINES[lineno - 1]}') named; stderr: $ERR" || return
        done
    done
}

@test "prop: rice-pacman/rice-aur list the names of one rice, or of every rice when none is named" {
    local kind ext rice r n count want_rice expected
    for ((PROP_CASE = 1; PROP_CASE <= PROP_CASES; PROP_CASE++)); do
        rm -rf "$FIXTURE/omarchy/rices"
        mkdir -p "$FIXTURE/omarchy/rices"
        prop_pick rice-pacman rice-aur
        kind="$REPLY"
        ext="${kind#rice-}"
        local rices=()
        prop_rand 3
        count=$((REPLY + 1))
        for ((r = 0; r < count; r++)); do
            prop_string "$LOWER$DIGIT" 1 1
            rice="$REPLY"
            prop_string "$LOWER$DIGIT-" 0 10
            rice+="$REPLY"
            [[ -d "$FIXTURE/omarchy/rices/$rice" ]] && continue
            mkdir "$FIXTURE/omarchy/rices/$rice"
            rices+=("$rice")
            for e in pacman aur; do
                prop_rand 3
                ((REPLY == 0)) && continue   # this rice ships no such list
                LINES=()
                local names=()
                prop_rand 8
                local m="$REPLY"
                for ((n = 0; n < m; n++)); do
                    prop_rand 3
                    if ((REPLY == 0)); then
                        gen_filler
                        LINES+=("$REPLY")
                    else
                        gen_entry "$kind"
                        LINES+=("$LINE")
                        names+=("$NAME")
                    fi
                done
                write_lines "$FIXTURE/omarchy/rices/$rice/packages.$e"
                printf '%s' "$(join_lines "${names[@]+"${names[@]}"}")" > "$TEST_TEMP_DIR/want.$rice.$e"
            done
        done

        prop_rand 3
        case "$REPLY" in
            0) want_rice="" ;;
            *) prop_pick "${rices[@]}"; want_rice="$REPLY" ;;
        esac
        if [[ -n "$want_rice" ]]; then
            run_manifest list "$kind" "$want_rice"
            expected="$(cat "$TEST_TEMP_DIR/want.$want_rice.$ext" 2> /dev/null || true)"
        else
            run_manifest list "$kind"
            expected=""
            # Same glob, same locale as bin/manifest: directory order.
            for f in "$FIXTURE"/omarchy/rices/*/packages."$ext"; do
                [[ -f "$f" ]] || continue
                r="$(basename "$(dirname "$f")")"
                [[ -s "$TEST_TEMP_DIR/want.$r.$ext" ]] || continue
                expected+="${expected:+$'\n'}$(cat "$TEST_TEMP_DIR/want.$r.$ext")"
            done
        fi
        rm -f "$TEST_TEMP_DIR"/want.*
        [[ $RC -eq 0 ]] || prop_fail "$kind ${want_rice:-<all>}: exit $RC: $ERR" || return
        [[ "$OUT" == "$expected" ]] ||
            prop_fail "$kind ${want_rice:-<all>}: got [$OUT], want [$expected]" || return
    done
}

@test "prop: a rice argument that is not a plain name is always refused" {
    local kind arg frag k
    # Targets a traversal would reach if the name were not checked.
    mkdir -p "$FIXTURE/omarchy/rices/real/sub" "$FIXTURE/omarchy/evil"
    for d in "$FIXTURE/omarchy/rices/real" "$FIXTURE/omarchy/rices/real/sub" "$FIXTURE/omarchy/evil" "$FIXTURE/omarchy"; do
        echo leaked > "$d/packages.pacman"
        echo leaked > "$d/packages.aur"
    done
    for ((PROP_CASE = 1; PROP_CASE <= PROP_CASES; PROP_CASE++)); do
        prop_pick rice-pacman rice-aur
        kind="$REPLY"
        arg=""
        prop_rand 4
        for ((k = 0; k <= REPLY; k++)); do
            prop_pick real evil sub .. . / ../evil real/sub ./real "$FIXTURE/omarchy/evil" \
                "-real" " real" "real " $'real\n' Real '~' '*' 're?l' 're al' $'re\tal'
            frag="$REPLY"
            arg+="$frag"
        done
        # Plain names are the other property's business.
        [[ "$arg" =~ ^[a-z0-9][a-z0-9-]*$ ]] && arg="../$arg"
        run_manifest list "$kind" "$arg"
        [[ $RC -eq 2 ]] || prop_fail "$kind $(printf %q "$arg"): exit $RC, want 2 (out: $OUT)" || return
        [[ -z "$OUT" ]] || prop_fail "$kind $(printf %q "$arg"): printed [$OUT]" || return
        [[ "$ERR" == *"no such rice"* ]] ||
            prop_fail "$kind $(printf %q "$arg"): refusal does not say why: $ERR" || return
    done
}
