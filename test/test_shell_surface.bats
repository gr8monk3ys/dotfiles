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
    # Each entry: representative alias name from one conditional block.
    # When updating aliases.zsh, add/remove an entry here for each
    # `if command -v X &> /dev/null` block.
    local sentinels=(
        # unconditional region (always defined)
        g           # alias g="git"
        # conditional blocks (defined only if guard succeeds)
        mergepdf    # gs (ghostscript) block
        GET         # lwp-request block
        lt          # eza block
        catp        # bat block
        rgi         # rg block
        dus         # dust block
        psa         # procs block
        htop        # btm block
        zi          # zoxide block
        hs          # atuin block
        mi          # mise block
        bench       # hyperfine block
        loc         # tokei block
        fm          # yazi block
        j           # jj block
        zj          # zellij block
        cheat       # navi block
        br          # broot block
        tldru       # tldr block
        dig         # doggo block
        df          # duf block
        compress    # ouch block
        lg          # lazygit block
        lzd         # lazydocker block
        jqi         # jnv block
        md          # glow block
        csv         # csvlens block
        bw          # bandwhich block
        watch       # viddy block
        mtr         # trip block
        gdd         # difft block
        tg          # topgrade block
        nrs         # darwin-rebuild block
        nhs         # home-manager block
        nfu         # nix block
        cc          # claude block
    )

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

    run env ALIASES_FILE="$DOTFILES_DIR/.config/zsh/aliases.zsh" \
        zsh -c "$check_script" -- "${sentinels[@]}"
    assert_success
}
