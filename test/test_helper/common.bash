#!/usr/bin/env bash
# Common test helper functions

# Get the directory of the dotfiles repository
DOTFILES_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
export DOTFILES_DIR

# Setup test environment
setup_test_env() {
    # Create temporary test directory
    export TEST_TEMP_DIR="$(mktemp -d)"
    export TEST_HOME="$TEST_TEMP_DIR/home"
    mkdir -p "$TEST_HOME"
}

# Cleanup test environment
cleanup_test_env() {
    if [[ -n "${TEST_TEMP_DIR:-}" ]] && [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Check if running on macOS
is_macos() {
    [[ "$OSTYPE" == "darwin"* ]]
}

# Check if running on Linux
is_linux() {
    [[ "$OSTYPE" == "linux-gnu"* ]]
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Skip test if not on macOS
skip_if_not_macos() {
    if ! is_macos; then
        skip "This test requires macOS"
    fi
}

# Skip test if not on Linux
skip_if_not_linux() {
    if ! is_linux; then
        skip "This test requires Linux"
    fi
}

# Skip test if command not available
skip_if_command_not_found() {
    local cmd="$1"
    if ! command_exists "$cmd"; then
        skip "Command '$cmd' not found"
    fi
}
