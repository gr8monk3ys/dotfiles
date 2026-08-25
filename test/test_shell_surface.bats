#!/usr/bin/env bats
# Shell-surface validation tests.
#
# Layer B-leaf: every shell file the user authors (i.e. not third-party
# plugins) must parse and source cleanly in isolation. Sourcing in a
# clean subshell catches errors that fire at definition time —
# typo'd guard expressions, malformed function declarations,
# bad parameter expansions.

load test_helper/common

setup() {
    setup_test_env
}

teardown() {
    cleanup_test_env
}

# --- Parse checks (zsh -n) -------------------------------------------------

@test "shell-surface: .zshenv parses as valid zsh" {
    run zsh -n "$DOTFILES_DIR/.zshenv"
    assert_success
}

@test "shell-surface: aliases.zsh parses as valid zsh" {
    run zsh -n "$DOTFILES_DIR/.config/zsh/aliases.zsh"
    assert_success
}

@test "shell-surface: functions.zsh parses as valid zsh" {
    run zsh -n "$DOTFILES_DIR/.config/zsh/functions.zsh"
    assert_success
}

# --- Source checks ---------------------------------------------------------
# Source each file in a clean subshell with HOME pointed at a temp dir.
# Any error written to stderr at source time is a failure.

@test "shell-surface: .zshenv sources cleanly in a clean subshell" {
    run zsh -c "HOME='$TEST_HOME' source '$DOTFILES_DIR/.zshenv'"
    assert_success
    assert_output ""
}

@test "shell-surface: aliases.zsh sources cleanly in a clean subshell" {
    run zsh -c "HOME='$TEST_HOME' source '$DOTFILES_DIR/.config/zsh/aliases.zsh'"
    assert_success
    assert_output ""
}

@test "shell-surface: functions.zsh sources cleanly in a clean subshell" {
    run zsh -c "HOME='$TEST_HOME' source '$DOTFILES_DIR/.config/zsh/functions.zsh'"
    assert_success
    assert_output ""
}

# --- Sentinel: detect typo'd `command -v` guards ---------------------------
# A typo in a guard ("commnd -v eza") evaluates to false silently — no error
# fires, but the entire conditional block is skipped. We catch this by
# shadowing `command` to always succeed for `-v` queries, then sourcing
# aliases.zsh and asserting each conditional block actually defined its
# representative alias.

@test "shell-surface: every conditional block in aliases.zsh defines its sentinel" {
    local aliases_file="$DOTFILES_DIR/.config/zsh/aliases.zsh"

    # Sentinels = `g` (unconditional) + the first literal-name alias inside
    # each `if command -v X` block. Auto-deriving from the file avoids the
    # drift hazard of a hand-curated list — when a new conditional block is
    # added to aliases.zsh, this test automatically gains coverage.
    #
    # Dynamic alias names (quoted, variable-expansion, dash-prefixed) are
    # skipped because we cannot statically resolve them. The `lwp-request`
    # block uses `alias "${method}"=` and so has no static sentinel; that
    # block is the only one intentionally uncovered.
    local sentinels=(g)
    while IFS= read -r derived; do
        [[ -n "$derived" ]] && sentinels+=("$derived")
    done < <(awk '
        # Two-pass walk over aliases.zsh.
        #
        # Pass 1 (NR == FNR): count occurrences of each alias name across
        # the whole file. Names appearing more than once mean an alias
        # inside a conditional block shadows an unconditional definition
        # of the same name — those make BAD sentinels (they remain
        # defined even when the block is silently skipped).
        #
        # Pass 2: walk again, emit the first unique-name alias inside each
        # `if c… -v` block. The c-prefixed regex catches `command` plus
        # likely typos (`commnd`, `commad`, `comand`, `cmd`). Typos that
        # do not start with `c` go undetected — an accepted limitation.
        # Nested non-cmdv `if/fi` pairs inside a cmdv block (e.g., the
        # yazi function body) must not close the outer block, so we track
        # the cmdv block by its entry-depth.
        NR == FNR {
            if ($0 ~ /^[[:space:]]*alias[[:space:]]+[^=]+=/) {
                line = $0
                sub(/^[[:space:]]*alias[[:space:]]+/, "", line)
                sub(/=.*/, "", line)
                if (line !~ /^[-"$]/) count[line]++
            }
            next
        }
        /^[[:space:]]*if[[:space:]]/ {
            depth++
            if (cmdv_entry_depth < 0 && $0 ~ /^[[:space:]]*if[[:space:]]+c[a-zA-Z_]+[[:space:]]+-v/) {
                cmdv_entry_depth = depth
                captured = 0
            }
            next
        }
        /^[[:space:]]*fi[[:space:]]*$/ {
            if (depth == cmdv_entry_depth) cmdv_entry_depth = -1
            if (depth > 0) depth--
            next
        }
        /^[[:space:]]*alias[[:space:]]+[^=]+=/ {
            if (cmdv_entry_depth < 0 || captured) next
            line = $0
            sub(/^[[:space:]]*alias[[:space:]]+/, "", line)
            sub(/=.*/, "", line)
            if (line ~ /^[-"$]/) next
            if (count[line] == 1) {
                print line
                captured = 1
            }
        }
    ' "$aliases_file" "$aliases_file")

    # Build a zsh script that:
    #   1. Shadows `command` so `command -v X` always returns success.
    #   2. Sources aliases.zsh.
    #   3. Prints any sentinel that is NOT defined as an alias.
    local check_script
    check_script=$(cat <<'ZSH'
command() {
    if [[ "$1" == "-v" ]]; then return 0; fi
    builtin command "$@"
}
source "$ALIASES_FILE"
missing=()
for name in "$@"; do
    if ! alias -L "$name" >/dev/null 2>&1; then
        missing+=("$name")
    fi
done
if (( ${#missing} > 0 )); then
    echo "Missing aliases (likely typo'd guard):"
    printf '  %s\n' "${missing[@]}"
    exit 1
fi
ZSH
)

    run env ALIASES_FILE="$aliases_file" \
        zsh -c "$check_script" -- "${sentinels[@]}"
    assert_success
}

# --- Integration: alias reference checker passes against real repo --------

@test "shell-surface: bin/check-alias-references passes against current aliases.zsh" {
    run bash "$DOTFILES_DIR/bin/check-alias-references"
    assert_success
    assert_output --partial "all aliases resolve"
}
