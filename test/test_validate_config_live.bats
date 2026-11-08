#!/usr/bin/env bats
# Tests for bin/validate-config-live.
#
# The validator's whole value is that it fails when a config is NOT honoured,
# so these tests drive it against stub tools on a sealed PATH: each stub prints
# a known answer (or exits non-zero), and the assertions pin how the validator
# classifies it — ok, skip (tool absent) or fail — and what it exits with.
# Nothing here runs a real git/jj/atuin, so the result does not depend on what
# the machine running the suite has installed or configured.

load test_helper/common

setup() {
    setup_test_env
    export STUBS="$TEST_TEMP_DIR/stubs"
    mkdir -p "$STUBS"
    # The only real binaries on the sealed PATH: the interpreter the script and
    # its probes run under, and dirname for SCRIPT_DIR resolution.
    ln -s "$(command -v bash)" "$STUBS/bash"
    ln -s "$(command -v dirname)" "$STUBS/dirname"
}

teardown() {
    cleanup_test_env
}

# stub NAME EXIT_CODE OUTPUT — a fake tool that prints OUTPUT and exits.
stub() {
    printf '#!%s\nprintf "%%s\\n" %q\nexit %s\n' "$(command -v bash)" "$3" "$2" > "$STUBS/$1"
    chmod +x "$STUBS/$1"
}

# Run the validator with only the stubs on PATH and a scrubbed environment,
# so discovery variables from the caller's login shell cannot leak in.
run_validator() {
    run /usr/bin/env -i PATH="$STUBS" HOME="$TEST_HOME" DOTFILES_DIR="$DOTFILES_DIR" \
        "${EXTRA_ENV[@]}" "$DOTFILES_DIR/bin/validate-config-live" "$@"
}

@test "--list prints every probe name in table order" {
    EXTRA_ENV=()
    run_validator --list
    assert_success
    [[ "${#lines[@]}" -eq 15 ]]
    [[ "${lines[0]}" == "git" ]]
    [[ "${lines[1]}" == "jj" ]]
    [[ "${lines[14]}" == "nvim" ]]
    assert_output --partial "bat-theme"
    assert_output --partial "nvim-theme"
}

@test "a probe whose output contains the expected substring is ok" {
    stub git 0 "log --color --decorate --graph --all"
    EXTRA_ENV=()
    run_validator git
    assert_success
    [[ "${lines[0]}" == $'ok\tgit\tlog --color --decorate --graph' ]]
    assert_output --partial "1 config(s) demonstrably live, 0 skipped"
}

@test "an env-var probe is ok only when the variable points at the tracked config" {
    stub curl 0 ""
    EXTRA_ENV=(CURL_HOME="$TEST_HOME/.config/curl")
    run_validator curl
    assert_success
    [[ "${lines[0]}" == $'ok\tcurl\t/.config/curl' ]]
}

@test "an env-var probe fails when the discovery variable is unset" {
    stub curl 0 ""
    EXTRA_ENV=()
    run_validator curl
    assert_failure
    [[ "${lines[0]}" == fail$'\t'curl$'\t'"expected /.config/curl, got ''" ]]
    assert_output --partial "1 config(s) not honoured, 0 live, 0 skipped"
}

@test "a tool that is not installed is skipped, not failed" {
    # ghostty has no stub, and the sealed PATH has no real one.
    EXTRA_ENV=()
    run_validator ghostty
    assert_success
    [[ "${lines[0]}" == $'skip\tghostty\tghostty not installed' ]]
    assert_output --partial "0 config(s) demonstrably live, 1 skipped"
}

@test "a probe that exits non-zero fails and reports its output" {
    stub jj 1 "Config error: unknown key"
    EXTRA_ENV=()
    run_validator jj
    assert_failure
    [[ "${lines[0]}" == $'fail\tjj\tprobe exited non-zero: Config error: unknown key' ]]
}

@test "a probe whose output lacks the expected substring fails" {
    # The tool runs fine but on stock defaults — the exact failure mode the
    # validator exists to catch.
    stub atuin 0 "default"
    EXTRA_ENV=()
    run_validator atuin
    assert_failure
    [[ "${lines[0]}" == $'fail\tatuin\texpected danse, got default' ]]
}

@test "an unknown tool name fails with no such probe" {
    EXTRA_ENV=()
    run_validator not-a-tool
    assert_failure
    [[ "${lines[0]}" == $'fail\tnot-a-tool\tno such probe' ]]
}

@test "one failure fails the run but every tool is still reported and counted" {
    stub git 0 "log --color --decorate --graph"
    stub atuin 0 "default"
    EXTRA_ENV=()
    run_validator git atuin ghostty
    assert_failure
    [[ "${lines[0]}" == ok$'\t'git* ]]
    [[ "${lines[1]}" == fail$'\t'atuin* ]]
    [[ "${lines[2]}" == skip$'\t'ghostty* ]]
    assert_output --partial "1 config(s) not honoured, 1 live, 1 skipped"
}

@test "with no arguments every probe in the table is run" {
    # Nothing stubbed: every tool is absent, so all 15 skip and the run passes.
    EXTRA_ENV=()
    run_validator
    assert_success
    [[ "$(grep -c $'^skip\t' <<< "$output")" -eq 15 ]]
    assert_output --partial "0 config(s) demonstrably live, 15 skipped"
}
