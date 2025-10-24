#!/usr/bin/env bats
# Tests for package file validation

load test_helper/common

setup() {
    setup_test_env
}

teardown() {
    cleanup_test_env
}

# Brewfile tests
@test "Brewfile exists" {
    [[ -f install/Brewfile ]]
}

@test "Brewfile has valid format" {
    run grep -E "^(brew|tap|cask|vscode|mas)" install/Brewfile
    assert_success
}

@test "Brewfile contains at least one package" {
    run grep -c "^brew " install/Brewfile
    [[ "$output" -gt 0 ]]
}

# Caskfile tests
@test "Caskfile exists" {
    [[ -f install/Caskfile ]]
}

@test "Caskfile has valid format" {
    run grep -E "^cask " install/Caskfile
    assert_success
}

@test "Caskfile contains at least one application" {
    run grep -c "^cask " install/Caskfile
    [[ "$output" -gt 0 ]]
}

# npmfile tests
@test "npmfile exists" {
    [[ -f install/npmfile ]]
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

@test "npmfile contains at least one package" {
    run grep -v "^#" install/npmfile
    [[ -n "$output" ]]
}

# Rustfile tests
@test "Rustfile exists" {
    [[ -f install/Rustfile ]]
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

@test "Rustfile contains at least one package" {
    run grep -v "^#" install/Rustfile
    [[ -n "$output" ]]
}

# Codefile tests
@test "Codefile exists" {
    [[ -f install/Codefile ]]
}

@test "Codefile has valid format (extension IDs or comments)" {
    while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        # Allow comments
        [[ "$line" =~ ^# ]] && continue
        # Should be a valid extension ID (publisher.extension)
        [[ "$line" =~ ^[a-z0-9-]+\.[a-z0-9-]+$ ]] || {
            echo "Invalid extension ID: $line"
            return 1
        }
    done < install/Codefile
}

# pacmanfile tests
@test "pacmanfile exists" {
    [[ -f install/pacmanfile ]]
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

# duti file tests
@test "duti file exists" {
    [[ -f install/duti ]]
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

# General package file tests
@test "all package files are readable" {
    for file in install/{Brewfile,Caskfile,npmfile,Rustfile,Codefile,pacmanfile,duti}; do
        [[ -r "$file" ]] || {
            echo "File not readable: $file"
            return 1
        }
    done
}

@test "no package files are empty" {
    for file in install/{Brewfile,Caskfile,npmfile,Rustfile,pacmanfile,duti}; do
        [[ -s "$file" ]] || {
            echo "File is empty: $file"
            return 1
        }
    done
}

@test "install README exists and is not empty" {
    [[ -f install/README.md ]]
    [[ -s install/README.md ]]
}
