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

@test "every kind bin/manifest knows is accepted by install-kind" {
    run bash -c '
        set -euo pipefail
        for k in $("$1/bin/manifest" kinds); do
            grep -q "        $k)" "$1/bin/install-kind" || { echo "no case arm for kind: $k"; exit 1; }
        done
    ' _ "$DOTFILES_DIR"
    assert_success
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

@test "deprecated SKIP_BREW still works and says so" {
    stub brew
    run env PATH="$STUB_BIN:$DOTFILES_DIR/bin:/usr/bin:/bin" CALL_LOG="$CALL_LOG" \
        HOME="$TEST_HOME" SKIP_BREW=1 bash "$DOTFILES_DIR/bin/install-kind" brew
    assert_success
    assert_output --partial "SKIP_BREW is deprecated"
    assert_output --partial "Skipping brew"
    [[ ! -s "$CALL_LOG" ]]
}

@test "deprecated SKIP_CASKS skips both cask kinds" {
    stub brew
    for k in cask cask-extra; do
        : > "$CALL_LOG"
        run env PATH="$STUB_BIN:$DOTFILES_DIR/bin:/usr/bin:/bin" CALL_LOG="$CALL_LOG" \
            HOME="$TEST_HOME" SKIP_CASKS=1 bash "$DOTFILES_DIR/bin/install-kind" "$k"
        assert_success
        [[ ! -s "$CALL_LOG" ]]
    done
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

@test "deprecated BREW_BUNDLE_STRICT still makes it fatal" {
    stub brew 1
    run env PATH="$STUB_BIN:$DOTFILES_DIR/bin:/usr/bin:/bin" CALL_LOG="$CALL_LOG" \
        HOME="$TEST_HOME" BREW_BUNDLE_STRICT=1 bash "$DOTFILES_DIR/bin/install-kind" brew
    assert_failure
    assert_output --partial "BREW_BUNDLE_STRICT is deprecated"
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
