#!/usr/bin/env bats
# Tests for bin/ utility scripts

load test_helper/common

setup() {
    setup_test_env
}

teardown() {
    cleanup_test_env
}

# dotfiles-doctor tests
@test "dotfiles-doctor script exists and is executable" {
    [[ -f bin/dotfiles-doctor ]]
    [[ -x bin/dotfiles-doctor ]]
}

@test "dotfiles-doctor runs without errors" {
    skip "Requires full system setup"
}

# dotfiles-update tests
@test "dotfiles-update script exists and is executable" {
    [[ -f bin/dotfiles-update ]]
    [[ -x bin/dotfiles-update ]]
}

@test "dotfiles-update detects missing dotfiles directory" {
    skip "Requires controlled environment"
}

# dotfiles-backup tests
@test "dotfiles-backup script exists and is executable" {
    [[ -f bin/dotfiles-backup ]]
    [[ -x bin/dotfiles-backup ]]
}

@test "dotfiles-backup accepts --help flag" {
    run bin/dotfiles-backup --help
    assert_success
    assert_output --partial "Usage:"
}

@test "dotfiles-backup accepts --compress flag" {
    skip "Requires full system setup"
}

@test "dotfiles-backup accepts --cleanup flag" {
    skip "Requires full system setup"
}

# dotfiles-worktree tests
@test "dotfiles-worktree script exists and is executable" {
    [[ -f bin/dotfiles-worktree ]]
    [[ -x bin/dotfiles-worktree ]]
}

@test "dotfiles-worktree accepts --help flag" {
    run bin/dotfiles-worktree --help
    assert_success
    assert_output --partial "Usage:"
}

# Platform detection script tests
@test "platform detection helper exists" {
    [[ -f bin/platform ]]
}

@test "platform detection helper is executable" {
    [[ -x bin/platform ]]
}

@test "platform helper has proper shebang" {
    head -n1 bin/platform | grep -q "^#!/"
}

@test "executable checker exists and is executable" {
    [[ -f bin/is-executable ]]
    [[ -x bin/is-executable ]]
}

# General script validation
@test "all bin scripts have execute permission" {
    for script in bin/*; do
        if [[ -f "$script" ]] && [[ "$script" != */README.md ]]; then
            [[ -x "$script" ]] || {
                echo "Script not executable: $script"
                return 1
            }
        fi
    done
}

@test "no bin scripts have syntax errors" {
    skip_if_command_not_found bash
    for script in bin/*; do
        if [[ -f "$script" ]] && [[ "$script" != */README.md ]]; then
            if head -n1 "$script" | grep -q "bash"; then
                bash -n "$script" || {
                    echo "Syntax error in: $script"
                    return 1
                }
            fi
        fi
    done
}
