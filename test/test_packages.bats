#!/usr/bin/env bats
# Tests for package file validation

load test_helper/common

setup() {
    setup_test_env
}

teardown() {
    cleanup_test_env
}

@test "Brewfile has valid format" {
    run grep -E "^(brew|tap|cask|vscode|mas)" install/Brewfile
    assert_success
}

@test "Caskfile has valid format" {
    run grep -E "^cask " install/Caskfile
    assert_success
}

@test "npmfile has valid format (one package per line)" {
    # Check no empty lines or comments
    while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        [[ ! "$line" =~ ^# ]] || continue
        # Should be a valid npm package name
        [[ "$line" =~ ^[@a-z0-9][a-z0-9._/-]*$ ]] || {
            echo "Invalid package name: $line"
            return 1
        }
    done < install/npmfile
}

@test "Rustfile has valid format (one package per line)" {
    while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        [[ ! "$line" =~ ^# ]] || continue
        # Should be a valid cargo package name
        [[ "$line" =~ ^[a-z0-9][a-z0-9_-]*$ ]] || {
            echo "Invalid package name: $line"
            return 1
        }
    done < install/Rustfile
}

@test "Codefile has valid format (extension IDs or comments)" {
    while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        # Allow comments
        [[ "$line" =~ ^# ]] && continue
        # Should be a valid extension ID (publisher.extension)
        [[ "$line" =~ ^[a-zA-Z0-9-]+\.[a-zA-Z0-9-]+$ ]] || {
            echo "Invalid extension ID: $line"
            return 1
        }
    done < install/Codefile
}

@test "pacmanfile has valid format" {
    while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        [[ ! "$line" =~ ^# ]] || continue
        # Should be a valid package name (lowercase, alphanumeric, -, _)
        [[ "$line" =~ ^[a-z0-9][a-z0-9._+-]*$ ]] || {
            echo "Invalid package name: $line"
            return 1
        }
    done < install/pacmanfile
}

@test "duti file has valid format" {
    while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        [[ ! "$line" =~ ^# ]] || continue
        # Format: bundle_id UTI role
        [[ "$line" =~ ^[a-zA-Z0-9.-]+[[:space:]]+[a-zA-Z0-9.-]+[[:space:]]+(all|viewer|editor|shell)$ ]] || {
            echo "Invalid duti line: $line"
            return 1
        }
    done < install/duti
}

