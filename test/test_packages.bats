#!/usr/bin/env bats
# Tests for package file validation.
#
# Manifest format is validated by bin/manifest itself: `manifest list <kind>`
# exits non-zero on a line it cannot parse or a name that breaks that
# ecosystem's grammar. These tests assert that it succeeds on the real
# manifests, so the parsing rule and the format rule stay the same rule.
# bin/manifest's own behaviour is covered in test_manifest.bats.

load test_helper/common

setup() {
    setup_test_env
}

teardown() {
    cleanup_test_env
}

@test "Brewfile has valid format" {
    run bin/manifest list brew
    assert_success
}

@test "Caskfile has valid format" {
    run bin/manifest list cask
    assert_success
}

@test "Caskfile.extra has valid format" {
    run bin/manifest list cask-extra
    assert_success
}

@test "Caskfile and Caskfile.extra do not overlap" {
    run bash -c 'comm -12 <(bin/manifest list cask | sort) <(bin/manifest list cask-extra | sort)'
    assert_success
    assert_output ""
}

@test "npmfile has valid format (one package per line)" {
    run bin/manifest list npm
    assert_success
}

@test "Rustfile has valid format (one package per line)" {
    run bin/manifest list rust
    assert_success
}

@test "Codefile has valid format (extension IDs or comments)" {
    run bin/manifest list code
    assert_success
}

@test "pacmanfile has valid format" {
    run bin/manifest list pacman
    assert_success
}

@test "every kind in the vocabulary parses" {
    run bash -c 'for k in $(bin/manifest kinds); do bin/manifest list "$k" > /dev/null || exit 1; done'
    assert_success
}

# install/duti is not a package manifest (it holds `<bundle-id> <type> [role]`
# triples consumed directly by `duti -v`), so bin/manifest does not read it
# and its format is still checked here.
@test "duti file has valid format" {
    while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        [[ ! "$line" =~ ^# ]] || continue
        [[ "$line" =~ ^[a-zA-Z0-9.-]+[[:space:]]+[a-zA-Z0-9.-]+[[:space:]]+(all|viewer|editor|shell)$ ]] || {
            echo "Invalid duti line: $line"
            return 1
        }
    done < install/duti
}
