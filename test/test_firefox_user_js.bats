#!/usr/bin/env bats
# Tests for bin/firefox-user-js.
#
# Everything here runs against a fixture Firefox root under $TEST_TEMP_DIR.
# The real ~/Library/Application Support/Firefox is never read or written:
# these profiles hold a live browser's history, and a test that touched one
# would be a test nobody dares run.
#
# DOTFILES_DIR is pointed at a fake checkout so the 81KB arkenfox file is not
# copied around 20 times; the script must still find bin/platform, which it
# resolves from SCRIPT_DIR rather than from the checkout it operates on.

load test_helper/common

setup() {
    setup_test_env
    export FAKE_REPO="$TEST_TEMP_DIR/checkout"
    export FF_ROOT="$TEST_TEMP_DIR/firefox"
    mkdir -p "$FAKE_REPO/.config/firefox"
    printf 'user_pref("dotfiles.test", true);\n' > "$FAKE_REPO/.config/firefox/user.js"
    mkdir -p "$FF_ROOT"
}

teardown() {
    cleanup_test_env
}

# Run the tool against the fixture root.
fj() {
    run env DOTFILES_DIR="$FAKE_REPO" HOME="$TEST_HOME" \
        bash "$DOTFILES_DIR/bin/firefox-user-js" "$@" --root "$FF_ROOT"
}

# Write a profiles.ini into the fixture root.
ini() {
    cat > "$FF_ROOT/profiles.ini"
}

# The layout of the machine this was written for: an [Install…] section
# naming the live profile, and a second profile carrying the legacy Default=1.
two_profiles() {
    mkdir -p "$FF_ROOT/Profiles/live" "$FF_ROOT/Profiles/dead"
    ini << 'EOF'
[General]
StartWithLastProfile=1
Version=2

[Profile0]
Name=default-release
IsRelative=1
Path=Profiles/live

[Install2656FF1E876E9973]
Default=Profiles/live
Locked=1

[Profile1]
Name=default
IsRelative=1
Path=Profiles/dead
Default=1
EOF
}

# The state column for the profile whose path ends in $1.
state_of() {
    printf '%s\n' "$output" | awk -F'\t' -v w="$1" '$2 ~ w"$" { print $1 }'
}

# The role column for the profile whose path ends in $1.
role_of() {
    printf '%s\n' "$output" | awk -F'\t' -v w="$1" '$2 ~ w"$" { print $1 }'
}

@test "firefox-user-js is executable" {
    [[ -x "$DOTFILES_DIR/bin/firefox-user-js" ]]
}

# ---------- discovery ----------

@test "profiles come from profiles.ini, and an [Install] Default beats Default=1" {
    two_profiles
    fj profiles
    assert_success
    [[ "$(role_of Profiles/live)" == "default" ]]
    [[ "$(role_of Profiles/dead)" == "other" ]]
}

@test "a profile directory not named by profiles.ini is never discovered" {
    two_profiles
    mkdir -p "$FF_ROOT/Profiles/stale-glob-bait"
    fj profiles
    assert_success
    [[ "$output" != *stale-glob-bait* ]]
}

@test "without an [Install] section, Default=1 names the default profile" {
    mkdir -p "$FF_ROOT/Profiles/a" "$FF_ROOT/Profiles/b"
    ini << 'EOF'
[Profile0]
Path=Profiles/a
IsRelative=1

[Profile1]
Path=Profiles/b
IsRelative=1
Default=1
EOF
    fj profiles
    assert_success
    [[ "$(role_of Profiles/a)" == "other" ]]
    [[ "$(role_of Profiles/b)" == "default" ]]
}

@test "IsRelative=0 means the Path is already absolute" {
    mkdir -p "$TEST_TEMP_DIR/elsewhere"
    ini << EOF
[Profile0]
Path=$TEST_TEMP_DIR/elsewhere
IsRelative=0
Default=1
EOF
    fj profiles
    assert_success
    assert_output "default	$TEST_TEMP_DIR/elsewhere"
}

@test "a CRLF profiles.ini parses the same as a LF one" {
    mkdir -p "$FF_ROOT/Profiles/live"
    printf '[Profile0]\r\nPath=Profiles/live\r\nIsRelative=1\r\nDefault=1\r\n' \
        > "$FF_ROOT/profiles.ini"
    fj profiles
    assert_success
    assert_output "default	$FF_ROOT/Profiles/live"
}

@test "a missing profiles.ini fails loudly instead of reporting no profiles" {
    fj status
    assert_failure
    assert_output --partial "No profiles.ini"
}

# ---------- state ----------

@test "a profile with no user.js is absent" {
    two_profiles
    fj status
    assert_success
    [[ "$(state_of Profiles/live)" == "absent" ]]
}

@test "a profile whose directory is gone is missing, not absent" {
    two_profiles
    rmdir "$FF_ROOT/Profiles/dead"
    fj status
    assert_success
    [[ "$(state_of Profiles/dead)" == "missing" ]]
}

@test "a user.js this checkout did not write is foreign" {
    two_profiles
    printf 'user_pref("someone.elses", 1);\n' > "$FF_ROOT/Profiles/live/user.js"
    fj status
    assert_success
    [[ "$(state_of Profiles/live)" == "foreign" ]]
}

@test "a symlink pointing somewhere other than the checkout is foreign" {
    two_profiles
    printf 'x\n' > "$TEST_TEMP_DIR/other.js"
    ln -s "$TEST_TEMP_DIR/other.js" "$FF_ROOT/Profiles/live/user.js"
    fj status
    assert_success
    [[ "$(state_of Profiles/live)" == "foreign" ]]
}

@test "a broken symlink is foreign, not linked" {
    two_profiles
    ln -s "$TEST_TEMP_DIR/gone.js" "$FF_ROOT/Profiles/live/user.js"
    fj status
    assert_success
    [[ "$(state_of Profiles/live)" == "foreign" ]]
}

@test "--states lists the vocabulary the header documents" {
    fj --states
    assert_success
    local st
    for st in $output; do
        grep -q "^#   $st " "$DOTFILES_DIR/bin/firefox-user-js" ||
            { echo "state '$st' is not documented in the script header"; return 1; }
    done
}

# ---------- install ----------

@test "install links the default profile and leaves the others alone" {
    two_profiles
    fj install
    assert_success
    [[ -L "$FF_ROOT/Profiles/live/user.js" ]]
    [[ ! -e "$FF_ROOT/Profiles/dead/user.js" ]]
}

@test "install --all reaches every profile" {
    two_profiles
    fj install --all
    assert_success
    [[ -L "$FF_ROOT/Profiles/live/user.js" ]]
    [[ -L "$FF_ROOT/Profiles/dead/user.js" ]]
}

@test "an installed profile reports linked" {
    two_profiles
    fj install
    fj status
    assert_success
    [[ "$(state_of Profiles/live)" == "linked" ]]
}

@test "the symlink resolves to the checkout's user.js" {
    two_profiles
    fj install
    [[ "$(readlink -f "$FF_ROOT/Profiles/live/user.js")" \
        == "$(readlink -f "$FAKE_REPO/.config/firefox/user.js")" ]]
}

@test "editing the checkout's user.js reaches the profile without reinstalling" {
    two_profiles
    fj install
    printf 'user_pref("edited.after.install", true);\n' \
        >> "$FAKE_REPO/.config/firefox/user.js"
    grep -q "edited.after.install" "$FF_ROOT/Profiles/live/user.js"
}

@test "install --copy writes a regular file identical to the checkout's" {
    two_profiles
    fj install --copy
    assert_success
    [[ -f "$FF_ROOT/Profiles/live/user.js" ]]
    [[ ! -L "$FF_ROOT/Profiles/live/user.js" ]]
    cmp -s "$FF_ROOT/Profiles/live/user.js" "$FAKE_REPO/.config/firefox/user.js"
}

@test "a copied user.js reports installed, not foreign" {
    two_profiles
    fj install --copy
    fj status
    assert_success
    [[ "$(state_of Profiles/live)" == "installed" ]]
}

@test "install --dry-run changes nothing" {
    two_profiles
    fj install --dry-run
    assert_success
    assert_output --partial "Would link"
    [[ ! -e "$FF_ROOT/Profiles/live/user.js" ]]
}

@test "install skips a profile whose directory is gone rather than creating it" {
    two_profiles
    rmdir "$FF_ROOT/Profiles/dead"
    fj install --all
    assert_success
    assert_output --partial "Skipping"
    [[ ! -d "$FF_ROOT/Profiles/dead" ]]
}

# ---------- never clobber ----------

@test "a foreign user.js is backed up before being replaced" {
    two_profiles
    printf 'user_pref("someone.elses", 1);\n' > "$FF_ROOT/Profiles/live/user.js"
    fj install
    assert_success
    assert_output --partial "Backed up"
    local backups
    backups="$(find "$FF_ROOT/Profiles/live" -name 'user.js.bak.*' | wc -l | tr -d ' ')"
    [[ "$backups" -eq 1 ]]
    grep -q "someone.elses" "$FF_ROOT"/Profiles/live/user.js.bak.*
}

@test "a second install neither rewrites nor re-backs-up" {
    two_profiles
    printf 'user_pref("someone.elses", 1);\n' > "$FF_ROOT/Profiles/live/user.js"
    fj install
    fj install
    assert_success
    assert_output --partial "Already current"
    [[ "$output" != *"Backed up"* ]]
    local backups
    backups="$(find "$FF_ROOT/Profiles/live" -name 'user.js.bak.*' | wc -l | tr -d ' ')"
    [[ "$backups" -eq 1 ]]
}

@test "switching symlink to copy replaces our own file without a backup" {
    two_profiles
    fj install
    fj install --copy
    assert_success
    [[ ! -L "$FF_ROOT/Profiles/live/user.js" ]]
    local backups
    backups="$(find "$FF_ROOT/Profiles/live" -name 'user.js.bak.*' | wc -l | tr -d ' ')"
    [[ "$backups" -eq 0 ]]
}

# ---------- platform ----------

@test "the default root is the platform's Firefox directory under \$HOME" {
    # Platform checks are inline (see test_helper/common): a helper that asked
    # bin/platform would make this skip instead of fail if platform broke.
    local root
    if is_macos; then
        root="$TEST_HOME/Library/Application Support/Firefox"
    else
        root="$TEST_HOME/.mozilla/firefox"
    fi
    mkdir -p "$root/Profiles/live"
    printf '[Profile0]\nPath=Profiles/live\nIsRelative=1\nDefault=1\n' > "$root/profiles.ini"

    # Deliberately not the fj() helper: this is the one case that must not
    # pass --root.
    run env DOTFILES_DIR="$FAKE_REPO" HOME="$TEST_HOME" \
        bash "$DOTFILES_DIR/bin/firefox-user-js" profiles
    assert_success
    assert_output "default	$root/Profiles/live"
}

# ---------- interface ----------

@test "an unknown command exits 2 and names the real ones" {
    fj bogus
    assert_failure
    [[ "$status" -eq 2 ]]
    assert_output --partial "profiles status install"
}

@test "an unknown option exits 2" {
    fj --nope
    assert_failure
    [[ "$status" -eq 2 ]]
}

@test "--help prints usage and exits 0" {
    run bash "$DOTFILES_DIR/bin/firefox-user-js" --help
    assert_success
    assert_output --partial "Usage:"
}

@test "no command prints usage and exits 2" {
    run bash "$DOTFILES_DIR/bin/firefox-user-js"
    [[ "$status" -eq 2 ]]
    assert_output --partial "Usage:"
}
