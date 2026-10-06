#!/usr/bin/env bash
# Common test helper functions

# Get the directory of the dotfiles repository
DOTFILES_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
export DOTFILES_DIR

# The suite never signs commits. Fixture repos commit with throwaway
# identities, but a linked ~/.config/git/config turns commit.gpgsign on: with
# no key (a fresh container after `make link`) every fixture commit failed,
# and with one the suite signed throwaway commits with the owner's key.
# Env-level config outranks every config file yet does not apply to
# `git config --file`, so tests that read a file directly are unaffected.
export GIT_CONFIG_COUNT=2 \
    GIT_CONFIG_KEY_0=commit.gpgsign GIT_CONFIG_VALUE_0=false \
    GIT_CONFIG_KEY_1=tag.gpgsign GIT_CONFIG_VALUE_1=false

# Load bats-support and bats-assert if available
# macOS (Homebrew on Apple Silicon)
if [[ -d "/opt/homebrew/lib/bats-support" ]]; then
    load "/opt/homebrew/lib/bats-support/load"
    load "/opt/homebrew/lib/bats-assert/load"
# macOS (Homebrew on Intel)
elif [[ -d "/usr/local/lib/bats-support" ]]; then
    load "/usr/local/lib/bats-support/load"
    load "/usr/local/lib/bats-assert/load"
# Linux (manual install location)
elif [[ -d "/usr/lib/bats/bats-support" ]]; then
    load "/usr/lib/bats/bats-support/load"
    load "/usr/lib/bats/bats-assert/load"
else
    # Fallback: define simple assert functions if libraries not found
    assert_success() {
        if [[ "$status" -ne 0 ]]; then
            echo "Expected success (exit code 0), got exit code $status"
            return 1
        fi
    }

    assert_failure() {
        if [[ "$status" -eq 0 ]]; then
            echo "Expected failure (non-zero exit code), got exit code 0"
            return 1
        fi
    }

    assert_output() {
        local expected
        if [[ "$1" == "--partial" ]]; then
            shift
            expected="$1"
            if [[ "$output" != *"$expected"* ]]; then
                echo "Expected output to contain: $expected"
                echo "Actual output: $output"
                return 1
            fi
        else
            expected="$1"
            if [[ "$output" != "$expected" ]]; then
                echo "Expected output: $expected"
                echo "Actual output: $output"
                return 1
            fi
        fi
    }
fi

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

# Platform checks are intentionally inline rather than delegated to
# bin/platform: a helper that calls the module under test would make
# platform-conditional tests *skip* instead of fail when the module breaks.
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
