#!/usr/bin/env bats
# Tests for bin/manifest (the single reader of install/ package manifests).
#
# Format validation of the real manifests lives in test_packages.bats; these
# exercise the module's own interface against fixture manifests.

load test_helper/common

setup() {
    setup_test_env
    export FIXTURE="$TEST_TEMP_DIR/root"
    mkdir -p "$FIXTURE/install"
    cp install/* "$FIXTURE/install/"
}

teardown() {
    cleanup_test_env
}

manifest() {
    run env DOTFILES_DIR="$FIXTURE" bin/manifest "$@"
}

@test "manifest is executable" {
    [[ -x "$DOTFILES_DIR/bin/manifest" ]]
}

@test "kinds lists the vocabulary and excludes duti" {
    manifest kinds
    assert_success
    assert_output --partial "brew"
    assert_output --partial "cask-extra"
    assert_output --partial "code"
    [[ "$output" != *"duti"* ]]
}

@test "list rejects an unknown kind" {
    manifest list nonsense
    assert_failure
    assert_output --partial "unknown kind"
}

@test "list requires a kind" {
    manifest list
    assert_failure
    assert_output --partial "kind required"
}

@test "list strips the tap prefix from a tap-qualified formula" {
    echo 'brew "some-tap/repo/toolname"' >> "$FIXTURE/install/Brewfile"
    manifest list brew
    assert_success
    assert_output --partial "toolname"
    [[ "$output" != *"some-tap/repo/toolname"* ]]
}

@test "list skips tap lines in the Brewfile" {
    manifest list brew
    assert_success
    # Taps are not packages; they come from `manifest taps`.
    [[ "$output" != *"FelixKratz/formulae"* ]]
}

@test "taps returns the declared taps" {
    manifest taps
    assert_success
    assert_output --partial "FelixKratz/formulae"
    assert_output --partial "oven-sh/bun"
}

@test "list ignores comments and blank lines" {
    printf '\n# a comment\n\n' >> "$FIXTURE/install/npmfile"
    manifest list npm
    assert_success
    [[ "$output" != *"comment"* ]]
}

@test "list fails on an unparseable line, naming file and line" {
    echo 'two words here' >> "$FIXTURE/install/npmfile"
    manifest list npm
    assert_failure
    assert_output --partial "npmfile:"
}

@test "list fails on a name that breaks the ecosystem grammar" {
    echo 'Not-A-Crate' >> "$FIXTURE/install/Rustfile"
    manifest list rust
    assert_failure
    assert_output --partial "invalid package name: Not-A-Crate"
}

@test "list enforces publisher.extension for Codefile ids" {
    echo 'nopublisherdot' >> "$FIXTURE/install/Codefile"
    manifest list code
    assert_failure
    assert_output --partial "invalid package name"
}

@test "list accepts npm scoped packages" {
    echo '@scope/pkg' >> "$FIXTURE/install/npmfile"
    manifest list npm
    assert_success
    assert_output --partial "@scope/pkg"
}

@test "list fails cleanly when a manifest is missing" {
    rm "$FIXTURE/install/Rustfile"
    manifest list rust
    assert_failure
    assert_output --partial "missing manifest"
}

@test "list emits one name per line with no decoration" {
    manifest list pacman
    assert_success
    run bash -c "env DOTFILES_DIR='$FIXTURE' bin/manifest list pacman | grep -cvE '^[a-z0-9][a-z0-9._+-]*$'"
    assert_output "0"
}

@test "DOTFILES_DIR redirects the module at another root" {
    # The tests below rely on this to run against fixture roots.
    echo 'brew "fixture-only-tool"' >> "$FIXTURE/install/Brewfile"
    manifest list brew
    assert_success
    assert_output --partial "fixture-only-tool"

    run bin/manifest list brew
    assert_success
    [[ "$output" != *"fixture-only-tool"* ]]
}

# ---------- the entry line: rationale and metadata ----------

@test "a bare manifest accepts a trailing comment" {
    echo 'fixture-crate   # why it is here' >> "$FIXTURE/install/Rustfile"
    manifest list rust
    assert_success
    assert_output --partial "fixture-crate"
    [[ "$output" != *"why"* ]]
}

@test "entries splits metadata from the rationale" {
    echo 'brew "fixture-grep"   # cmd=fg tier=essential Greps fixtures, fast.' >> "$FIXTURE/install/Brewfile"
    manifest entries brew
    assert_success
    assert_output --partial "$(printf 'brew\tfixture-grep\tfg\tessential\tGreps fixtures, fast.')"
}

@test "entries reports the package name as the command when cmd= is absent" {
    echo 'fixture-crate  # Plain rationale.' >> "$FIXTURE/install/Rustfile"
    manifest entries rust
    assert_success
    assert_output --partial "$(printf 'rust\tfixture-crate\tfixture-crate\t\tPlain rationale.')"
}

@test "brew-bundle arguments before the comment are not rationale" {
    echo 'brew "fixture-svc", restart_service: :changed  # Runs a service.' >> "$FIXTURE/install/Brewfile"
    manifest entries brew
    assert_success
    assert_output --partial "$(printf 'fixture-svc\tfixture-svc\t\tRuns a service.')"
}

@test "an unknown metadata key is a parse error naming file and line" {
    echo 'fixture-crate  # colour=red Rationale.' >> "$FIXTURE/install/Rustfile"
    manifest list rust
    assert_failure
    assert_output --partial "Rustfile:"
    assert_output --partial "unknown metadata key 'colour'"
}

@test "a tier outside the vocabulary is a parse error" {
    echo 'brew "fixture-tool"  # tier=vital Rationale.' >> "$FIXTURE/install/Brewfile"
    manifest list brew
    assert_failure
    assert_output --partial "tier=vital"
}

@test "a repeated metadata key is a parse error" {
    echo 'brew "fixture-tool"  # cmd=a cmd=b Rationale.' >> "$FIXTURE/install/Brewfile"
    manifest list brew
    assert_failure
    assert_output --partial "cmd=b"
}

@test "describe finds an entry by its command as well as its name" {
    echo 'brew "fixture-grep"  # cmd=fg Greps fixtures.' >> "$FIXTURE/install/Brewfile"
    manifest describe fg
    assert_success
    assert_output --partial "fixture-grep"
    manifest describe fixture-grep
    assert_success
    assert_output --partial "Greps fixtures."
}

@test "describe fails when nothing matches" {
    manifest describe no-such-package-anywhere
    assert_failure
}

@test "tier lists commands, once each, and rejects an unknown tier" {
    echo 'brew "fixture-grep"  # cmd=fg tier=additional Greps.' >> "$FIXTURE/install/Brewfile"
    echo 'fixture-grep  # cmd=fg tier=additional Greps on Arch.' >> "$FIXTURE/install/pacmanfile"
    manifest tier additional
    assert_success
    [[ "$(printf '%s\n' "$output" | grep -cx fg)" -eq 1 ]]
    manifest tier vital
    assert_failure
}
