#!/usr/bin/env bats
# Tests for bin/install-kind.
#
# These run install-kind for real against stub binaries on PATH that log their
# argv. Before this module existed the same behaviour could only be checked by
# grepping `make -n` output, which asserts on make's string expansion rather
# than on what actually gets installed.

load test_helper/common

setup() {
    setup_test_env
    export STUB_BIN="$TEST_TEMP_DIR/stubbin"
    export CALL_LOG="$TEST_TEMP_DIR/calls.log"
    mkdir -p "$STUB_BIN"
    : > "$CALL_LOG"
}

teardown() {
    cleanup_test_env
}

# A stub that records how it was called and succeeds.
stub() {
    local name="$1" exit_code="${2:-0}"
    cat > "$STUB_BIN/$name" <<STUB
#!/usr/bin/env bash
printf '%s %s\n' "$name" "\$*" >> "\$CALL_LOG"
exit $exit_code
STUB
    chmod +x "$STUB_BIN/$name"
}

# pacman reads its package list from stdin when the last argument is "-";
# this stub keeps it, so a test can see what pacman was actually handed.
stub_pacman() {
    cat > "$STUB_BIN/pacman" <<'STUB'
#!/usr/bin/env bash
printf 'pacman %s\n' "$*" >> "$CALL_LOG"
[[ "${!#}" == "-" ]] && cat > "$CALL_LOG.stdin"
exit 0
STUB
    chmod +x "$STUB_BIN/pacman"
}

# sudo that logs and then runs its command (the stubbed one, via PATH), and
# an `id` that claims the given uid: together they decide who escalates.
stub_sudo_as_uid() {
    local uid="$1"
    cat > "$STUB_BIN/sudo" <<'STUB'
#!/usr/bin/env bash
printf 'sudo %s\n' "$*" >> "$CALL_LOG"
exec "$@"
STUB
    printf '#!/usr/bin/env bash\necho %s\n' "$uid" > "$STUB_BIN/id"
    chmod +x "$STUB_BIN/sudo" "$STUB_BIN/id"
}

# Run install-kind with ONLY the stubs plus the repo's bin on PATH, so a real
# brew/npm/cargo on this machine can never be reached.
run_kind() {
    run env PATH="$STUB_BIN:$DOTFILES_DIR/bin:/usr/bin:/bin" \
        CALL_LOG="$CALL_LOG" HOME="$TEST_HOME" \
        SKIP_KINDS="${SKIP_KINDS:-}" STRICT_PACKAGES="${STRICT_PACKAGES:-}" \
        bash "$DOTFILES_DIR/bin/install-kind" "$@"
}

calls() { cat "$CALL_LOG"; }

# ---------- interface ----------

@test "install-kind rejects an unknown kind" {
    run_kind not-a-kind
    assert_failure
    assert_output --partial "Unknown kind"
}

@test "install-kind with no argument fails and prints usage" {
    run_kind
    assert_failure
    assert_output --partial "install-kind <kind>"
}

@test "install-kind --help succeeds" {
    run_kind --help
    assert_success
    assert_output --partial "SKIP_KINDS"
}

# Every verb must answer for every kind bin/manifest knows. Run for real
# with every tool stubbed, so a kind with no function for a verb fails here
# rather than on the first machine that asks.
@test "every verb answers for every kind bin/manifest knows" {
    for t in brew npm cargo cargo-install-update rustup code codium; do stub "$t"; done
    stub_pacman
    stub_sudo_as_uid 1000
    local verb kind
    for verb in install update; do
        for kind in $("$DOTFILES_DIR/bin/manifest" kinds); do
            run_kind "$verb" "$kind"
            [[ "$status" -eq 0 ]] || { echo "$verb $kind exited $status: $output"; return 1; }
        done
    done
}

@test "install is the default verb" {
    stub brew
    run_kind install brew
    assert_success
    run calls
    local explicit="$output"
    : > "$CALL_LOG"
    run_kind brew
    run calls
    [[ "$output" == "$explicit" ]]
}

@test "a verb with no kind fails" {
    run_kind update
    assert_failure
    assert_output --partial "missing <kind>"
}

# ---------- skip policy ----------

@test "SKIP_KINDS skips the named kind and installs nothing" {
    stub brew
    SKIP_KINDS="brew" run_kind brew
    assert_success
    assert_output --partial "Skipping brew"
    [[ ! -s "$CALL_LOG" ]]
}

@test "SKIP_KINDS only skips the kinds it names" {
    stub brew
    SKIP_KINDS="rust pacman" run_kind brew
    assert_success
    run calls
    assert_output --partial "brew bundle"
}

# ---------- what each kind actually runs ----------

@test "brew installs from the Brewfile" {
    stub brew
    run_kind brew
    assert_success
    run calls
    assert_output --partial "bundle --file="
    assert_output --partial "install/Brewfile"
}

@test "cask and cask-extra use their own manifests" {
    stub brew
    run_kind cask
    run calls
    assert_output --partial "install/Caskfile"
    [[ "$output" != *"Caskfile.extra"* ]]

    : > "$CALL_LOG"
    run_kind cask-extra
    run calls
    assert_output --partial "install/Caskfile.extra"
}

# Regression: Homebrew >= 5 refuses third-party taps until `brew trust`ed, so
# `brew bundle` on a fresh Mac died on the first tapped cask (aerospace).
@test "brew kinds trust the declared taps first" {
    stub brew
    run_kind brew
    assert_success
    run calls
    # trust runs before bundle
    assert_output --partial "trust"
    run bash -c 'grep -n "trust\|bundle" "$1" | head -1' _ "$CALL_LOG"
    assert_output --partial "trust"
}

@test "npm installs the manifest's packages globally" {
    stub npm
    stub xargs_unused
    run_kind npm
    assert_success
    run calls
    assert_output --partial "npm install --force --location global"
}

# bin/pacman used to shadow the real pacman on PATH to add sudo. The kind
# escalates at the call site instead.
@test "pacman installs the manifest through sudo when not root" {
    stub_pacman
    stub_sudo_as_uid 1000
    run_kind pacman
    assert_success
    run calls
    assert_output --partial "sudo pacman -S --noconfirm -"
    first="$("$DOTFILES_DIR/bin/manifest" list pacman | head -1)"
    run grep -cx "$first" "$CALL_LOG.stdin"
    assert_output "1"
    run grep -c "#" "$CALL_LOG.stdin"
    assert_output "0"
}

@test "pacman runs directly as root, without sudo" {
    stub_pacman
    stub_sudo_as_uid 0
    run_kind pacman
    assert_success
    run calls
    assert_output --partial "pacman -S --noconfirm -"
    [[ "$output" != *"sudo"* ]]
}

@test "code prefers codium when both editors exist" {
    stub codium
    stub code
    run_kind code
    assert_success
    run calls
    assert_output --partial "codium --install-extension"
    [[ "$output" != *"^code --install-extension"* ]]
}

@test "code falls back to code when codium is absent" {
    stub code
    run_kind code
    assert_success
    run calls
    assert_output --partial "code --install-extension"
}

# Regression: the Makefile used $(shell cat install/npmfile), which flattens
# the file onto one line so the leading "# comment" turned every package name
# into a shell comment: `make node-packages` installed nothing and
# `make rust-packages` ran a bare `cargo install`. Asserted on what the tool
# actually receives, not on which file a recipe names.
@test "npm is handed real package names, never a comment" {
    stub npm
    run_kind npm
    assert_success
    first="$("$DOTFILES_DIR/bin/manifest" list npm | head -1)"
    run calls
    assert_output --partial "$first"
    [[ "$output" != *"#"* ]]
}

@test "rust runs one cargo install per crate, never a bare one" {
    stub cargo
    run_kind rust
    assert_success
    run calls
    [[ "${#lines[@]}" -eq "$("$DOTFILES_DIR/bin/manifest" list rust | wc -l)" ]]
    [[ "$output" != *"#"* ]]
    run grep -cxE 'cargo install ?' "$CALL_LOG"
    assert_output "0"
}

# ---------- make routes every kind through here ----------

# A claim about make's graph, which is make's job, so `make -n` is the right
# tool here and only here. What install-kind then does is asserted above.
@test "every package target routes through install-kind" {
    local target kind
    for pair in brew-packages:brew cask-apps:cask cask-apps-extra:cask-extra \
                node-packages:npm rust-packages:rust vscode-extensions:code \
                pacman-packages:pacman; do
        target="${pair%%:*}" kind="${pair#*:}"
        run make -n -C "$DOTFILES_DIR" "$target"
        assert_success
        [[ "$output" == *"install-kind $kind"* ]] || { echo "$target does not run install-kind $kind"; return 1; }
    done
}

# ---------- update ----------

@test "update brew refreshes Homebrew, upgrades formulae, then cleans up" {
    stub brew
    run_kind update brew
    assert_success
    run calls
    assert_output "brew update
brew upgrade --formula
brew cleanup"
}

@test "update cask upgrades casks greedily; cask-extra adds nothing" {
    stub brew
    run_kind update cask
    assert_success
    run calls
    assert_output "brew upgrade --cask --greedy"

    : > "$CALL_LOG"
    run_kind update cask-extra
    assert_success
    assert_output --partial "upgraded with cask"
    [[ ! -s "$CALL_LOG" ]]
}

# Regression (was in test_regressions.bats against dotfiles-update): npm
# outdated exits 1 exactly when there is work to do, which under set -e used
# to abort the update. Strict, so errexit is live inside the step.
@test "update npm survives outdated packages under set -e" {
    cat > "$STUB_BIN/npm" <<'STUB'
#!/usr/bin/env bash
printf 'npm %s\n' "$*" >> "$CALL_LOG"
case "${1:-}" in
    outdated) printf 'Package Current Wanted\nfoo 1.0.0 2.0.0\n'; exit 1 ;;
esac
exit 0
STUB
    chmod +x "$STUB_BIN/npm"
    STRICT_PACKAGES=1 run_kind update npm
    assert_success
    assert_output --partial "npm packages updated"
    run calls
    assert_output --partial "npm update -g"
}

@test "update rust installs cargo-update when missing, then upgrades crates" {
    stub cargo
    stub rustup
    run_kind update rust
    assert_success
    run calls
    assert_output "rustup update
cargo install cargo-update
cargo install-update -a"
}

@test "update pacman upgrades the system through sudo when not root" {
    stub_pacman
    stub_sudo_as_uid 1000
    run_kind update pacman
    assert_success
    run calls
    assert_output --partial "sudo pacman -Syu --noconfirm"
}

@test "update code updates the preferred editor's extensions" {
    stub codium
    stub code
    run_kind update code
    assert_success
    run calls
    assert_output "codium --update-extensions"
}

@test "SKIP_KINDS applies to update too" {
    stub brew
    SKIP_KINDS="brew" run_kind update brew
    assert_success
    assert_output --partial "Skipping brew"
    [[ ! -s "$CALL_LOG" ]]
}

@test "a failing update is tolerated by default and fatal under STRICT_PACKAGES" {
    stub brew 1
    run_kind update brew
    assert_success
    assert_output --partial "Continuing after failure"
    STRICT_PACKAGES=1 run_kind update brew
    assert_failure
}

# ---------- missing tools are not failures ----------

@test "a missing tool warns and exits 0" {
    # No stubs at all: nothing is on PATH.
    run_kind brew
    assert_success
    assert_output --partial "not installed; skipping"
}

@test "code with no editor at all warns and exits 0" {
    run_kind code
    assert_success
    assert_output --partial "Neither codium nor code"
}

# ---------- strictness ----------

@test "a failing install is tolerated by default" {
    stub brew 1
    run_kind brew
    assert_success
    assert_output --partial "Continuing after failure"
}

@test "STRICT_PACKAGES makes a failing install fatal" {
    stub brew 1
    STRICT_PACKAGES=1 run_kind brew
    assert_failure
}

@test "STRICT_PACKAGES=true is strict too" {
    stub brew 1
    STRICT_PACKAGES=true run_kind brew
    assert_failure
}

# Regression: any non-empty value used to be strict, so the obvious way to
# turn it off (STRICT_PACKAGES=0) turned it on.
@test "STRICT_PACKAGES=0 and =false are not strict" {
    stub brew 1
    for v in 0 false; do
        STRICT_PACKAGES="$v" run_kind brew
        assert_success
        assert_output --partial "Continuing after failure"
    done
}

@test "a STRICT_PACKAGES typo is reported, not silently read as on" {
    stub brew 1
    STRICT_PACKAGES=yes run_kind brew
    assert_success
    assert_output --partial "STRICT_PACKAGES='yes' is not 1/true or 0/false"
}

# ---------- the flags are documented ----------

@test "every SKIP_/STRICT_ variable the Makefile reads appears in make help" {
    run bash -c '
        set -euo pipefail
        cd "$1"
        help="$(make help 2>/dev/null)"
        status=0
        for v in $(grep -oE "\$\((SKIP|STRICT)_[A-Z_]+\)" Makefile | tr -d "\$()" | sort -u); do
            printf "%s" "$help" | grep -q "$v" || { echo "undocumented in make help: $v"; status=1; }
        done
        exit $status
    ' _ "$DOTFILES_DIR"
    assert_success
}
