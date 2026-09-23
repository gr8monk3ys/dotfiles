#!/usr/bin/env bats
# Tests for bin/dotfiles-update.
#
# Runs the real script against a throwaway checkout and stub package
# managers that log their argv. How each kind upgrades is install-kind's
# business (test_install_kind.bats); what is asserted here is the
# orchestration: every kind is asked, --skip and SKIP_KINDS reach it, a dirty
# checkout does not stop the packages, and a failure is reported.

load test_helper/common

setup() {
    setup_test_env
    export STUB_BIN="$TEST_TEMP_DIR/stubbin"
    export CALL_LOG="$TEST_TEMP_DIR/calls.log"
    mkdir -p "$STUB_BIN"
    : > "$CALL_LOG"

    # Every package manager is stubbed, always: on the Arch image the real
    # pacman is in /usr/bin and the test user has passwordless sudo.
    local t
    for t in brew npm cargo cargo-install-update rustup code codium pacman; do
        stub "$t"
    done
    cat > "$STUB_BIN/sudo" <<'STUB'
#!/usr/bin/env bash
printf 'sudo %s\n' "$*" >> "$CALL_LOG"
exec "$@"
STUB
    printf '#!/usr/bin/env bash\necho 1000\n' > "$STUB_BIN/id"
    chmod +x "$STUB_BIN/sudo" "$STUB_BIN/id"

    # A clean checkout level with its upstream, so the repository step passes.
    export REPO="$TEST_HOME/dotfiles-repo"
    git -C "$TEST_HOME" init -q -b main dotfiles-repo
    git -C "$REPO" -c user.email=t@t.t -c user.name=t commit -q --allow-empty -m init
    git -C "$REPO" remote add origin "$REPO"
    git -C "$REPO" fetch -q origin
    git -C "$REPO" branch -q --set-upstream-to=origin/main main
}

teardown() {
    cleanup_test_env
}

stub() {
    local name="$1" exit_code="${2:-0}"
    cat > "$STUB_BIN/$name" <<STUB
#!/usr/bin/env bash
printf '%s %s\n' "$name" "\$*" >> "\$CALL_LOG"
exit $exit_code
STUB
    chmod +x "$STUB_BIN/$name"
}

# ZDOTDIR and the XDG vars are scrubbed, not just HOME: the zinit step runs a
# child `zsh -c`, and zsh derives its completion dump from an inherited
# $ZDOTDIR rather than from $HOME — on a machine where ~/.config/zsh is
# stowed that path resolves into the checkout, and the sandboxed test wrote
# .zcompdump into the working tree. Same scrub test_shell_boot.bats uses.
#
# The knobs are passed only when a test sets them, so --skip is exercised
# with SKIP_KINDS absent from the environment, as it is for a person.
run_update() {
    local knobs=()
    [[ -n "${SKIP_KINDS:-}" ]] && knobs+=("SKIP_KINDS=$SKIP_KINDS")
    [[ -n "${STRICT_PACKAGES:-}" ]] && knobs+=("STRICT_PACKAGES=$STRICT_PACKAGES")
    run env -u ZDOTDIR -u XDG_CONFIG_HOME -u XDG_DATA_HOME -u XDG_CACHE_HOME \
        -u SKIP_KINDS -u STRICT_PACKAGES \
        HOME="$TEST_HOME" DOTFILES_DIR="$REPO" CALL_LOG="$CALL_LOG" \
        PATH="$STUB_BIN:/usr/bin:/bin:/usr/sbin:/sbin" \
        ${knobs[@]+"${knobs[@]}"} \
        bash "$BATS_TEST_DIRNAME/../bin/dotfiles-update" "$@"
}

calls() { cat "$CALL_LOG"; }

@test "asks install-kind to update every kind" {
    run_update
    assert_success
    assert_output --partial "Update complete!"
    run calls
    assert_output --partial "brew upgrade --formula"
    assert_output --partial "brew upgrade --cask --greedy"
    assert_output --partial "npm install -g npm@latest"
    assert_output --partial "cargo install-update -a"
    assert_output --partial "sudo pacman -Syu --noconfirm"
    assert_output --partial "codium --update-extensions"
}

@test "--skip skips exactly the kinds it names" {
    run_update --skip brew --skip npm
    assert_success
    assert_output --partial "Skipping brew (SKIP_KINDS)"
    run calls
    [[ "$output" != *"brew upgrade --formula"* ]]
    [[ "$output" != *"npm "* ]]
    # Kind-sized, not tool-sized: skipping brew leaves the casks alone.
    assert_output --partial "brew upgrade --cask --greedy"
    assert_output --partial "cargo install-update -a"
}

@test "SKIP_KINDS from the environment reaches every kind" {
    SKIP_KINDS="brew cask cask-extra npm rust pacman code" run_update
    assert_success
    [[ ! -s "$CALL_LOG" ]]
}

@test "--skip rejects a kind that does not exist" {
    # "cargo" was dotfiles-update's own name for the rust kind.
    run_update --skip cargo
    assert_failure
    assert_output --partial "--skip needs a kind"
    [[ ! -s "$CALL_LOG" ]]
}

@test "the per-tool --skip-brew flags are gone" {
    run_update --skip-brew
    assert_failure
    assert_output --partial "Unknown option: --skip-brew"
}

@test "a dirty checkout skips the repository step, not the packages" {
    echo "wip" > "$REPO/untracked-change"
    git -C "$REPO" add untracked-change
    run_update
    assert_success
    assert_output --partial "repository not updated (uncommitted changes)"
    run calls
    assert_output --partial "brew upgrade --formula"
}

@test "a failing kind is reported, the rest still run, and the exit is non-zero when strict" {
    stub brew 1
    STRICT_PACKAGES=1 run_update
    assert_failure
    assert_output --partial "Updating brew failed"
    assert_output --partial "Update finished with failures: brew"
    run calls
    assert_output --partial "npm install -g npm@latest"
}

@test "a failing kind is tolerated by default" {
    stub brew 1
    run_update
    assert_success
    assert_output --partial "Continuing after failure"
}

@test "help documents --skip and no longer demands a clean checkout" {
    run_update --help
    assert_success
    assert_output --partial "--skip <kind>"
    assert_output --partial "brew cask cask-extra npm rust pacman code"
    [[ "$output" != *"Clean git repository"* ]]
}
