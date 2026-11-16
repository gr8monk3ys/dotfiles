#!/usr/bin/env bats
# Tests for bin/dotfiles-bench-shell: argument validation, the run loop and
# the budget verdict. zsh is replaced by a stub on PATH so the timings are
# controlled (a sleep) and the runs can be counted; the arithmetic, parsing
# and pass/fail decision are the script's own.

load test_helper/common

BENCH="$DOTFILES_DIR/bin/dotfiles-bench-shell"

setup() {
    setup_test_env
    STUB_BIN="$TEST_TEMP_DIR/stub-bin"
    export ZSH_CALLS="$TEST_TEMP_DIR/zsh-calls"
    mkdir -p "$STUB_BIN"
    # Records each invocation's arguments, optionally sleeps, exits with
    # STUB_ZSH_STATUS. Nothing else about zsh is needed by the benchmark.
    cat > "$STUB_BIN/zsh" << 'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$ZSH_CALLS"
if [[ -n "${STUB_ZSH_SLEEP:-}" ]]; then sleep "$STUB_ZSH_SLEEP"; fi
exit "${STUB_ZSH_STATUS:-0}"
EOF
    chmod +x "$STUB_BIN/zsh"
}

teardown() {
    cleanup_test_env
}

bench() {
    run env PATH="$STUB_BIN:$PATH" "$BENCH" "$@"
}

# ---------- the verdict ----------

@test "bench-shell: passes and reports every run when the average is within budget" {
    bench --runs 3 --budget-ms 100000
    assert_success
    assert_output --partial "Benchmarking zsh interactive startup (3 runs, budget 100000ms)"
    assert_output --partial "  run 1: "
    assert_output --partial "  run 3: "
    [[ "$output" != *"run 4:"* ]]
    assert_output --partial "PASS: average startup"
    assert_output --partial "within budget 100000ms"
}

@test "bench-shell: fails with exit 1 when the average exceeds the budget" {
    STUB_ZSH_SLEEP=0.05 bench --runs 2 --budget-ms 0
    assert_failure
    [[ "$status" -eq 1 ]]
    assert_output --partial "FAIL: average startup"
    assert_output --partial "exceeds budget 0ms"
    [[ "$output" != *"PASS:"* ]]
}

@test "bench-shell: runs zsh interactively once more than asked, for the warmup" {
    bench -r 4 -b 100000
    assert_success
    run cat "$ZSH_CALLS"
    assert_output "$(printf -- '-i -c exit\n%.0s' 1 2 3 4 5)"
}

@test "bench-shell: average is the integer mean, best and worst the extremes of the runs" {
    STUB_ZSH_SLEEP=0.02 bench --runs 4 --budget-ms 100000
    assert_success
    local line ms sum=0 n=0 best=999999 worst=0
    while IFS= read -r line; do
        [[ "$line" =~ ^\ \ run\ [0-9]+:\ ([0-9]+)ms$ ]] || continue
        ms="${BASH_REMATCH[1]}"
        sum=$((sum + ms)); n=$((n + 1))
        ((ms < best)) && best=$ms
        ((ms > worst)) && worst=$ms
    done <<< "$output"
    [[ "$n" -eq 4 ]]
    # A 20ms sleep cannot measure as 0ms; a 0 here means the parse broke.
    [[ "$best" -ge 1 ]]
    assert_output --partial "Average: $((sum / 4))ms (best: ${best}ms, worst: ${worst}ms)"
}

@test "bench-shell: a failing zsh warns on each measured run but not the warmup" {
    STUB_ZSH_STATUS=3 bench --runs 2 --budget-ms 100000
    assert_success
    [[ "$(grep -c 'Warning: zsh exited with status 3 during benchmark run' <<< "$output")" -eq 2 ]]
}

# ---------- argument validation: nothing is measured ----------

@test "bench-shell: --runs 0 is rejected" {
    bench --runs 0
    assert_failure
    assert_output --partial "Error: --runs must be >= 1"
    [[ ! -e "$ZSH_CALLS" ]]
}

@test "bench-shell: a non-integer --runs is rejected" {
    bench --runs three
    assert_failure
    assert_output --partial "Error: --runs must be an integer"
    [[ ! -e "$ZSH_CALLS" ]]
}

@test "bench-shell: a negative --budget-ms is rejected as not an integer" {
    bench --budget-ms -5
    assert_failure
    assert_output --partial "Error: --budget-ms must be an integer"
    [[ ! -e "$ZSH_CALLS" ]]
}

@test "bench-shell: a flag with no value is rejected by name" {
    bench --runs
    assert_failure
    assert_output --partial "Error: Missing value for --runs"

    bench -b
    assert_failure
    assert_output --partial "Error: Missing value for -b"
}

@test "bench-shell: an unknown option is rejected" {
    bench --fast
    assert_failure
    assert_output --partial "Error: Unknown option: --fast"
}

@test "bench-shell: fails cleanly when zsh is not on PATH" {
    mkdir -p "$TEST_TEMP_DIR/empty-bin"
    run env PATH="$TEST_TEMP_DIR/empty-bin" "$BASH" "$BENCH" --runs 1
    assert_failure
    assert_output --partial "Error: zsh is not installed"
}
