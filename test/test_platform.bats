#!/usr/bin/env bats
# Tests for platform detection scripts

load test_helper/common

setup() {
    setup_test_env
}

teardown() {
    cleanup_test_env
}

@test "is-macos returns 0 on macOS" {
    skip_if_not_macos
    run bin/is-macos
    assert_success
}

@test "is-macos returns 1 on non-macOS" {
    skip_if_not_linux
    run bin/is-macos
    assert_failure
}

@test "is-arch detects Arch Linux" {
    skip_if_not_linux
    if [[ -f /etc/arch-release ]]; then
        run bin/is-arch
        assert_success
    else
        run bin/is-arch
        assert_failure
    fi
}

@test "is-arm64 detects ARM architecture" {
    run bin/is-arm64
    if [[ $(uname -m) == "arm64" ]] || [[ $(uname -m) == "aarch64" ]]; then
        assert_success
    else
        assert_failure
    fi
}

@test "is-executable works for existing command" {
    run bin/is-executable ls
    assert_success
}

@test "is-executable fails for non-existing command" {
    run bin/is-executable nonexistent-command-12345
    assert_failure
}

@test "is-supported executes command if it exists" {
    run bin/is-supported bin/is-macos echo "macos" echo "not-macos"
    if is_macos; then
        assert_output "macos"
    else
        assert_output "not-macos"
    fi
}

@test "is-supported handles missing command gracefully" {
    run bin/is-supported nonexistent-command-12345 echo "exists" echo "missing"
    assert_output "missing"
}
