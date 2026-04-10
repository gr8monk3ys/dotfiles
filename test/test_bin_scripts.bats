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

@test "dotfiles-doctor runs and reaches summary" {
    run env HOME="$TEST_HOME" DOTFILES_DIR="$TEST_HOME/.dotfiles" \
        PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
        bash bin/dotfiles-doctor
    # Mock env is incomplete so issues will be found, but it should reach summary
    assert_output --partial "Summary"
}

# dotfiles-update tests
@test "dotfiles-update script exists and is executable" {
    [[ -f bin/dotfiles-update ]]
    [[ -x bin/dotfiles-update ]]
}

@test "dotfiles-update detects missing dotfiles directory" {
    run env HOME="$TEST_HOME" DOTFILES_DIR="$TEST_HOME/nonexistent" \
        PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
        bash bin/dotfiles-update
    assert_failure
    assert_output --partial "not found"
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
    mkdir -p "$TEST_TEMP_DIR/backups"
    printf 'export TEST=1\n' > "$TEST_HOME/.zshrc"
    run env HOME="$TEST_HOME" BACKUP_DIR="$TEST_TEMP_DIR/backups" \
        PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
        bash bin/dotfiles-backup --compress
    assert_success
    assert_output --partial "Backup completed successfully!"
}

@test "dotfiles-backup accepts --cleanup flag" {
    mkdir -p "$TEST_TEMP_DIR/backups/20260101_000000"
    run env HOME="$TEST_HOME" BACKUP_DIR="$TEST_TEMP_DIR/backups" \
        PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
        bash bin/dotfiles-backup --cleanup
    assert_success
}

# dotfiles-restore tests
@test "dotfiles-restore script exists and is executable" {
    [[ -f bin/dotfiles-restore ]]
    [[ -x bin/dotfiles-restore ]]
}

@test "dotfiles-restore accepts --help flag" {
    run bin/dotfiles-restore --help
    assert_success
    assert_output --partial "Usage:"
}

@test "dotfiles-restore restores files from a backup snapshot" {
    local backup_path="$TEST_TEMP_DIR/backups/20260101_010101"
    mkdir -p "$backup_path/configs" "$backup_path/ssh" "$TEST_HOME/.ssh"
    echo "export TEST_RESTORE=1" > "$backup_path/configs/.zshrc"
    echo "Host github.com" > "$backup_path/ssh/config"

    run env HOME="$TEST_HOME" BACKUP_DIR="$TEST_TEMP_DIR/backups" \
        bin/dotfiles-restore "$backup_path"
    assert_success
    [[ -f "$TEST_HOME/.zshrc" ]]
    [[ -f "$TEST_HOME/.ssh/config" ]]
}

# dotfiles-bench-shell tests
@test "dotfiles-bench-shell script exists and is executable" {
    [[ -f bin/dotfiles-bench-shell ]]
    [[ -x bin/dotfiles-bench-shell ]]
}

@test "dotfiles-bench-shell accepts --help flag" {
    run bin/dotfiles-bench-shell --help
    assert_success
    assert_output --partial "Usage:"
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

# dotfiles-nix tests
@test "dotfiles-nix script exists and is executable" {
    [[ -f bin/dotfiles-nix ]]
    [[ -x bin/dotfiles-nix ]]
}

@test "dotfiles-nix accepts help subcommand" {
    run bin/dotfiles-nix help
    assert_success
    assert_output --partial "Usage:"
}
