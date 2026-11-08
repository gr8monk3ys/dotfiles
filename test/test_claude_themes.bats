#!/usr/bin/env bats
# Tests for bin/claude-themes.
#
# Everything here runs against a fixture themes directory under
# $TEST_TEMP_DIR. The real ~/.claude is never read or written: a running
# Claude Code session watches that directory and would reload mid-test.

load test_helper/common

setup() {
    setup_test_env
    export FAKE_REPO="$TEST_TEMP_DIR/checkout"
    export THEMES="$TEST_TEMP_DIR/claude/themes"
    mkdir -p "$FAKE_REPO/.config/claude/themes"
    printf '{"name":"One","base":"dark","overrides":{}}\n' > "$FAKE_REPO/.config/claude/themes/one.json"
    printf '{"name":"Two","base":"light","overrides":{}}\n' > "$FAKE_REPO/.config/claude/themes/two.json"
}

teardown() {
    cleanup_test_env
}

# Run the tool against the fixture directory.
ct() {
    run env DOTFILES_DIR="$FAKE_REPO" HOME="$TEST_HOME" \
        bash "$DOTFILES_DIR/bin/claude-themes" "$@" --target "$THEMES"
}

@test "claude-themes is executable" {
    [[ -x "$DOTFILES_DIR/bin/claude-themes" ]]
}

@test "--help prints usage and exits 0" {
    run bash "$DOTFILES_DIR/bin/claude-themes" --help
    assert_success
    assert_output --partial "claude-themes install"
}

@test "no command is a usage error" {
    run bash "$DOTFILES_DIR/bin/claude-themes"
    [[ "$status" -eq 2 ]]
}

@test "an unknown argument is a usage error" {
    ct status --nope
    [[ "$status" -eq 2 ]]
}

@test "every state in --states is documented in the header" {
    run bash "$DOTFILES_DIR/bin/claude-themes" --states
    assert_success
    for st in $output; do
        grep -q "^#   $st " "$DOTFILES_DIR/bin/claude-themes" ||
            { echo "state $st is not documented"; return 1; }
    done
}

@test "status reports absent before install" {
    ct status
    assert_success
    [[ "$output" == *"absent"$'\t'"$THEMES/one.json"* ]]
    [[ "$output" == *"absent"$'\t'"$THEMES/two.json"* ]]
}

@test "install --copy places identical regular files" {
    ct install --copy
    assert_success
    [[ -f "$THEMES/one.json" && ! -L "$THEMES/one.json" ]]
    cmp -s "$THEMES/one.json" "$FAKE_REPO/.config/claude/themes/one.json"
    ct status
    [[ "$output" == *"installed"$'\t'"$THEMES/two.json"* ]]
}

@test "install symlinks into the checkout by default" {
    # Git Bash emulates `ln -s` with a copy unless told otherwise, so there is
    # no symlink to assert on there.
    [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* ]] && skip "no native symlinks"
    ct install
    assert_success
    [[ -L "$THEMES/one.json" ]]
    [[ "$(readlink -f "$THEMES/one.json")" \
        == "$(readlink -f "$FAKE_REPO/.config/claude/themes/one.json")" ]]
    ct status
    [[ "$output" == *"linked"$'\t'"$THEMES/one.json"* ]]
}

@test "install is idempotent and takes no backup of its own file" {
    ct install --copy
    ct install --copy
    assert_success
    assert_output --partial "already installed"
    run bash -c 'ls "$1"/*.bak.* 2>/dev/null' _ "$THEMES"
    [[ -z "$output" ]]
}

@test "a foreign theme is backed up, not clobbered" {
    mkdir -p "$THEMES"
    printf '{"name":"Mine"}\n' > "$THEMES/one.json"
    ct status
    [[ "$output" == *"foreign"$'\t'"$THEMES/one.json"* ]]
    ct install --copy
    assert_success
    cmp -s "$THEMES/one.json" "$FAKE_REPO/.config/claude/themes/one.json"
    run bash -c 'cat "$1"/one.json.bak.*' _ "$THEMES"
    assert_output '{"name":"Mine"}'
}

@test "install leaves themes it does not track alone" {
    mkdir -p "$THEMES"
    printf '{"name":"Scratch"}\n' > "$THEMES/scratch.json"
    ct install --copy
    assert_success
    run cat "$THEMES/scratch.json"
    assert_output '{"name":"Scratch"}'
}

@test "--dry-run changes nothing" {
    ct install --copy --dry-run
    assert_success
    assert_output --partial "Would place one.json"
    [[ ! -e "$THEMES" ]]
}

@test "remove deletes its own themes and keeps a foreign one" {
    ct install --copy
    printf '{"name":"Edited"}\n' > "$THEMES/two.json"
    ct remove
    assert_success
    [[ ! -e "$THEMES/one.json" ]]
    run cat "$THEMES/two.json"
    assert_output '{"name":"Edited"}'
}

@test "the default target follows CLAUDE_CONFIG_DIR, then HOME" {
    run env DOTFILES_DIR="$FAKE_REPO" HOME="$TEST_HOME" CLAUDE_CONFIG_DIR="$TEST_TEMP_DIR/cfg" \
        bash "$DOTFILES_DIR/bin/claude-themes" status
    assert_output --partial "$TEST_TEMP_DIR/cfg/themes/one.json"
    run env -u CLAUDE_CONFIG_DIR DOTFILES_DIR="$FAKE_REPO" HOME="$TEST_HOME" \
        bash "$DOTFILES_DIR/bin/claude-themes" status
    assert_output --partial "$TEST_HOME/.claude/themes/one.json"
}

@test "the tracked themes are valid JSON with the three documented fields only" {
    command -v python3 > /dev/null || skip "python3 not available"
    run python3 - "$DOTFILES_DIR/.config/claude/themes" << 'EOF'
import json, pathlib, re, sys
ok = True
for f in sorted(pathlib.Path(sys.argv[1]).glob("*.json")):
    d = json.loads(f.read_text(encoding="utf-8"))
    extra = set(d) - {"name", "base", "overrides"}
    if extra:
        print(f"{f.name}: unknown fields {sorted(extra)}"); ok = False
    for token, value in d.get("overrides", {}).items():
        if not re.fullmatch(r"#[0-9a-f]{6}", value):
            print(f"{f.name}: {token} is {value!r}, not #rrggbb"); ok = False
sys.exit(0 if ok else 1)
EOF
    assert_success
}
