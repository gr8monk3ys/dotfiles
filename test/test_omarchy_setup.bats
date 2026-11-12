#!/usr/bin/env bats
# omarchy/ - the Omarchy layer: pinned plugin manifest, bar layout, and
# omarchy/setup.sh (dry run by default). Every Omarchy marker and the
# `omarchy` command are faked, so this runs the same on any machine.

load test_helper/common

SETUP="$DOTFILES_DIR/omarchy/setup.sh"

setup() {
    setup_test_env
    export HOME="$TEST_HOME"
    export XDG_CONFIG_HOME="$TEST_HOME/.config"
    export XDG_STATE_HOME="$TEST_HOME/.local/state"
    export PLATFORM_OS_RELEASE="$TEST_TEMP_DIR/os-release"
    export PLATFORM_OMARCHY_SYSTEM_DIR="$TEST_TEMP_DIR/usr-share-omarchy"
    : > "$PLATFORM_OS_RELEASE"

    # A logging stand-in for the omarchy CLI.
    STUB_BIN="$TEST_TEMP_DIR/bin"
    OMARCHY_LOG="$TEST_TEMP_DIR/omarchy.log"
    export OMARCHY_LOG
    mkdir -p "$STUB_BIN"
    cat > "$STUB_BIN/omarchy" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$OMARCHY_LOG"
case "$1 $2" in
    "plugin list") echo '[]' ;;
    "theme dir") exit 1 ;;
esac
STUB
    chmod +x "$STUB_BIN/omarchy"
    export PATH="$STUB_BIN:$PATH"
}

teardown() {
    cleanup_test_env
}

be_omarchy() { mkdir -p "$PLATFORM_OMARCHY_SYSTEM_DIR"; }

@test "setup.sh dry run on a non-Omarchy machine does nothing and succeeds" {
    run "$SETUP"
    assert_success
    assert_output --partial "Not an Omarchy machine"
    [[ -z "$(ls -A "$TEST_HOME")" ]]
}

@test "setup.sh --apply on a non-Omarchy machine refuses" {
    run "$SETUP" --apply
    assert_failure
    [[ -z "$(ls -A "$TEST_HOME")" ]]
}

@test "setup.sh dry run on Omarchy writes nothing and calls no mutating command" {
    be_omarchy
    run "$SETUP"
    assert_success
    assert_output --partial "Dry run"
    assert_output --partial "would"
    [[ -z "$(ls -A "$TEST_HOME")" ]]
    # Only read-only queries reached the CLI.
    run grep -vE '^(plugin list --json|theme dir vantablack)$' "$OMARCHY_LOG"
    assert_output ""
}

@test "setup.sh rejects an unknown step" {
    run "$SETUP" --only everything
    assert_failure
}

@test "hypr step links the snippet and appends the require exactly once" {
    be_omarchy
    mkdir -p "$XDG_CONFIG_HOME/hypr"
    echo '-- user look' > "$XDG_CONFIG_HOME/hypr/looknfeel.lua"
    run "$SETUP" --apply --only hypr
    assert_success
    run "$SETUP" --apply --only hypr
    assert_success
    assert_output --partial "Everything already in place"
    run grep -c 'require("hypr.monochrome_43")' "$XDG_CONFIG_HOME/hypr/looknfeel.lua"
    assert_output "1"
    [[ "$(readlink "$XDG_CONFIG_HOME/hypr/monochrome_43.lua")" == "$DOTFILES_DIR/omarchy/hypr/monochrome_43.lua" ]]
}

@test "hypr step does not stack a require on top of an inline copy" {
    be_omarchy
    mkdir -p "$XDG_CONFIG_HOME/hypr"
    printf 'hl.curve("riceOut", {})\n' > "$XDG_CONFIG_HOME/hypr/looknfeel.lua"
    run "$SETUP" --apply --only hypr
    assert_success
    run grep -c 'require("hypr.monochrome_43")' "$XDG_CONFIG_HOME/hypr/looknfeel.lua"
    assert_output "0"
}

@test "a differing local plugin is backed up outside the dir Omarchy scans" {
    be_omarchy
    local plugins="$XDG_CONFIG_HOME/omarchy/plugins"
    mkdir -p "$plugins/gr8monk3ys.sysstats"
    echo '{"id": "gr8monk3ys.sysstats"}' > "$plugins/gr8monk3ys.sysstats/manifest.json"
    printf 'gr8monk3ys.sysstats\tlocal\t-\tno\n' > "$TEST_TEMP_DIR/plugins.tsv"
    OMARCHY_PLUGINS_TSV="$TEST_TEMP_DIR/plugins.tsv" run "$SETUP" --apply --only plugins
    assert_success
    [[ "$(readlink "$plugins/gr8monk3ys.sysstats")" == "$DOTFILES_DIR/omarchy/plugins/gr8monk3ys.sysstats" ]]
    [[ -f "$XDG_CONFIG_HOME/omarchy/plugins.dotfiles-bak/gr8monk3ys.sysstats/manifest.json" ]]
    # Nothing but the link is left under plugins/.
    run ls -A "$plugins"
    assert_output "gr8monk3ys.sysstats"
}

@test "plugins.tsv pins every third-party plugin to a full commit over https" {
    run bash -c '
        status=0
        while read -r id src commit enable; do
            [[ -z "$id" || "$id" == \#* ]] && continue
            [[ "$enable" =~ ^(yes|no)$ ]] || { echo "$id: enable must be yes|no"; status=1; }
            if [[ "$src" == local ]]; then
                [[ -f "$1/omarchy/plugins/$id/manifest.json" ]] || { echo "$id: no local plugin"; status=1; }
            else
                [[ "$src" =~ ^https://github\.com/[^/]+/[^/]+\.git$ ]] || { echo "$id: bad source $src"; status=1; }
                [[ "$commit" =~ ^[0-9a-f]{40}$ ]] || { echo "$id: commit not pinned: $commit"; status=1; }
            fi
        done < "$1/omarchy/plugins.tsv"
        exit $status
    ' _ "$DOTFILES_DIR"
    assert_success
}

@test "bar.json only places built-in widgets or plugins the manifest installs" {
    command -v jq > /dev/null || skip "jq not installed"
    run bash -c '
        ids="$(awk "!/^#/ && NF { print \$1 }" "$1/omarchy/plugins.tsv")"
        status=0
        for w in $(jq -r ".layout[][] | .id" "$1/omarchy/bar.json"); do
            [[ "$w" == omarchy.* ]] && continue
            printf "%s\n" "$ids" | grep -Fxq "$w" || { echo "bar.json places $w, which plugins.tsv does not install"; status=1; }
        done
        exit $status
    ' _ "$DOTFILES_DIR"
    assert_success
}

@test "the local sysstats plugin's own tests pass" {
    command -v node > /dev/null || skip "node not installed"
    run node --test "$DOTFILES_DIR/omarchy/plugins/gr8monk3ys.sysstats/tests/"
    assert_success
}
