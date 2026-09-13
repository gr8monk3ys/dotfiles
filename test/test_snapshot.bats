#!/usr/bin/env bats
# Tests for bin/lib/snapshot.sh and dotfiles-restore's use of it.
#
# No package manager runs here. The snapshot layout is exercised against a
# hand-built fixture directory, and the drift check greps dotfiles-backup
# rather than executing it — asserting that `brew` works is not our job.

load test_helper/common

setup() {
    setup_test_env
    export SNAPSHOT_LIB="$DOTFILES_DIR/bin/lib/snapshot.sh"
    export FIXTURE="$TEST_TEMP_DIR/backup/20260909_010000"
    mkdir -p "$FIXTURE"
}

teardown() {
    cleanup_test_env
}

# A snapshot with every artifact the table knows about.
make_full_fixture() {
    mkdir -p "$FIXTURE/configs" "$FIXTURE/ssh"
    echo "# zshrc" > "$FIXTURE/configs/.zshrc"
    echo "Host example" > "$FIXTURE/ssh/config"
    for f in Brewfile Caskfile npm-global-list.txt cargo-installed.txt \
             vscode-extensions.txt vscodium-extensions.txt MANIFEST.txt; do
        echo "# placeholder" > "$FIXTURE/$f"
    done
}

lib() {
    run bash -c 'source "$1"; shift; "$@"' _ "$SNAPSHOT_LIB" "$@"
}

# ---------- the table ----------

@test "snapshot table lists every class" {
    lib snapshot_names_of_class tree
    assert_success
    assert_output --partial "configs"
    assert_output --partial "ssh"

    lib snapshot_names_of_class record
    assert_success
    assert_output --partial "Brewfile"
    assert_output --partial "npm-global-list.txt"

    lib snapshot_names_of_class metadata
    assert_success
    assert_output "MANIFEST.txt"
}

@test "snapshot_class resolves current names" {
    lib snapshot_class configs
    assert_output "tree"
    lib snapshot_class Brewfile
    assert_output "record"
}

@test "snapshot_class resolves legacy names from older snapshots" {
    lib snapshot_class npmfile.txt
    assert_success
    assert_output "record"
    lib snapshot_class Rustfile.txt
    assert_success
    assert_output "record"
}

@test "snapshot_class fails on an unknown artifact" {
    lib snapshot_class not-a-real-artifact
    assert_failure
}

@test "snapshot_present falls back to the legacy filename" {
    echo "old" > "$FIXTURE/npmfile.txt"
    lib snapshot_present "$FIXTURE" npm-global-list.txt
    assert_success
    assert_output "$FIXTURE/npmfile.txt"
}

@test "snapshot_present prefers the current filename over the legacy one" {
    echo "old" > "$FIXTURE/npmfile.txt"
    echo "new" > "$FIXTURE/npm-global-list.txt"
    lib snapshot_present "$FIXTURE" npm-global-list.txt
    assert_output "$FIXTURE/npm-global-list.txt"
}

@test "snapshot_present fails when neither name is there" {
    lib snapshot_present "$FIXTURE" Brewfile
    assert_failure
}

@test "snapshot_provenance makes a record self-describing" {
    printf 'pkg@1.0.0\n' > "$FIXTURE/npm-global-list.txt"
    run bash -c 'source "$1"; snapshot_provenance "$2" "npm list -g"' _ \
        "$SNAPSHOT_LIB" "$FIXTURE/npm-global-list.txt"
    assert_success
    run head -2 "$FIXTURE/npm-global-list.txt"
    assert_output --partial "not an install manifest"
    assert_output --partial "npm list -g"
    # The original content survives.
    run grep -q 'pkg@1.0.0' "$FIXTURE/npm-global-list.txt"
    assert_success
}

# ---------- drift: backup and the table must agree ----------

@test "every artifact dotfiles-backup writes is in the snapshot table" {
    # Greps the source rather than running it: no brew/npm/cargo needed.
    run bash -c '
        set -euo pipefail
        cd "$1"
        source bin/lib/snapshot.sh
        status=0
        # Artifact names backup writes directly under $BACKUP_PATH.
        for name in $(grep -oE "\$BACKUP_PATH/[A-Za-z0-9._-]+" bin/dotfiles-backup \
                        | sed "s|\$BACKUP_PATH/||" | sort -u); do
            snapshot_class "$name" >/dev/null 2>&1 || { echo "not in table: $name"; status=1; }
        done
        exit $status
    ' _ "$DOTFILES_DIR"
    assert_success
}

@test "every table artifact except metadata is written by dotfiles-backup" {
    run bash -c '
        set -euo pipefail
        cd "$1"
        source bin/lib/snapshot.sh
        status=0
        while IFS= read -r name; do
            grep -q "BACKUP_PATH/$name" bin/dotfiles-backup ||
                { echo "in table but never written: $name"; status=1; }
        done < <(snapshot_names_of_class record)
        exit $status
    ' _ "$DOTFILES_DIR"
    assert_success
}

# ---------- restore's behaviour over a fixture ----------

@test "restore replays tree artifacts and reports preserved records" {
    make_full_fixture
    run env HOME="$TEST_HOME" bin/dotfiles-restore "$FIXTURE" --dry-run
    assert_success
    assert_output --partial "Would restore"
    assert_output --partial "Preserved, not replayed"
    assert_output --partial "Brewfile"
    assert_output --partial "npm-global-list.txt"
}

@test "restore warns about an artifact the table does not know" {
    make_full_fixture
    echo "surprise" > "$FIXTURE/mystery-artifact.txt"
    run env HOME="$TEST_HOME" bin/dotfiles-restore "$FIXTURE" --dry-run
    assert_success
    assert_output --partial "not restorable: mystery-artifact.txt"
}

@test "restore does not abort on an unknown artifact" {
    make_full_fixture
    echo "surprise" > "$FIXTURE/mystery-artifact.txt"
    run env HOME="$TEST_HOME" bin/dotfiles-restore "$FIXTURE" --dry-run
    assert_success
    # It still got to the end and did the real work.
    assert_output --partial "Dry run complete"
}

@test "restore actually writes tree artifacts to HOME" {
    make_full_fixture
    run env HOME="$TEST_HOME" bin/dotfiles-restore "$FIXTURE"
    assert_success
    [[ -f "$TEST_HOME/.zshrc" ]]
    [[ -f "$TEST_HOME/.ssh/config" ]]
}

@test "restore leaves package records alone" {
    make_full_fixture
    run env HOME="$TEST_HOME" bin/dotfiles-restore "$FIXTURE"
    assert_success
    # A record must never be copied into HOME.
    [[ ! -e "$TEST_HOME/Brewfile" ]]
    [[ ! -e "$TEST_HOME/npm-global-list.txt" ]]
}

@test "restore reads a pre-rename snapshot without spurious warnings" {
    make_full_fixture
    mv "$FIXTURE/npm-global-list.txt" "$FIXTURE/npmfile.txt"
    mv "$FIXTURE/cargo-installed.txt" "$FIXTURE/Rustfile.txt"
    run env HOME="$TEST_HOME" bin/dotfiles-restore "$FIXTURE" --dry-run
    assert_success
    [[ "$output" != *"not restorable: npmfile.txt"* ]]
    [[ "$output" != *"not restorable: Rustfile.txt"* ]]
}
