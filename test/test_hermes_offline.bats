#!/usr/bin/env bats
# bin/hermes-offline - sets Hermes Agent's four model keys for the local
# Ollama. Stubs stand in for `hermes` and `ollama`; the real ~/.hermes is
# never touched.

load test_helper/common

SCRIPT="$DOTFILES_DIR/bin/hermes-offline"

setup() {
    setup_test_env
    export HOME="$TEST_HOME"
    STUB_BIN="$TEST_TEMP_DIR/bin"
    export HERMES_STATE="$TEST_TEMP_DIR/hermes"
    mkdir -p "$STUB_BIN" "$HERMES_STATE"
    # `hermes config get|set <key> [value]`, one file per key.
    cat > "$STUB_BIN/hermes" <<'STUB'
#!/usr/bin/env bash
[[ "$1" == config ]] || exit 2
case "$2" in
    get) [[ -f "$HERMES_STATE/$3" ]] && cat "$HERMES_STATE/$3" ;;
    set) printf '%s\n' "$4" > "$HERMES_STATE/$3"; echo "$3" >> "$HERMES_STATE/.sets" ;;
esac
STUB
    cat > "$STUB_BIN/ollama" <<'STUB'
#!/usr/bin/env bash
case "$1" in
    list) printf 'NAME ID SIZE MODIFIED\ngpt-oss:20b abc 13GB now\n' ;;
    pull) echo "$2" >> "$HERMES_STATE/.pulls" ;;
esac
STUB
    chmod +x "$STUB_BIN"/*
    export PATH="$STUB_BIN:$PATH"
    unset HERMES_MODEL HERMES_NUM_CTX
}

teardown() {
    cleanup_test_env
}

@test "hermes-offline dry run changes nothing" {
    run "$SCRIPT"
    assert_success
    assert_output --partial "would   hermes config set model.provider custom"
    [[ ! -e "$HERMES_STATE/.sets" ]]
}

@test "hermes-offline --apply sets the four keys, then is idempotent" {
    run "$SCRIPT" --apply
    assert_success
    [[ "$(cat "$HERMES_STATE/model.provider")" == custom ]]
    [[ "$(cat "$HERMES_STATE/model.base_url")" == http://127.0.0.1:11434/v1 ]]
    [[ "$(cat "$HERMES_STATE/model.default")" == gpt-oss:20b ]]
    [[ "$(cat "$HERMES_STATE/model.ollama_num_ctx")" == 65536 ]]
    rm "$HERMES_STATE/.sets"
    run "$SCRIPT" --apply
    assert_output --partial "Everything already in place."
    [[ ! -e "$HERMES_STATE/.sets" ]]
}

@test "hermes-offline refuses a context below Hermes' 64K minimum" {
    HERMES_NUM_CTX=32768 run "$SCRIPT"
    assert_failure
    assert_output --partial "64K"
}

@test "hermes-offline pulls a missing model only with --pull" {
    HERMES_MODEL=qwen3:8b run "$SCRIPT" --apply
    assert_success
    assert_output --partial "ollama pull qwen3:8b"
    [[ ! -e "$HERMES_STATE/.pulls" ]]
    HERMES_MODEL=qwen3:8b run "$SCRIPT" --apply --pull
    grep -qx 'qwen3:8b' "$HERMES_STATE/.pulls"
}
