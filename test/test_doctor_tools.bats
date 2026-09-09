#!/usr/bin/env bats
# Tests for bin/validate-doctor-tools.
#
# dotfiles-doctor probes commands; install/ manifests list packages. This
# validator is what stops the two drifting apart, so it has to fail in both
# directions, not just pass today.

load test_helper/common

setup() {
    setup_test_env
    export FIXTURE="$TEST_TEMP_DIR/root"
    mkdir -p "$FIXTURE"
    # A working copy the fixture can mutate without touching the checkout.
    cp -R bin install test "$FIXTURE/"
}

teardown() {
    cleanup_test_env
}

@test "validate-doctor-tools passes on the current checkout" {
    run bin/validate-doctor-tools
    assert_success
    assert_output --partial "in sync"
}

@test "dotfiles-doctor --list-checked-tools lists every probed command" {
    run bin/dotfiles-doctor --list-checked-tools
    assert_success
    assert_output --partial "git"
    assert_output --partial "rg"
    assert_output --partial "ouch"
    # 4 core + 6 essential + 5 nextgen + 5 additional
    [[ "${#lines[@]}" -eq 20 ]]
}

@test "fails when doctor probes a tool no manifest installs" {
    sed -i.bak 's/readonly DOCTOR_ADDITIONAL_TOOLS=("navi"/readonly DOCTOR_ADDITIONAL_TOOLS=("madeuptool" "navi"/' \
        "$FIXTURE/bin/dotfiles-doctor"
    run "$FIXTURE/bin/validate-doctor-tools" "$FIXTURE"
    assert_failure
    assert_output --partial "madeuptool"
}

@test "fails when a mapped package is removed from its manifest" {
    grep -v '^brew "ripgrep"' "$FIXTURE/install/Brewfile" > "$FIXTURE/install/Brewfile.new"
    mv "$FIXTURE/install/Brewfile.new" "$FIXTURE/install/Brewfile"
    run "$FIXTURE/bin/validate-doctor-tools" "$FIXTURE"
    assert_failure
    assert_output --partial "ripgrep"
}

@test "fails when the mapping names a command doctor no longer probes" {
    echo 'ghosttool ghostpkg  # stale entry' >> "$FIXTURE/test/allowlist/command-packages.txt"
    run "$FIXTURE/bin/validate-doctor-tools" "$FIXTURE"
    assert_failure
    assert_output --partial "no longer probes"
}

@test "exempt entries need no manifest package" {
    # zsh and stow map to "-" and must not be reported.
    run bin/validate-doctor-tools
    assert_success
    [[ "$output" != *"'zsh'"* ]]
    [[ "$output" != *"'stow'"* ]]
}

@test "fails cleanly when the mapping file is missing" {
    rm "$FIXTURE/test/allowlist/command-packages.txt"
    run "$FIXTURE/bin/validate-doctor-tools" "$FIXTURE"
    assert_failure
    assert_output --partial "Missing"
}
