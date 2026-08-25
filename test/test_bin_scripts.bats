#!/usr/bin/env bats
# Tests for bin/ utility scripts

load test_helper/common

setup() {
    setup_test_env
}

teardown() {
    cleanup_test_env
}

@test "dotfiles-doctor runs and reaches summary" {
    run env HOME="$TEST_HOME" DOTFILES_DIR="$TEST_HOME/.dotfiles" \
        PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
        bash bin/dotfiles-doctor
    # Mock env is incomplete so issues will be found, but it should reach summary
    assert_output --partial "Summary"
}

@test "dotfiles-update detects missing dotfiles directory" {
    run env HOME="$TEST_HOME" DOTFILES_DIR="$TEST_HOME/nonexistent" \
        PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
        bash bin/dotfiles-update
    assert_failure
    assert_output --partial "not found"
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

@test "dotfiles-bench-shell accepts --help flag" {
    run bin/dotfiles-bench-shell --help
    assert_success
    assert_output --partial "Usage:"
}

@test "dotfiles-worktree accepts --help flag" {
    run bin/dotfiles-worktree --help
    assert_success
    assert_output --partial "Usage:"
}

@test "platform helper has proper shebang" {
    head -n1 bin/platform | grep -q "^#!/"
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

# Tool catalog tests
@test "validate-tool-docs passes on current catalog" {
    run bin/validate-tool-docs
    assert_success
    assert_output --partial "in sync"
}

@test "validate-tool-docs fails on undocumented package" {
    cp -r install "$TEST_TEMP_DIR/install"
    mkdir -p "$TEST_TEMP_DIR/docs" "$TEST_TEMP_DIR/bin"
    cp docs/TOOLS.md "$TEST_TEMP_DIR/docs/"
    echo 'brew "made-up-tool"' >> "$TEST_TEMP_DIR/install/Brewfile"
    run bin/validate-tool-docs "$TEST_TEMP_DIR"
    assert_failure
    assert_output --partial "made-up-tool"
}

@test "dotfiles-why prints a known tool entry" {
    run bin/dotfiles-why ripgrep
    assert_success
    assert_output --partial "### ripgrep"
    assert_output --partial "Why:"
}

@test "dotfiles-why fails cleanly on unknown tool" {
    run bin/dotfiles-why this-tool-does-not-exist
    assert_failure
    assert_output --partial "No catalog entry"
}
