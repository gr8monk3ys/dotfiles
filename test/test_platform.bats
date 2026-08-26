#!/usr/bin/env bats
# Tests for platform detection script

load test_helper/common

setup() {
    setup_test_env
}

teardown() {
    cleanup_test_env
}

@test "platform detect returns valid OS" {
    run bin/platform detect
    assert_success
    [[ "$output" =~ ^(macos|arch|linux|unknown)$ ]]
}

@test "platform arch returns valid architecture" {
    run bin/platform arch
    assert_success
    [[ "$output" =~ ^(arm64|x86_64|unknown)$ ]]
}

@test "platform is-macos returns 0 on macOS" {
    skip_if_not_macos
    run bin/platform is-macos
    assert_success
}

@test "platform is-macos returns 1 on non-macOS" {
    skip_if_not_linux
    run bin/platform is-macos
    assert_failure
}

@test "platform is-arch detects Arch Linux" {
    skip_if_not_linux
    if [[ -f /etc/arch-release ]]; then
        run bin/platform is-arch
        assert_success
    else
        run bin/platform is-arch
        assert_failure
    fi
}

@test "platform is-omarchy fails without the Omarchy checkout" {
    HOME="$TEST_HOME" run bin/platform is-omarchy
    assert_failure
}

@test "platform is-omarchy detects ~/.local/share/omarchy and detect stays arch-compatible" {
    mkdir -p "$TEST_HOME/.local/share/omarchy"
    HOME="$TEST_HOME" run bin/platform is-omarchy
    assert_success
    # Omarchy is Arch: detect must not grow a new OS name for it.
    HOME="$TEST_HOME" run bin/platform detect
    assert_success
    [[ "$output" =~ ^(macos|arch|linux|unknown)$ ]]
    [[ "$output" != "omarchy" ]]
}

@test "platform is-arm64 detects ARM architecture" {
    run bin/platform is-arm64
    if [[ $(uname -m) == "arm64" ]] || [[ $(uname -m) == "aarch64" ]]; then
        assert_success
    else
        assert_failure
    fi
}

@test "platform has works for existing command" {
    run bin/platform has ls
    assert_success
}

@test "platform has fails for non-existing command" {
    run bin/platform has nonexistent-command-12345
    assert_failure
}

@test "platform select returns correct value for true condition" {
    run bin/platform select "yes" "no" "true"
    assert_success
    assert_output "yes"
}

@test "platform select returns correct value for false condition" {
    run bin/platform select "yes" "no" "false"
    assert_success
    assert_output "no"
}

@test "platform help shows usage" {
    run bin/platform help
    assert_success
    [[ "$output" =~ "platform" ]]
}
