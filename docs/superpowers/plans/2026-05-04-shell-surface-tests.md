# Shell-Surface Tests Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add automated CI guards for the largest currently-untested behavioral surface (shell aliases and functions) so that syntax errors, source-time errors, typo'd guards, and reference drift in `aliases.zsh` / `functions.zsh` / `.zshenv` fail the build.

**Architecture:** Two thin layers — (1) a BATS test file `test/test_shell_surface.bats` that runs `zsh -n` and `zsh -c 'source …'` against each shell file, plus a sentinel-aliases test that uses a `command -v` shadow to detect typo'd guards; (2) a helper script `bin/check-alias-references` (mirroring the existing `bin/validate-doc-links` pattern) that walks every unconditional alias in `aliases.zsh` and verifies the first word of each body resolves to a shell builtin, an entry in an install manifest, or `test/allowlist/system-tools.txt`. Both layers wire into `make verify` via a new `verify-shell-surface` target.

**Tech Stack:** zsh, bash, BATS, Makefile, awk/sed/grep (no new dependencies).

**Spec:** [`docs/superpowers/specs/2026-04-27-shell-surface-tests-design.md`](../specs/2026-04-27-shell-surface-tests-design.md).

---

## File Structure

| Path | New / Modify | Responsibility |
|---|---|---|
| `Makefile` | modify | Add `functions.zsh` to `verify-shell`, add `verify-shell-surface` target, hook into `verify` chain |
| `test/test_shell_surface.bats` | new | B-leaf parse + source tests, sentinel test, integration with the C checker |
| `test/test_alias_checker.bats` | new | Fixture-based unit tests for `bin/check-alias-references` itself |
| `test/fixtures/aliases-fixture-good.zsh` | new | Synthetic minimal valid aliases (resolves cleanly) |
| `test/fixtures/aliases-fixture-bad.zsh` | new | Synthetic alias with unresolved reference |
| `test/fixtures/aliases-fixture-typo-guard.zsh` | new | Synthetic file with typo'd `command -v` guard |
| `test/allowlist/system-tools.txt` | new | Curated list of base-OS commands not in any install manifest |
| `bin/check-alias-references` | new | Bash script implementing the C-layer reference checker |
| `bin/README.md` | modify | Document the new helper |
| `AGENTS.md` | modify | One-line note in Testing Guidelines |
| `OPERATING.md` | modify | Troubleshooting entry for `verify-shell-surface` failures |

Files are split by responsibility: B-leaf and integration tests live in `test_shell_surface.bats`; checker-correctness tests live in `test_alias_checker.bats` (separate because they test the checker itself, not the repo state). The checker logic lives in a script (not in BATS) for reusability outside CI and better failure messages, mirroring `bin/validate-doc-links`.

---

## Pre-flight check

- [ ] **Verify branch and clean tree**

```bash
git status
git branch --show-current
```

Expected: on branch `docs/shell-surface-tests-spec` with a clean working tree. The spec already lives at `docs/superpowers/specs/2026-04-27-shell-surface-tests-design.md`.

- [ ] **Verify zsh and BATS are available**

```bash
zsh --version
make test-setup
```

Expected: zsh prints a version; `make test-setup` exits 0 (installs `bats-support`/`bats-assert` if missing).

---

## Task 1: Extend `verify-shell` to cover `functions.zsh`

**Why first:** Tiny single-line change with immediate value, no test infrastructure needed, doesn't depend on anything else. Gets the obvious gap closed before adding the larger BATS layer.

**Files:**
- Modify: `Makefile` (the `verify-shell` target)

- [ ] **Step 1: Read the current `verify-shell` target**

```bash
sed -n '209,222p' Makefile
```

Expected output (current state):

```makefile
verify-shell:
	@echo "Running shell syntax checks..."
	@if command -v zsh >/dev/null 2>&1; then \
		zsh -n .zshenv .config/zsh/.zshrc .config/zsh/aliases.zsh; \
	else \
		echo "⚠️  zsh not found; skipping zsh syntax checks"; \
	fi
	@for script in bin/*; do \
		if [ -f "$$script" ] && head -n1 "$$script" | grep -q "bash"; then \
			bash -n "$$script"; \
		fi; \
	done
```

- [ ] **Step 2: Add `functions.zsh` to the zsh syntax check list**

Edit `Makefile`, find the `zsh -n` line, and add `.config/zsh/functions.zsh`:

```makefile
		zsh -n .zshenv .config/zsh/.zshrc .config/zsh/aliases.zsh .config/zsh/functions.zsh; \
```

- [ ] **Step 3: Run `make verify-shell` and confirm it still passes**

```bash
make verify-shell
```

Expected: exits 0, no errors. The `functions.zsh` file (25 lines) is currently valid zsh, so this should pass.

- [ ] **Step 4: Commit**

```bash
git add Makefile
git commit -m "$(cat <<'EOF'
test(shell): include functions.zsh in verify-shell parse check

verify-shell already runs zsh -n on .zshenv, .zshrc, aliases.zsh —
functions.zsh was the only zsh source file not covered.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Create `test/test_shell_surface.bats` with parse + source tests

**Why next:** Establishes the test file as the single home for shell-surface validation. Six tests, all should pass against current state (this is characterization — locking in the current good state).

**Files:**
- Create: `test/test_shell_surface.bats`

- [ ] **Step 1: Create the test file with parse and source tests**

Write the full file:

```bash
#!/usr/bin/env bats
# Shell-surface validation tests.
#
# Layer B-leaf: every shell file the user authors (i.e. not third-party
# plugins) must parse and source cleanly in isolation. Sourcing in a
# clean subshell catches errors that fire at definition time —
# typo'd guard expressions, malformed function declarations,
# bad parameter expansions.

load test_helper/common

setup() {
    setup_test_env
}

teardown() {
    cleanup_test_env
}

# --- Parse checks (zsh -n) -------------------------------------------------

@test "shell-surface: .zshenv parses as valid zsh" {
    run zsh -n "$DOTFILES_DIR/.zshenv"
    assert_success
}

@test "shell-surface: aliases.zsh parses as valid zsh" {
    run zsh -n "$DOTFILES_DIR/.config/zsh/aliases.zsh"
    assert_success
}

@test "shell-surface: functions.zsh parses as valid zsh" {
    run zsh -n "$DOTFILES_DIR/.config/zsh/functions.zsh"
    assert_success
}

# --- Source checks ---------------------------------------------------------
# Source each file in a clean subshell with HOME pointed at a temp dir.
# Any error written to stderr at source time is a failure.

@test "shell-surface: .zshenv sources cleanly in a clean subshell" {
    run zsh -c "HOME='$TEST_HOME' source '$DOTFILES_DIR/.zshenv'"
    assert_success
    [[ -z "$output" ]] || {
        echo "Expected no stderr output, got:"
        echo "$output"
        return 1
    }
}

@test "shell-surface: aliases.zsh sources cleanly in a clean subshell" {
    run zsh -c "HOME='$TEST_HOME' source '$DOTFILES_DIR/.config/zsh/aliases.zsh'"
    assert_success
    [[ -z "$output" ]] || {
        echo "Expected no stderr output, got:"
        echo "$output"
        return 1
    }
}

@test "shell-surface: functions.zsh sources cleanly in a clean subshell" {
    run zsh -c "HOME='$TEST_HOME' source '$DOTFILES_DIR/.config/zsh/functions.zsh'"
    assert_success
    [[ -z "$output" ]] || {
        echo "Expected no stderr output, got:"
        echo "$output"
        return 1
    }
}
```

- [ ] **Step 2: Run the new tests and confirm they pass**

```bash
bats test/test_shell_surface.bats
```

Expected:
```
 ✓ shell-surface: .zshenv parses as valid zsh
 ✓ shell-surface: aliases.zsh parses as valid zsh
 ✓ shell-surface: functions.zsh parses as valid zsh
 ✓ shell-surface: .zshenv sources cleanly in a clean subshell
 ✓ shell-surface: aliases.zsh sources cleanly in a clean subshell
 ✓ shell-surface: functions.zsh sources cleanly in a clean subshell

6 tests, 0 failures
```

If any test fails, do not proceed — fix the underlying file or adjust the assertion (the goal is to lock in the *current good state*).

- [ ] **Step 3: Commit**

```bash
git add test/test_shell_surface.bats
git commit -m "$(cat <<'EOF'
test(shell): add B-leaf parse and source checks for shell files

Adds test/test_shell_surface.bats covering:
- zsh -n parse-checks for .zshenv, aliases.zsh, functions.zsh
- zsh -c source-checks for the same files in clean subshells

Sourcing catches errors that fire at definition time (typo'd guards,
bad function syntax) which the parse-only check at verify-shell
cannot catch.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Add sentinel test to catch typo'd `command -v` guards

**Why next:** The sourcing test from Task 2 catches errors that fire at source time. But a typo'd guard like `commnd -v eza` evaluates to false silently — no error, but the entire conditional block is skipped. This test shadows `command -v` to always return true and asserts that representative aliases from each conditional block actually get defined.

**Files:**
- Modify: `test/test_shell_surface.bats` (append a new test)

- [ ] **Step 1: Identify the conditional blocks in `aliases.zsh`**

```bash
grep -nE '^if command -v' .config/zsh/aliases.zsh
```

The sentinel list below was derived from this grep at design time. If the output above shows new or removed blocks, update the sentinel list to match (one alias per block).

- [ ] **Step 2: Append the sentinel test to `test/test_shell_surface.bats`**

Add at the end of the file:

```bash
# --- Sentinel: detect typo'd `command -v` guards ---------------------------
# A typo in a guard ("commnd -v eza") evaluates to false silently — no error
# fires, but the entire conditional block is skipped. We catch this by
# shadowing `command` to always succeed for `-v` queries, then sourcing
# aliases.zsh and asserting each conditional block actually defined its
# representative alias.

@test "shell-surface: every conditional block in aliases.zsh defines its sentinel" {
    # Each entry: representative alias name from one conditional block.
    # When updating aliases.zsh, add/remove an entry here for each
    # `if command -v X &> /dev/null` block.
    local sentinels=(
        # unconditional region (always defined)
        g           # alias g="git"
        # conditional blocks (defined only if guard succeeds)
        ls          # eza block
        catp        # bat block
        rgi         # rg block
        dus         # dust block
        psa         # procs block
        htop        # btm block
        zi          # zoxide block
        hs          # atuin block
        mi          # mise block
        bench       # hyperfine block
        loc         # tokei block
        fm          # yazi block
        j           # jj block
        zj          # zellij block
        cheat       # navi block
        br          # broot block
        tldru       # tldr block
        df          # duf block
        compress    # ouch block
        lg          # lazygit block
        lzd         # lazydocker block
        jqi         # jnv block
        md          # glow block
        csv         # csvlens block
        bw          # bandwhich block
        watch       # viddy block
        mtr         # trip block
        gdd         # difft block
        tg          # topgrade block
        nrs         # darwin-rebuild block
        nhs         # home-manager block
    )

    # Build a zsh script that:
    #   1. Shadows `command` so `command -v X` always returns success.
    #   2. Sources aliases.zsh.
    #   3. Prints any sentinel that is NOT defined as an alias.
    local check_script
    check_script=$(cat <<'ZSH'
command() {
    if [[ "$1" == "-v" ]]; then return 0; fi
    builtin command "$@"
}
source "$ALIASES_FILE"
missing=()
for name in "$@"; do
    if ! alias -L "$name" >/dev/null 2>&1; then
        missing+=("$name")
    fi
done
if (( ${#missing} > 0 )); then
    echo "Missing aliases (likely typo'd guard):"
    printf '  %s\n' "${missing[@]}"
    exit 1
fi
ZSH
)

    run env ALIASES_FILE="$DOTFILES_DIR/.config/zsh/aliases.zsh" \
        zsh -c "$check_script" -- "${sentinels[@]}"
    assert_success
}
```

- [ ] **Step 3: Run the sentinel test and confirm it passes**

```bash
bats test/test_shell_surface.bats -f "sentinel"
```

Expected: 1 test, 0 failures. If the sentinel test fails because a sentinel name doesn't exist in `aliases.zsh`, fix the *sentinel list* (the test was designed assuming aliases.zsh as it stood when this plan was written; if aliases have moved/renamed, update the sentinel list, not aliases.zsh).

- [ ] **Step 4: Sanity-check that the test actually catches a typo'd guard**

Manually break one guard in `aliases.zsh` (don't commit this — just test):

```bash
sed -i.bak 's/if command -v eza/if commnd -v eza/' .config/zsh/aliases.zsh
bats test/test_shell_surface.bats -f "sentinel"
```

Expected: the sentinel test now FAILS with `Missing aliases (likely typo'd guard): ls`.

Restore:

```bash
mv .config/zsh/aliases.zsh.bak .config/zsh/aliases.zsh
bats test/test_shell_surface.bats -f "sentinel"
```

Expected: passes again.

- [ ] **Step 5: Commit**

```bash
git add test/test_shell_surface.bats
git commit -m "$(cat <<'EOF'
test(shell): add sentinel test for typo'd command -v guards

A typo'd guard ('commnd -v eza') silently evaluates false and
skips its entire alias block — sourcing aliases.zsh produces no
error, so source-checks alone cannot catch this. The sentinel test
shadows `command` to always succeed for `-v` queries, then asserts
one representative alias from each conditional block was actually
defined after sourcing.

Manually verified: introducing a typo in any guard makes this test
fail with the expected missing-alias message.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Build `bin/check-alias-references` (the C-layer checker) with fixture-based TDD

**Why next:** The C-layer is the largest piece. We TDD it: write fixture-based tests that drive the script's behavior, watch them fail (no script), then implement the script.

**Files:**
- Create: `test/fixtures/aliases-fixture-good.zsh`
- Create: `test/fixtures/aliases-fixture-bad.zsh`
- Create: `test/test_alias_checker.bats`
- Create: `bin/check-alias-references`

- [ ] **Step 1: Create the "good" fixture**

`test/fixtures/aliases-fixture-good.zsh`:

```zsh
# Minimal fixture used by test_alias_checker.bats: every alias here MUST
# resolve cleanly against builtins, the test allowlist, and the install
# manifests in install/. This fixture is the positive case.

alias gg="git status"
alias e="echo hello"

if command -v eza &> /dev/null; then
    alias ll="eza -la"
fi
```

- [ ] **Step 2: Create the "bad" fixture**

`test/fixtures/aliases-fixture-bad.zsh`:

```zsh
# Negative fixture: contains an unresolved reference outside any guard.
# `definitely-not-a-real-tool` is not in any manifest, builtin list,
# or allowlist — the checker MUST flag this.

alias bad="definitely-not-a-real-tool --frob"
```

- [ ] **Step 3: Create the BATS test for the checker**

`test/test_alias_checker.bats`:

```bash
#!/usr/bin/env bats
# Unit tests for bin/check-alias-references using synthetic fixtures.
#
# These tests verify the checker correctly distinguishes resolvable
# from unresolvable aliases. They are independent of the real
# .config/zsh/aliases.zsh — that file is exercised by an integration
# test in test_shell_surface.bats once the allowlist is built.

load test_helper/common

setup() {
    setup_test_env
}

teardown() {
    cleanup_test_env
}

@test "alias-checker: passes against the good fixture" {
    run env ALIASES_FILE="$DOTFILES_DIR/test/fixtures/aliases-fixture-good.zsh" \
        bash "$DOTFILES_DIR/bin/check-alias-references"
    assert_success
}

@test "alias-checker: fails against the bad fixture and names the offender" {
    run env ALIASES_FILE="$DOTFILES_DIR/test/fixtures/aliases-fixture-bad.zsh" \
        bash "$DOTFILES_DIR/bin/check-alias-references"
    assert_failure
    assert_output --partial "definitely-not-a-real-tool"
    assert_output --partial "alias 'bad'"
}

@test "alias-checker: prints a usable fix-it message on failure" {
    run env ALIASES_FILE="$DOTFILES_DIR/test/fixtures/aliases-fixture-bad.zsh" \
        bash "$DOTFILES_DIR/bin/check-alias-references"
    assert_failure
    assert_output --partial "Fix one of"
    assert_output --partial "install/Brewfile"
    assert_output --partial "test/allowlist/system-tools.txt"
}
```

- [ ] **Step 4: Run the BATS tests — they should ALL fail (script doesn't exist yet)**

```bash
bats test/test_alias_checker.bats
```

Expected:
```
 ✗ alias-checker: passes against the good fixture
 ✗ alias-checker: fails against the bad fixture and names the offender
 ✗ alias-checker: prints a usable fix-it message on failure
```

Each failure should mention "No such file or directory" or similar — the checker doesn't exist yet. This is the TDD red state.

- [ ] **Step 5: Create `bin/check-alias-references` with full implementation**

Write `bin/check-alias-references`:

```bash
#!/usr/bin/env bash
# bin/check-alias-references
#
# Validate that every unconditional alias in .config/zsh/aliases.zsh
# resolves to a known source: a shell builtin, an entry in an install
# manifest (Brewfile/Caskfile/Rustfile/npmfile), an alias defined
# elsewhere in the file, or an entry in test/allowlist/system-tools.txt.
#
# Conditional blocks (`if command -v X &> /dev/null; then ...; fi`) are
# exempt — the guard itself declares the dependency.
#
# Override the input file by setting ALIASES_FILE; defaults to
# $DOTFILES_DIR/.config/zsh/aliases.zsh.
#
# Exit code: 0 if all aliases resolve, 1 if any violation is found.

set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
ALIASES_FILE="${ALIASES_FILE:-$DOTFILES_DIR/.config/zsh/aliases.zsh}"
ALLOWLIST_FILE="$DOTFILES_DIR/test/allowlist/system-tools.txt"
INSTALL_DIR="$DOTFILES_DIR/install"

# Hardcoded list of POSIX/zsh shell builtins.
BUILTINS=(
    cd echo exec type command builtin eval exit export return set source .
    test alias unalias history jobs fg bg pwd read shift trap umask wait
    true false printf time times kill ulimit
)

is_builtin() {
    local cmd="$1"
    local b
    for b in "${BUILTINS[@]}"; do
        [[ "$b" == "$cmd" ]] && return 0
    done
    return 1
}

is_in_allowlist() {
    local cmd="$1"
    [[ -f "$ALLOWLIST_FILE" ]] || return 1
    awk '
        /^[[:space:]]*#/ { next }
        /^[[:space:]]*$/ { next }
        { print $1 }
    ' "$ALLOWLIST_FILE" | grep -Fxq "$cmd"
}

is_in_manifest_quoted() {
    # Matches Brewfile/Caskfile lines like: brew "name" or cask 'name'
    local file="$1"
    local keyword="$2"
    local cmd="$3"
    [[ -f "$file" ]] || return 1
    sed -nE 's/^[[:space:]]*'"$keyword"'[[:space:]]+["'"'"']([^"'"'"']+)["'"'"'].*/\1/p' "$file" \
        | grep -Fxq "$cmd"
}

is_in_manifest_bare() {
    # Matches Rustfile/npmfile bare-name lines, ignoring comments and blanks.
    local file="$1"
    local cmd="$2"
    [[ -f "$file" ]] || return 1
    awk '
        /^[[:space:]]*#/ { next }
        /^[[:space:]]*$/ { next }
        { print $1 }
    ' "$file" | grep -Fxq "$cmd"
}

is_alias_in_file() {
    # Matches `alias NAME=` anywhere in aliases.zsh.
    local cmd="$1"
    grep -E "^[[:space:]]*alias[[:space:]]+${cmd}=" "$ALIASES_FILE" >/dev/null 2>&1
}

resolve() {
    local cmd="$1"
    is_builtin "$cmd" && return 0
    is_in_allowlist "$cmd" && return 0
    is_in_manifest_quoted "$INSTALL_DIR/Brewfile" "brew" "$cmd" && return 0
    is_in_manifest_quoted "$INSTALL_DIR/Caskfile" "cask" "$cmd" && return 0
    is_in_manifest_bare "$INSTALL_DIR/Rustfile" "$cmd" && return 0
    is_in_manifest_bare "$INSTALL_DIR/npmfile" "$cmd" && return 0
    is_alias_in_file "$cmd" && return 0
    return 1
}

# Walk aliases.zsh: track conditional-block depth, emit (line_num, full_line)
# for every alias defined at depth 0.
extract_unconditional_aliases() {
    awk '
        BEGIN { depth = 0 }
        /^[[:space:]]*if[[:space:]]/  { depth++; next }
        /^[[:space:]]*fi[[:space:]]*$/ { if (depth > 0) depth--; next }
        /^[[:space:]]*alias[[:space:]]+[^=]+=/ {
            if (depth == 0) printf "%d\t%s\n", NR, $0
            next
        }
        # Fallback pattern: command -v X > /dev/null || alias Y=...
        # The fallback BODY is what runs when X is missing, so it must resolve.
        /command -v .* \|\| alias[[:space:]]+[^=]+=/ {
            if (depth == 0) printf "%d\t%s\n", NR, $0
            next
        }
    ' "$ALIASES_FILE"
}

# Extract the alias name and the first word of the body from a raw line.
# Echoes "<name>\t<first_word>" or nothing if the line should be skipped.
parse_alias_line() {
    local line="$1"

    # Fallback form: `command -v X > /dev/null || alias Y=BODY`
    if [[ "$line" =~ command[[:space:]]+-v.*\|\|[[:space:]]+alias[[:space:]]+([^=]+)=(.*)$ ]]; then
        local name="${BASH_REMATCH[1]}"
        local body="${BASH_REMATCH[2]}"
        emit_first_word "$name" "$body"
        return
    fi

    # Standard form: `alias NAME=BODY`
    if [[ "$line" =~ ^[[:space:]]*alias[[:space:]]+([^=]+)=(.*)$ ]]; then
        local name="${BASH_REMATCH[1]}"
        local body="${BASH_REMATCH[2]}"
        emit_first_word "$name" "$body"
    fi
}

emit_first_word() {
    local name="$1"
    local body="$2"

    # Strip surrounding single or double quotes from the body.
    body="${body#\'}"; body="${body%\'}"
    body="${body#\"}"; body="${body%\"}"

    # First whitespace-separated token.
    local first="${body%%[[:space:]]*}"

    # Unwrap wrappers.
    case "$first" in
        sudo|command|nohup|exec)
            local rest="${body#"$first"}"
            rest="${rest#"${rest%%[![:space:]]*}"}"   # ltrim
            first="${rest%%[[:space:]]*}"
            ;;
    esac

    # Skip empty, absolute paths, and variable expansions.
    case "$first" in
        '' | /* | \$* | '${'* ) return ;;
    esac

    printf '%s\t%s\n' "$name" "$first"
}

# Main loop: process every unconditional alias, collect violations.
violations=0
violation_log="$(mktemp)"
trap 'rm -f "$violation_log"' EXIT

while IFS=$'\t' read -r line_num line; do
    [[ -z "$line_num" ]] && continue
    parsed="$(parse_alias_line "$line" || true)"
    [[ -z "$parsed" ]] && continue
    alias_name="${parsed%%$'\t'*}"
    first_word="${parsed##*$'\t'}"

    if ! resolve "$first_word"; then
        {
            echo "  $ALIASES_FILE:$line_num"
            echo "    alias '$alias_name' references '$first_word'"
            echo "    '$first_word' is not in:"
            echo "      - shell builtins"
            echo "      - test/allowlist/system-tools.txt"
            echo "      - install/Brewfile, install/Caskfile, install/Rustfile, install/npmfile"
            echo ""
        } >> "$violation_log"
        violations=$((violations + 1))
    fi
done < <(extract_unconditional_aliases)

if (( violations > 0 )); then
    echo "check-alias-references: $violations violation(s) found"
    echo ""
    cat "$violation_log"
    cat <<'FIX'
Fix one of:
  1. Add the command to install/Brewfile (or appropriate manifest)
  2. Wrap the alias with a guard:
       if command -v CMD &> /dev/null; then
           alias NAME='CMD ...'
       fi
  3. If CMD is a base system tool that should not be manifested
     (e.g., 'osascript', 'pbcopy'), add it to
     test/allowlist/system-tools.txt with a one-line comment.

Run 'bin/check-alias-references' locally to iterate.
FIX
    exit 1
fi

echo "check-alias-references: all aliases resolve"
exit 0
```

- [ ] **Step 6: Make it executable**

```bash
chmod +x bin/check-alias-references
```

- [ ] **Step 7: Run the BATS tests — they should now pass**

```bash
bats test/test_alias_checker.bats
```

Expected:
```
 ✓ alias-checker: passes against the good fixture
 ✓ alias-checker: fails against the bad fixture and names the offender
 ✓ alias-checker: prints a usable fix-it message on failure

3 tests, 0 failures
```

- [ ] **Step 8: Commit**

```bash
git add bin/check-alias-references test/test_alias_checker.bats \
        test/fixtures/aliases-fixture-good.zsh \
        test/fixtures/aliases-fixture-bad.zsh
git commit -m "$(cat <<'EOF'
feat(test): add bin/check-alias-references with fixture tests

bin/check-alias-references walks unconditional aliases in
.config/zsh/aliases.zsh and verifies each first-word reference
resolves to:
  - a shell builtin
  - an entry in install/Brewfile, Caskfile, Rustfile, or npmfile
  - an alias defined elsewhere in the file
  - an entry in test/allowlist/system-tools.txt

Conditional blocks (`if command -v X`) are exempt; the guard is the
dependency declaration. The fallback pattern (`command -v X || alias Y=...`)
checks the fallback body, not the alias name X.

test/test_alias_checker.bats verifies the checker via good/bad
fixtures rather than the real aliases.zsh — that integration test
arrives once the system-tools allowlist is built.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Build `test/allowlist/system-tools.txt` from real violations

**Why next:** The checker now exists and is tested in isolation, but running it against the real `aliases.zsh` will produce many violations because the allowlist doesn't exist yet. This task builds the allowlist by iterating with the checker against reality.

**Files:**
- Create: `test/allowlist/system-tools.txt`

- [ ] **Step 1: Run the checker against the real `aliases.zsh` and capture violations**

```bash
bin/check-alias-references > /tmp/alias-check.out 2>&1 || true
cat /tmp/alias-check.out
```

Expected: many "alias 'X' references 'Y'" lines for system tools like `osascript`, `pbcopy`, `defaults`, `ifconfig`, etc., that are present on macOS but not in any install manifest.

- [ ] **Step 2: Extract the unique offending command names**

```bash
grep -oE "references '[^']+'" /tmp/alias-check.out | sort -u
```

This gives a deduplicated list of every external command flagged by the checker.

- [ ] **Step 3: Triage each command into one of three buckets**

For each command in the list:

| Bucket | What to do |
|---|---|
| Base-OS / always-present (e.g., `osascript`, `pbcopy`, `dig`, `ifconfig`, `find`, `grep`, `sed`, `awk`, `python3`, `xargs`) | Add to `test/allowlist/system-tools.txt` |
| Should-be-manifested but missing (e.g., a CLI tool that's actually installed via brew but you forgot to commit the Brewfile entry) | Add to `install/Brewfile` (or correct manifest), commit separately |
| Should-be-guarded but currently unconditional (e.g., a tool that may not be present on every machine) | Add a `command -v` guard around the alias in `.config/zsh/aliases.zsh`, commit separately |

If you find any bucket-2 or bucket-3 issues, **stop and address them in a separate commit before continuing this task.** This task is *only* for adding base-OS tools to the allowlist; manifest corrections and missing guards are bug fixes that deserve their own commits.

- [ ] **Step 4: Create `test/allowlist/system-tools.txt`**

Create the file with structure like this. The exact entries depend on Step 3's triage; below is the expected shape, with comments justifying each entry:

```
# test/allowlist/system-tools.txt
#
# Commands assumed always-present on supported platforms (macOS or
# CI-tested Linux). Entries here are NOT tracked by any install manifest
# because they ship with the base OS or with Xcode Command Line Tools.
#
# Format: one command per line. '#' starts a comment (line or inline).
# Each entry should have a one-line justification.
#
# When adding an entry, prefer guarding the alias with
# `if command -v X &> /dev/null` if X might not be present on every
# supported platform.

# --- POSIX / Unix coreutils (macOS + Linux) ---
ls               # listing files
cp               # copying
mv               # moving
rm               # removing
cat              # concatenating
find             # filesystem traversal
grep             # text search
sed              # stream editor
awk              # field processing
tr               # character translation
cut              # field extraction
sort             # sorting
uniq             # deduplication
wc               # word count
head             # leading lines
tail             # trailing lines
xargs            # argument stream piping
ps               # process listing
kill             # signal sending
date             # current time
echo             # text output
printf           # formatted output

# --- Network / system inspection (macOS coreutils + BSD utilities) ---
dig              # DNS lookup, present on macOS by default
ifconfig         # network interface listing (macOS still ships it)
ipconfig         # macOS-only DHCP / interface helper
hostname         # current hostname
ssh              # OpenSSH client
scp              # OpenSSH copy
curl             # HTTP client (ships with macOS)

# --- macOS-only system tools (base OS, not Homebrew) ---
osascript        # AppleScript runner
defaults         # macOS preferences
pbcopy           # clipboard write
pbpaste          # clipboard read
pmset            # power management
mdutil           # Spotlight control
dscacheutil      # DNS cache control
killall          # signal-by-name
sqlite3          # ships with macOS
networksetup    # network preferences CLI
diskutil         # disk admin
sw_vers          # macOS version info
xcrun            # Xcode tooling wrapper
softwareupdate   # macOS software updates

# --- Common interpreters present on base macOS ---
python3          # /usr/bin/python3 ships with Xcode CLT
ruby             # /usr/bin/ruby ships with macOS
perl             # /usr/bin/perl ships with macOS

# --- Misc ---
gs               # ghostscript — bundled with mactex / Adobe; treat as system
pcregrep         # PCRE grep — base macOS in older versions; treat as system
```

The list above is illustrative — the *actual* entries are determined by Step 3 against the real `aliases.zsh`. Add only what's needed; don't pre-emptively add tools that aren't referenced.

- [ ] **Step 5: Re-run the checker until it exits 0**

```bash
bin/check-alias-references
echo "exit: $?"
```

Expected: `check-alias-references: all aliases resolve` and exit 0.

If still failing, return to Step 3 and triage the remaining commands. Each command must end up in exactly one of: allowlist, install manifest (separate commit), or behind a guard (separate commit).

- [ ] **Step 6: Commit (allowlist only)**

```bash
git add test/allowlist/system-tools.txt
git commit -m "$(cat <<'EOF'
test(shell): add allowlist of base-OS commands for alias checker

bin/check-alias-references would otherwise flag every alias that uses
osascript, pbcopy, defaults, etc. — base-OS commands that are not
managed by any install manifest. The allowlist documents which
commands are exempt and why.

Adding to the allowlist is a deliberate choice: prefer guarding with
`command -v` if the command might not be present on every supported
platform.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

If you committed manifest corrections or guard additions during Step 3, they're already in earlier separate commits. Verify with `git log --oneline -5`.

---

## Task 6: Add the integration test "checker passes against real repo state"

**Why next:** The checker is tested in isolation (Task 4) and the allowlist is built (Task 5). Now we lock in the current real-repo state with an integration test in `test_shell_surface.bats`.

**Files:**
- Modify: `test/test_shell_surface.bats` (append integration test)

- [ ] **Step 1: Append the integration test**

Add at the end of `test/test_shell_surface.bats`:

```bash
# --- Integration: alias reference checker passes against real repo --------

@test "shell-surface: bin/check-alias-references passes against current aliases.zsh" {
    run bash "$DOTFILES_DIR/bin/check-alias-references"
    assert_success
    assert_output --partial "all aliases resolve"
}
```

- [ ] **Step 2: Run the new integration test**

```bash
bats test/test_shell_surface.bats -f "check-alias-references"
```

Expected: 1 test, 0 failures.

- [ ] **Step 3: Run the full BATS suite to confirm no regressions**

```bash
make test
```

Expected: all tests pass, including the existing regression suite, the new shell-surface tests, and the new alias-checker tests.

- [ ] **Step 4: Commit**

```bash
git add test/test_shell_surface.bats
git commit -m "$(cat <<'EOF'
test(shell): assert check-alias-references passes against real repo

Locks in the current good state of aliases.zsh + the system-tools
allowlist + install manifests. Any future change that adds an
unguarded, unmanifested alias reference will fail this test.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: Wire `verify-shell-surface` target into the Makefile

**Why next:** All test machinery is in place; the only missing piece is exposing it as `make verify-shell-surface` and chaining it into `make verify`.

**Files:**
- Modify: `Makefile`

- [ ] **Step 1: Locate the `verify` target and the existing `verify-*` targets**

```bash
grep -nE '^verify' Makefile
```

Expected: lines for `verify:`, `verify-shell:`, `verify-stale-refs:`, `verify-doc-links:`, `verify-tests:`, `verify-nix:`.

- [ ] **Step 2: Add `verify-shell-surface` target after `verify-doc-links`**

Find the `verify-doc-links:` target and the line right after it. Insert a new target:

```makefile
verify-shell-surface:
	@echo "Running shell-surface tests..."
	@bats test/test_shell_surface.bats test/test_alias_checker.bats
```

(Use a literal tab for the indentation — Makefile rules require tabs.)

- [ ] **Step 3: Add `verify-shell-surface` to the `verify` target chain**

Find the line:

```makefile
verify: verify-shell verify-stale-refs verify-doc-links verify-tests verify-nix
```

Replace it with:

```makefile
verify: verify-shell verify-shell-surface verify-stale-refs verify-doc-links verify-tests verify-nix
```

- [ ] **Step 4: Run `make verify-shell-surface` standalone**

```bash
make verify-shell-surface
```

Expected: BATS output for both files, all tests pass.

- [ ] **Step 5: Run the full `make verify` chain**

```bash
make verify
```

Expected: all six verify-* targets run, all pass, ends with `✓ Verification complete`.

- [ ] **Step 6: Commit**

```bash
git add Makefile
git commit -m "$(cat <<'EOF'
build(make): add verify-shell-surface target and wire into verify

verify-shell-surface runs both shell-surface and alias-checker BATS
files. Hooked into the `make verify` chain so CI surfaces shell-layer
regressions alongside doc-link, stale-ref, and nix-flake checks.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: Document `bin/check-alias-references` in `bin/README.md`

**Files:**
- Modify: `bin/README.md`

- [ ] **Step 1: Read the current `bin/README.md`**

```bash
cat bin/README.md
```

Note the existing entry style (e.g., for `validate-doc-links`, `dotfiles-doctor`).

- [ ] **Step 2: Add a new entry matching the existing style**

Append (or insert in alphabetical position) an entry like:

```markdown
### `check-alias-references`

Validates every unconditional alias in `.config/zsh/aliases.zsh` resolves
to a known source: a shell builtin, an entry in `install/Brewfile`,
`Caskfile`, `Rustfile`, or `npmfile`, an alias defined elsewhere in the
file, or an entry in `test/allowlist/system-tools.txt`.

Aliases inside `if command -v X &> /dev/null; then ... fi` blocks are
exempt — the guard itself is the dependency declaration.

**Run:** `bin/check-alias-references` (or `make verify-shell-surface`)

**On failure:** prints the offending alias's file:line, the unresolved
command, and three suggested fixes (manifest entry, guard, or allowlist).
```

(Adjust the heading level and exact wording to match the existing entries' style — e.g., if other entries use `####` or a table format, mirror that.)

- [ ] **Step 3: Commit**

```bash
git add bin/README.md
git commit -m "$(cat <<'EOF'
docs(bin): document check-alias-references helper

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 9: Add notes to `AGENTS.md` and `OPERATING.md`

**Files:**
- Modify: `AGENTS.md`
- Modify: `OPERATING.md`

- [ ] **Step 1: Add a note in `AGENTS.md` Testing Guidelines section**

Read the current section:

```bash
sed -n '/^## Testing/,/^## /p' AGENTS.md
```

Add one sentence after the existing testing description:

```markdown
The suite includes shell-surface validation (`make verify-shell-surface`) which
parses and sources `.zshenv`, `aliases.zsh`, and `functions.zsh`, asserts
sentinel aliases per conditional block, and runs `bin/check-alias-references`
to verify every unconditional alias references a known command.
```

- [ ] **Step 2: Add a troubleshooting entry in `OPERATING.md`**

Find the Troubleshooting section. Add a new collapsible/sub-entry following the existing style:

```markdown
### `verify-shell-surface` fails with "alias references unresolved command"

The alias references a command that is not a shell builtin, not in any
install manifest, and not in `test/allowlist/system-tools.txt`. The error
output names the offending alias's file:line and the unresolved command.
Pick one fix:

1. **Manifest the dependency.** Add the command to the appropriate
   `install/` file (`Brewfile` for Homebrew formulae, `Rustfile` for
   Cargo, `npmfile` for npm globals).
2. **Guard the alias.** Wrap with `if command -v CMD &> /dev/null; then …; fi`
   — appropriate when the command is optional or not available on every
   supported platform.
3. **Allowlist the command.** Only when the command is a base-OS tool
   (e.g., `osascript`, `pbcopy`) that should not be manifested. Add it to
   `test/allowlist/system-tools.txt` with a one-line comment.

To iterate locally without committing, run `bin/check-alias-references`
directly — it prints the same output as the BATS test.
```

- [ ] **Step 3: Run doc-link validation to make sure new links resolve**

```bash
make verify-doc-links
```

Expected: passes.

- [ ] **Step 4: Commit**

```bash
git add AGENTS.md OPERATING.md
git commit -m "$(cat <<'EOF'
docs: note shell-surface tests in AGENTS.md and OPERATING.md

- AGENTS.md: one-line entry in Testing Guidelines describing the
  new shell-surface verify target.
- OPERATING.md: troubleshooting entry explaining the three ways to
  resolve a verify-shell-surface failure (manifest, guard, allowlist).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 10: Final integration check and PR prep

**Why last:** Sanity check before opening the PR.

- [ ] **Step 1: Run the full verification chain end-to-end**

```bash
make verify
```

Expected: all six verify-* targets pass.

- [ ] **Step 2: Run `make daily` (the fast pre-push gate)**

```bash
make daily
```

Expected: passes.

- [ ] **Step 3: Inspect the commit history for this branch**

```bash
git log --oneline main..HEAD
```

Expected: ~9 commits, each a focused, independently meaningful change. If any commits look entangled, consider rebasing/squashing before PR.

- [ ] **Step 4: Push and open the PR**

```bash
git push -u origin docs/shell-surface-tests-spec
gh pr create --title "test: add shell-surface validation suite" --body "$(cat <<'EOF'
## Summary
- Adds `bin/check-alias-references` to verify every unconditional alias in `aliases.zsh` resolves to a builtin, install-manifest entry, alias, or curated allowlist.
- Adds `test/test_shell_surface.bats` with parse, source, and sentinel tests covering `.zshenv`, `aliases.zsh`, and `functions.zsh`.
- Adds `test/test_alias_checker.bats` with fixture-based unit tests for the checker.
- Wires both into `make verify` via a new `verify-shell-surface` target.
- Documents the helper in `bin/README.md`, `AGENTS.md`, and `OPERATING.md`.

Spec: [docs/superpowers/specs/2026-04-27-shell-surface-tests-design.md](docs/superpowers/specs/2026-04-27-shell-surface-tests-design.md)

## Test plan
- [x] `make verify-shell-surface` passes
- [x] `make verify` passes end-to-end
- [x] Manually introducing a typo'd guard in `aliases.zsh` makes the sentinel test fail
- [x] Manually introducing an unmanifested alias makes the checker test fail

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Summary of commits this plan produces

| # | Task | Commit |
|---|---|---|
| 1 | Task 1 | `test(shell): include functions.zsh in verify-shell parse check` |
| 2 | Task 2 | `test(shell): add B-leaf parse and source checks for shell files` |
| 3 | Task 3 | `test(shell): add sentinel test for typo'd command -v guards` |
| 4 | Task 4 | `feat(test): add bin/check-alias-references with fixture tests` |
| 5 | Task 5 | `test(shell): add allowlist of base-OS commands for alias checker` |
| 6 | Task 6 | `test(shell): assert check-alias-references passes against real repo` |
| 7 | Task 7 | `build(make): add verify-shell-surface target and wire into verify` |
| 8 | Task 8 | `docs(bin): document check-alias-references helper` |
| 9 | Task 9 | `docs: note shell-surface tests in AGENTS.md and OPERATING.md` |

(Plus any incidental commits from Task 5's bucket-2/bucket-3 triage if real-repo violations require them.)

Each commit is focused, self-contained, and the test suite passes after each one.
