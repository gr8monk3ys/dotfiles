#!/usr/bin/env bats
# Tests for bin/ utility scripts

load test_helper/common

setup() {
    setup_test_env
}

teardown() {
    cleanup_test_env
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

# bin/README.md is an index that points at each script's --help rather than
# repeating it, so every script must answer --help, and must do it without
# acting: a script that ignored the flag would run for real here.
@test "every bin script prints help for --help and exits 0" {
    local script
    for script in bin/*; do
        [[ -f "$script" && "$script" != */README.md ]] || continue
        run env HOME="$TEST_HOME" "$script" --help </dev/null
        [[ "$status" -eq 0 && -n "$output" ]] || {
            echo "no --help: $script (status $status)"
            return 1
        }
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

# dotfiles-why tests
@test "dotfiles-why prints the rationale from the manifest line" {
    run bin/dotfiles-why ripgrep
    assert_success
    assert_output --partial "### ripgrep"
    assert_output --partial "Fast recursive grep"
    assert_output --partial "Installed via:** brew, pacman"
}

@test "dotfiles-why finds a package by the command it provides" {
    run bin/dotfiles-why rg
    assert_success
    assert_output --partial "### ripgrep"
    assert_output --partial "Command:** \`rg\`"
    # Only the Brewfile line names rg, but the pacmanfile installs ripgrep too.
    assert_output --partial "Installed via:** brew, pacman"
}

@test "dotfiles-why --list lists each package once" {
    run bash -c 'bin/dotfiles-why --list | sort | uniq -d'
    assert_success
    assert_output ""
    run bin/dotfiles-why --list
    assert_output --partial "ripgrep"
}

@test "dotfiles-why fails cleanly on unknown tool" {
    run bin/dotfiles-why this-tool-does-not-exist
    assert_failure
    assert_output --partial "No manifest entry"
}
