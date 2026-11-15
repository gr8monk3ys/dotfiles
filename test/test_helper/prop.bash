#!/usr/bin/env bash
# prop.bash - a seeded input generator for the property tests
# (test/test_prop_*.bats).
#
# A property test states an invariant ("manifest list never silently drops a
# line") and checks it against many generated inputs instead of a few picked
# by hand. Everything random comes from one generator seeded per test, so a
# failure is reproduced by re-running that test with the seed it printed:
#
#   PROP_SEED=<seed> bats test/test_prop_manifest.bats -f '<test name>'
#
# The generator is a 31-bit LCG in bash arithmetic rather than $RANDOM:
# $RANDOM's sequence for a given seed differs between bash 3.2 (macOS's
# /bin/bash) and 5.x, and a seed is only worth printing if it reproduces the
# same inputs on every machine.
#
# Interface:
#   prop_init              seed from PROP_SEED, else a fresh seed; record it
#   prop_rand <n>          REPLY = an integer in [0, n)
#   prop_pick <word>...    REPLY = one of the arguments
#   prop_string <chars> <min> <max>
#                          REPLY = <min>..<max> characters drawn from <chars>
#   prop_fail <message>    print the message, the seed and the reproduce
#                          line; returns 1 so `|| return` ends the test
#
# Environment:
#   PROP_CASES     inputs per property (default 40)
#   PROP_SEED      fixed seed (default: fresh per test)
#   PROP_SEED_LOG  if set, one line per property is appended to it:
#                  <file>\t<test>\t<seed>\t<cases>  (CI's step summary
#                  reads it; see bin/ci-summary)
#
# PROP_CASE is the index of the input being checked; a property loop sets it
# so prop_fail can name the case.

PROP_CASES="${PROP_CASES:-40}"
# What the caller asked for, before a test scales it: the reproduce line
# repeats it, since the inputs drawn depend on the seed and the case count.
_PROP_CASES_ARG="$PROP_CASES"

prop_init() {
    # bats traces every command through a DEBUG trap to report the failing
    # line. A property loop runs tens of thousands of commands, and the trap
    # made one file take 30s instead of 3. prop_fail names the failing case
    # itself, so the trace adds nothing here.
    # prop_fail puts the trap back so bats still points at the failing line.
    _PROP_DEBUG_TRAP="$(trap -p DEBUG)"
    trap - DEBUG
    set +o functrace
    if [[ -n "${PROP_SEED:-}" ]]; then
        _PROP_SEED="$PROP_SEED"
    else
        _PROP_SEED=$(((RANDOM << 15 | RANDOM) ^ $$))
    fi
    _PROP_STATE=$((_PROP_SEED & 0x7fffffff))
    PROP_CASE=0
    if [[ -n "${PROP_SEED_LOG:-}" ]]; then
        printf '%s\t%s\t%s\t%s\n' "$(basename "$BATS_TEST_FILENAME")" \
            "$BATS_TEST_DESCRIPTION" "$_PROP_SEED" "$PROP_CASES" >> "$PROP_SEED_LOG"
    fi
}

prop_rand() {
    _PROP_STATE=$(((_PROP_STATE * 1103515245 + 12345) & 0x7fffffff))
    # The low bits of a power-of-two LCG cycle quickly; use the high ones.
    REPLY=$(((_PROP_STATE >> 8) % $1))
}

prop_pick() {
    prop_rand $#
    shift "$REPLY"
    REPLY="$1"
}

prop_string() {
    local chars="$1" min="$2" max="$3" len out=""
    prop_rand $((max - min + 1))
    len=$((min + REPLY))
    while ((len-- > 0)); do
        prop_rand ${#chars}
        out+="${chars:REPLY:1}"
    done
    REPLY="$out"
}

prop_fail() {
    {
        printf 'property failed: %s\n' "$*"
        printf '  seed %s, case %s of %s\n' "$_PROP_SEED" "$PROP_CASE" "$PROP_CASES"
        printf '  reproduce: PROP_SEED=%s PROP_CASES=%s bats test/%s -f %q\n' \
            "$_PROP_SEED" "$_PROP_CASES_ARG" "$(basename "$BATS_TEST_FILENAME")" "$BATS_TEST_DESCRIPTION"
    } >&2
    set -o functrace
    eval "${_PROP_DEBUG_TRAP:-}"
    return 1
}
