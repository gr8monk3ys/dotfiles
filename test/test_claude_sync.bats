#!/usr/bin/env bats
# bin/claude-sync - adds the tracked Claude Code marketplaces, plugins and
# user-scope MCP servers through the `claude` CLI. A logging stub stands in
# for `claude`, so nothing here touches the real ~/.claude or ~/.claude.json.

load test_helper/common

SYNC="$DOTFILES_DIR/bin/claude-sync"

setup() {
    setup_test_env
    export HOME="$TEST_HOME"
    export XDG_CONFIG_HOME="$TEST_HOME/.config"
    unset CLAUDE_CONFIG_DIR
    # Not Omarchy, whatever the host is.
    export PLATFORM_OS_RELEASE="$TEST_TEMP_DIR/os-release"
    export PLATFORM_OMARCHY_SYSTEM_DIR="$TEST_TEMP_DIR/no-omarchy"
    : > "$PLATFORM_OS_RELEASE"

    STUB_BIN="$TEST_TEMP_DIR/bin"
    CLAUDE_LOG="$TEST_TEMP_DIR/claude.log"
    STUB_STATE="$TEST_TEMP_DIR/state"
    export CLAUDE_LOG STUB_STATE
    mkdir -p "$STUB_BIN" "$STUB_STATE"
    echo '[]' > "$STUB_STATE/marketplaces.json"
    echo '[]' > "$STUB_STATE/plugins.json"
    cat > "$STUB_BIN/claude" <<'STUB'
#!/usr/bin/env bash
case "$*" in
    "plugin marketplace list --json") cat "$STUB_STATE/marketplaces.json" ;;
    "plugin list --json") cat "$STUB_STATE/plugins.json" ;;
    *) printf '%s\n' "$*" >> "$CLAUDE_LOG" ;;
esac
STUB
    for tool in uv uvx npx godot; do
        printf '#!/bin/sh\nexit 0\n' > "$STUB_BIN/$tool"
    done
    chmod +x "$STUB_BIN"/*
    export PATH="$STUB_BIN:$PATH"

    export GIMP_MCP_DIR="$TEST_TEMP_DIR/gimp-mcp"
    mkdir -p "$GIMP_MCP_DIR"
    : > "$GIMP_MCP_DIR/gimp_mcp_server.py"
}

teardown() {
    cleanup_test_env
}

everything_present() {
    jq -n '[{name:"claude-plugins-official"},{name:"impeccable"},{name:"agent-browser"},{name:"godot-claude-skills"},{name:"claude-hud"}]' \
        > "$STUB_STATE/marketplaces.json"
    sed -n '/^readonly PLUGINS=/,/'"'"'$/p' "$SYNC" | sed "s/^readonly PLUGINS='//; s/'\$//" |
        jq -R '{id: .}' | jq -s . > "$STUB_STATE/plugins.json"
    jq -n '{mcpServers: {gimp:{}, blender:{}, godot:{}, discord:{}}}' > "$HOME/.claude.json"
}

@test "claude-sync --help prints usage" {
    run "$SYNC" --help
    assert_success
    assert_output --partial "Usage:"
}

@test "claude-sync rejects an unknown part" {
    run "$SYNC" --only everything
    assert_failure
}

@test "claude-sync dry run on a bare machine changes nothing" {
    run "$SYNC"
    assert_success
    assert_output --partial "Dry run"
    assert_output --partial "would   claude plugin install github@claude-plugins-official --scope user"
    [[ ! -e "$CLAUDE_LOG" ]]
}

@test "claude-sync --apply adds marketplaces, plugins and MCP servers" {
    run "$SYNC" --apply
    assert_success
    grep -qx 'plugin marketplace add pbakaus/impeccable' "$CLAUDE_LOG"
    grep -qx 'plugin install superpowers@claude-plugins-official --scope user' "$CLAUDE_LOG"
    grep -qx 'mcp add --scope user blender -e DISABLE_TELEMETRY=true -- uvx --python 3.13 mcp-for-blender' "$CLAUDE_LOG"
    grep -qx "mcp add --scope user gimp -- uv run --python 3.13 --directory $GIMP_MCP_DIR gimp_mcp_server.py" "$CLAUDE_LOG"
    grep -qx 'mcp add --scope user discord --transport http http://127.0.0.1:8085/mcp' "$CLAUDE_LOG"
}

@test "claude-sync points godot-mcp at the platform's Godot" {
    [[ "$OSTYPE" == darwin* ]] && skip "the macOS path is /Applications/Godot.app"
    run "$SYNC" --apply --only mcp
    assert_success
    grep -qx "mcp add --scope user godot -e GODOT_PATH=$STUB_BIN/godot -- npx -y @coding-solo/godot-mcp@0.1.1" "$CLAUDE_LOG"
}

@test "claude-sync skips the Omarchy-only server off Omarchy" {
    run "$SYNC" --apply --only mcp
    assert_success
    assert_output --partial "skip    omarchy: Omarchy only"
    run grep -c 'mcp add --scope user omarchy' "$CLAUDE_LOG"
    assert_output "0"
}

@test "claude-sync skips gimp without a gimp-mcp checkout" {
    rm -rf "$GIMP_MCP_DIR"
    run "$SYNC" --apply --only mcp
    assert_success
    assert_output --partial "skip    gimp: no gimp-mcp checkout"
}

@test "claude-sync is idempotent: nothing to do when everything is present" {
    everything_present
    run "$SYNC" --apply
    assert_success
    assert_output --partial "Everything already in place."
    [[ ! -e "$CLAUDE_LOG" ]]
}

@test "claude-sync carries no secrets" {
    # Tokens come from the environment (gh auth token in .zshrc), never from
    # this file.
    run grep -nEi 'authorization|bearer|ghp_|github_pat_|api[_-]?key|--header' "$SYNC"
    assert_failure
}
