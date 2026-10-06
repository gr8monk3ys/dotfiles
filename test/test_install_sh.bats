#!/usr/bin/env bats
# Tests for install.sh, the curl installer.
#
# `make verify` never runs install.sh itself (CI's Installer job does, after
# push), so these guard the ways it has broken before without executing it.

load test_helper/common

@test "install.sh does not re-implement the Makefile's OS dispatch" {
    # It may read the platform to report it, but must not branch to targets.
    # Comments are exempt: the deletion is explained in one.
    run bash -c 'grep -vE "^[[:space:]]*#" install.sh | grep -nE "make (macos|arch|link)\b"'
    assert_failure
}

# Regression: install.sh declared `readonly STRICT_PACKAGES=...` and then used
# it as an assignment prefix (`STRICT_PACKAGES="$STRICT_PACKAGES" make`). bash
# treats that as a fatal error on a readonly variable, so under `set -e` the
# curl installer exited 1 before running make at all. CI's Installer job
# caught it, but only after push: `make verify` never runs install.sh.
@test "no readonly variable is used as a command assignment prefix" {
    run bash -c '
        set -euo pipefail
        cd "$1"
        status=0
        for f in install.sh bin/*; do
            [[ -f "$f" && "$f" != *.md ]] || continue
            # Variables this file declares readonly...
            for v in $(grep -oE "^readonly [A-Z_]+=" "$f" | sed "s/^readonly //; s/=$//"); do
                # ...must not then appear as `VAR=... cmd`.
                if grep -qE "^[[:space:]]*$v=.*[[:space:]]+[a-z]" "$f" &&
                   ! grep -qE "^readonly $v=" <(grep -E "^[[:space:]]*$v=" "$f"); then
                    echo "$f: $v is readonly but reassigned as a command prefix"
                    status=1
                fi
            done
        done
        exit $status
    ' _ "$DOTFILES_DIR"
    assert_success
}

@test "install.sh exports STRICT_PACKAGES rather than re-assigning it" {
    run grep -n "^export STRICT_PACKAGES" install.sh
    assert_success
    run grep -nE '^[[:space:]]*STRICT_PACKAGES="\$STRICT_PACKAGES"[[:space:]]+make' install.sh
    assert_failure
}
