#!/usr/bin/env bats
# Tests for bin/ci-summary, the Markdown verification report CI writes to
# the step summary. The report is only worth reading if it is right, so the
# Makefile shape it depends on is pinned here too.

load test_helper/common

setup() {
    setup_test_env
    REPORT="$TEST_TEMP_DIR/report"
    mkdir -p "$REPORT"
    cat > "$REPORT/report.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<testsuites time="1.0">
<testsuite name="test_a.bats" tests="3" failures="1" errors="0" skipped="1" time="0.5" timestamp="x" hostname="h">
</testsuite>
<testsuite name="test_b.bats" tests="2" failures="0" errors="0" skipped="0" time="0.25" timestamp="x" hostname="h">
</testsuite>
</testsuites>
EOF
    printf 'ok 1 a\nnot ok 2 b\n# (in test file test/test_a.bats, line 9)\n' > "$REPORT/bats.tap"
    printf 'test_prop_x.bats\tprop: holds\t12345\t40\n' > "$REPORT/prop-seeds.tsv"
}

teardown() {
    cleanup_test_env
}

verify_targets() {
    sed -n 's/^verify:[[:space:]]*//p' "$DOTFILES_DIR/Makefile" | tr ' ' '\n' | sed '/^$/d'
}

# A log in which every verify target printed its header, as make would.
fake_log() {
    local t
    for t in $(verify_targets); do
        awk -v t="$t" '$0 ~ "^" t ":" { getline; sub(/^\t@echo "/, ""); sub(/"$/, ""); print; exit }' \
            "$DOTFILES_DIR/Makefile"
        echo "output of $t"
    done
}

@test "ci-summary: every verify target opens with an @echo header" {
    # ci-summary finds each validator's output by that header; a target
    # without one would be reported without its skip/pass detail.
    local t first status=0
    for t in $(verify_targets); do
        first="$(awk -v t="$t" '$0 ~ "^" t ":" { getline; print; exit }' "$DOTFILES_DIR/Makefile")"
        [[ "$first" == $'\t@echo "'* ]] || { echo "$t: first recipe line is not an @echo header: $first"; status=1; }
    done
    return "$status"
}

@test "ci-summary: a passing run lists every verify target as passed" {
    fake_log > "$TEST_TEMP_DIR/verify.log"
    run bin/ci-summary --log "$TEST_TEMP_DIR/verify.log" --report "$REPORT" --outcome success
    assert_success
    local t
    for t in $(verify_targets); do
        [[ "$output" == *"| \`$t\` | passed |"* ]] || { echo "missing $t"; echo "$output"; return 1; }
    done
}

@test "ci-summary: the failed target is named and later ones are not run" {
    {
        fake_log | sed '/^Validating markdown links/q'
        echo "make: *** [Makefile:228: verify-doc-links] Error 1"
    } > "$TEST_TEMP_DIR/verify.log"
    run bin/ci-summary --log "$TEST_TEMP_DIR/verify.log" --report "$REPORT"
    assert_success
    assert_output --partial "| \`verify-doc-links\` | **FAILED** |"
    assert_output --partial "| \`verify-tests\` | not run |"
    assert_output --partial "| \`verify-shell\` | passed |"
    assert_output --partial "make verify\`: failure"
}

@test "ci-summary: reads make 3.81's failure line too" {
    {
        fake_log | sed '/^Validating markdown links/q'
        echo "make: *** [verify-doc-links] Error 1"
    } > "$TEST_TEMP_DIR/verify.log"
    run bin/ci-summary --log "$TEST_TEMP_DIR/verify.log"
    assert_output --partial "| \`verify-doc-links\` | **FAILED** |"
}

@test "ci-summary: a nested make failure is not mistaken for the top-level one" {
    {
        fake_log
        echo "make[1]: *** [Makefile:151: test] Error 1"
        echo "make: *** [Makefile:280: verify-tests] Error 2"
    } > "$TEST_TEMP_DIR/verify.log"
    run bin/ci-summary --log "$TEST_TEMP_DIR/verify.log"
    assert_output --partial "| \`verify-tests\` | **FAILED** |"
}

@test "ci-summary: a skipped validator is reported as skipped, not passed" {
    fake_log | sed 's/^output of verify-docker$/Skipping container tests (SKIP_DOCKER set)/' \
        > "$TEST_TEMP_DIR/verify.log"
    run bin/ci-summary --log "$TEST_TEMP_DIR/verify.log" --outcome success
    assert_output --partial "| \`verify-docker\` | skipped: Skipping container tests (SKIP_DOCKER set) |"
}

@test "ci-summary: per-file test counts, totals, failures and seeds come from the report" {
    fake_log > "$TEST_TEMP_DIR/verify.log"
    run bin/ci-summary --log "$TEST_TEMP_DIR/verify.log" --report "$REPORT" --title "Tests (ubuntu)"
    assert_success
    assert_output --partial "## Tests (ubuntu)"
    assert_output --partial "**5 tests: 3 passed, 1 failed, 1 skipped.**"
    assert_output --partial "| \`test_a.bats\` | 3 | 1 | 1 | 1 | 0.5s |"
    assert_output --partial "| \`test_b.bats\` | 2 | 2 | 0 | 0 | 0.25s |"
    assert_output --partial "not ok 2 b"
    assert_output --partial "| \`test_prop_x.bats\` | prop: holds | \`12345\` | 40 |"
}

@test "ci-summary: a missing log or report is said, not an error" {
    run bin/ci-summary --log "$TEST_TEMP_DIR/nope.log" --outcome skipped
    assert_success
    assert_output --partial "verify did not run (outcome: skipped)"
    fake_log > "$TEST_TEMP_DIR/verify.log"
    run bin/ci-summary --log "$TEST_TEMP_DIR/verify.log" --report "$TEST_TEMP_DIR/none"
    assert_success
    assert_output --partial "the suite did not run"
}

@test "ci-summary: --log is required" {
    run bin/ci-summary
    assert_failure
    assert_output --partial "--log is required"
}
