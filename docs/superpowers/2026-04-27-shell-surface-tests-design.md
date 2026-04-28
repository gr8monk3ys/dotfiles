# Shell-surface tests: lock in the weakest tested layer

**Status:** Design — pending implementation plan
**Date:** 2026-04-27
**Owner:** @gr8monk3ys

## Problem

The repo has a strong CI footprint — BATS suite, Docker matrix, doc-link validator, stale-reference scanner — but the largest behavioral surface (shell aliases and functions) is only implicitly tested. A typo in `.config/zsh/aliases.zsh` does not fail CI; it lands silently and reveals itself months later when the user types the broken alias. Two failure modes go unguarded today:

1. **Syntax / sourcing errors** — a missing quote, an unbalanced `if/fi`, or a typo'd guard (`commnd -v eza`) silently disables a whole conditional block. The shell sources it without complaint at startup; the user just notices later that `ls` is the system `ls` again.
2. **Reference drift** — an alias references a tool that is no longer in the install manifest (e.g., a Brewfile entry was removed in a tool swap, but the unconditional `alias ls="eza ..."` survived). Repository-level audits ("audit round 2", per recent commit history) keep catching these by hand. The repo has *no automated guard* against this class.

This spec adds two thin layers of testing that close both gaps.

## Goal

Extend the BATS suite so that:

- **B-leaf:** A syntax error or source-time error in `.zshenv`, `.config/zsh/aliases.zsh`, or `.config/zsh/functions.zsh` fails CI.
- **C:** Every unconditional alias whose body invokes an external command resolves that command to a known source — a shell builtin, a documented system tool, or an entry in an install manifest. Any alias that does not resolve must either move to a `command -v X` guard, gain a manifest entry, or be added to a curated allowlist with justification.

## Non-goals

- Behavioral testing of alias expansions (e.g., `type ls` returns `eza ...`). Too brittle for the value.
- Full `.zshrc` integration testing. Sourcing it requires zinit, plugins, and network. The "your code" surface is the leaves; integration is one-line concern, caught by smoke testing on machine setup.
- Linting non-shell config files (Neovim Lua, Yazi TOML, etc.). Out of scope.
- A general-purpose alias linter for the broader community. This is purpose-built for this repo.

## Architecture

Three new files, one Makefile change, one allowlist file. Mirrors the existing `bin/validate-doc-links` + `make verify-doc-links` pattern.

```
bin/check-alias-references         # the C-layer parser/checker (script)
test/test_shell_surface.bats       # B-leaf + C BATS tests
test/allowlist/system-tools.txt    # curated list of "always present" commands
Makefile                           # add verify-shell-surface target, hook into verify
bin/README.md                      # document the new helper
```

### Why a script + thin BATS wrapper rather than pure BATS

- **Reusability outside CI.** `bin/check-alias-references` can be run by hand to debug "why did this fail?" — same shape as `bin/validate-doc-links`.
- **Better failure messages.** Custom error formatting (file:line, the offending command, fix-it instructions) is awkward to produce inside BATS assertions.
- **Smaller test file.** BATS test stays at ~10 lines; the parser logic lives where parser logic belongs.
- **Follows existing convention.** Per `OPERATING.md`, the existing `bin/validate-doc-links` already does exactly this for doc links.

## B-leaf design

For each of `.zshenv`, `.config/zsh/aliases.zsh`, `.config/zsh/functions.zsh`:

1. **Parse-check.** Run `zsh -n <file>`. Asserts the file is syntactically valid zsh. Catches missing quotes, unbalanced `if/fi`, malformed `alias` keyword.
2. **Source-check.** Run `zsh -c 'source <file>'` in a clean subshell with a controlled `HOME=$TEST_HOME`. Asserts exit 0 and no stderr output. Catches:
   - Errors that fire at definition time (bad function syntax, bad guard expressions).
   - Typos in `command -v` guards (the typo'd guard is silently false, no error fires — but it also means no aliases inside the block get defined; the test asserts a sentinel: at least one expected alias exists after sourcing).

Alias *bodies* are strings until invoked, so sourcing does **not** require any of the referenced tools to be installed. This is what makes B-leaf cheap.

### Sentinel post-source assertion

After sourcing `aliases.zsh`, assert that one alias from each conditional block exists. The intent: if a guard expression has a typo (`commnd -v eza`) the whole block is silently skipped, but no error fires. The sentinel test catches this by asserting at least one alias from each block was actually defined.

The implementation plan picks the concrete sentinel set by walking `aliases.zsh` and identifying each `if command -v X &> /dev/null` block, then selecting one representative alias from each. Sentinels live in the BATS file as a small list (~6–10 entries based on the current file).

## C design: alias reference checker

`bin/check-alias-references` reads `.config/zsh/aliases.zsh` and `.config/zsh/functions.zsh`, walks every alias/function definition, and verifies each external command reference resolves.

### Resolution order

For each `alias NAME=BODY` line that is **not inside a conditional block**:

1. **Tokenize the body.** Take the first whitespace-separated word.
2. **Strip wrappers.** If the first word is `sudo`, `command`, `nohup`, or `exec`, take the next word instead.
3. **Skip non-command tokens:**
   - First word starts with `/` → absolute path (e.g., `/Applications/Google Chrome.app/...`). Skip.
   - First word starts with `$` or `${` → variable expansion. Skip.
   - First word is a shell control structure keyword (`if`, `while`, etc., though rare in alias bodies). Skip.
4. **Resolve.** The remaining token must match one of:
   - **Shell builtin** — hardcoded list (cd, echo, exec, type, command, builtin, eval, exit, export, return, set, source, ., test, [, alias, unalias, history, jobs, fg, bg, pwd, read, shift, trap, umask, wait, true, false, :, printf, time, times, kill, ulimit).
   - **System tool allowlist** — entry in `test/allowlist/system-tools.txt` (one command per line, comments allowed).
   - **Install manifest** — entry in `install/Brewfile`, `install/Caskfile`, `install/Rustfile`, or `install/npmfile`. Manifest parsing handles each format's quirks (`brew "name"`, `cask "name"`, bare names with `#` comments).

If none match, the alias is a violation.

### Conditional-block detection

A line is "inside a conditional block" if it falls between an `if command -v X &> /dev/null; then` (or equivalent variant) and the matching `fi`. Inside such a block, aliases are exempt from C-checking — the guard *is* the dependency declaration.

The fallback pattern `command -v X > /dev/null || alias X=...` is exempt from C-checking *for the alias name X*, but the **fallback body** (e.g., `hexdump -C`) is still checked. The fallback is what runs when X is missing, so it must resolve.

Variants the parser must recognize:

- `if command -v X &> /dev/null; then` (current pattern)
- `if command -v X > /dev/null 2>&1; then`
- `if command -v X &>/dev/null; then`
- `command -v X > /dev/null || alias ...` (fallback form)

### Function and cross-alias references

C-checking applies to `aliases.zsh` only. `functions.zsh` is covered by B-leaf (parse + source); its bodies are not parsed for command references because function bodies legitimately contain control flow that's expensive to model and rarely the source of drift. The unconditional `cx` function is reviewed by hand on each change — at 25 lines total, `functions.zsh` is small enough that human review is the right tool.

For **aliases referencing other aliases** (e.g., `alias dotsup='cd ~/.dotfiles && make link'` referencing `cd`, or pipelines that chain to alias names), the checker treats any alias name defined anywhere in `aliases.zsh` as a valid resolution target. Source order does not matter — zsh resolves alias references at expansion time, not at definition time.

### Error message format

When the checker fails, output is:

```
check-alias-references: 1 violation found

  .config/zsh/aliases.zsh:42
    alias 'foo' references 'bar' (after stripping wrappers)
    'bar' is not in:
      - shell builtins
      - test/allowlist/system-tools.txt
      - install/Brewfile, install/Caskfile, install/Rustfile, install/npmfile

    Fix one of:
      1. Add 'bar' to install/Brewfile (or appropriate manifest)
      2. Wrap the alias with a guard:
           if command -v bar &> /dev/null; then
               alias foo='bar ...'
           fi
      3. If 'bar' is a base system tool that should not be manifested
         (e.g., 'osascript', 'pbcopy'), add it to
         test/allowlist/system-tools.txt with a one-line comment.

Run 'bin/check-alias-references' locally to iterate.
```

Exit code: 0 on success, 1 on any violation.

## Allowlist file format

`test/allowlist/system-tools.txt`:

- One command per line.
- Comment syntax: a line starting with `#` is a comment; an inline `#` (preceded by whitespace) starts an end-of-line comment. Both forms are supported.
- Section headers are comment lines, not enforced by tooling.
- Each entry should have a short justification (inline comment) explaining why the command is base-OS rather than manifested.

Illustrative shape (concrete contents produced during implementation by walking `aliases.zsh` and identifying which commands need entries):

```
# Commands assumed always-present on supported platforms.
# Add an entry only when the command is part of the base OS install
# (macOS or supported Linux), not when it just happens to be installed
# on your machine.

# POSIX / Unix coreutils
ls
cp
find
grep
# ...

# macOS system tools
osascript        # AppleScript runner
defaults         # macOS preferences
pbcopy           # clipboard
# ...

# Common interpreters
python3          # /usr/bin/python3 ships with Xcode CLT
```

Producing the allowlist contents from the actual `aliases.zsh` rather than imagining them upfront avoids a "designed in a vacuum" list that doesn't match reality.

## Makefile integration

Add a new target and chain it into `verify`:

```makefile
verify-shell-surface:
	@echo "Checking shell-surface tests..."
	@bats test/test_shell_surface.bats

verify: verify-shell verify-shell-surface verify-stale-refs verify-doc-links verify-tests verify-nix
```

`verify-shell-surface` runs the BATS file, which itself shells out to `bin/check-alias-references`. Two layers, one entry point.

## Test plan

`test/test_shell_surface.bats` contains roughly:

| # | Test | Asserts |
|---|------|---------|
| 1 | `.zshenv parses` | `zsh -n .zshenv` exits 0 |
| 2 | `aliases.zsh parses` | `zsh -n .config/zsh/aliases.zsh` exits 0 |
| 3 | `functions.zsh parses` | `zsh -n .config/zsh/functions.zsh` exits 0 |
| 4 | `.zshenv sources cleanly` | `zsh -c 'source .zshenv'` exits 0, no stderr |
| 5 | `aliases.zsh sources cleanly` | as above |
| 6 | `functions.zsh sources cleanly` | as above |
| 7 | `aliases.zsh defines sentinels` | After sourcing, each sentinel alias (one per conditional block; concrete list produced in implementation) is non-empty when queried via `alias -L NAME` |
| 8 | `bin/check-alias-references passes` | Script exits 0 against current repo state |

Total runtime target: under 1 second. No tool installations required beyond zsh (already in CI).

### Negative tests (optional, in implementation plan)

To verify the checker actually catches what it claims, add 1-2 fixture-based negative tests in a separate file (`test/test_alias_checker.bats`) that pass synthetic alias-file fragments to `bin/check-alias-references` and assert it fails with the expected message. These give us confidence the checker isn't silently passing everything.

## Edge cases the design accounts for

- **Wrapper commands** (`sudo`, `command`, `nohup`, `exec`) — unwrap to find the real dependency.
- **Absolute paths in alias bodies** (`/Applications/Google Chrome.app/...`) — skip; they're macOS GUI app paths the user has accepted.
- **Variable expansion in body** (`${SHELL}`, `${EDITOR:-nvim}`) — skip; first word is dynamic.
- **Aliases referencing other aliases** — resolve against the set of aliases defined anywhere in `aliases.zsh` (source order doesn't affect zsh's expansion-time resolution).
- **Fallback aliases** (`command -v hd > /dev/null || alias hd="hexdump -C"`) — the alias name is exempt; the fallback body is still checked.
- **The `lwp-request` block** (line 129+ in current `aliases.zsh`) — already inside `if command -v lwp-request &> /dev/null`, so already exempt under conditional-block rules.

## Edge cases explicitly out of scope

- Multi-statement alias bodies (`alias x="cmd1; cmd2"`) — only the first command is checked. If a second command is broken, that's a future iteration.
- Pipelines inside alias bodies (`alias ifactive="ifconfig | pcregrep ..."`) — only the first command (`ifconfig`) is checked. Same rationale.
- Subshell expressions (`alias x="$(some-cmd)"`) — current `aliases.zsh` does not use these. Not handled.
- Nested conditionals (`if X; then if Y; then alias ...; fi; fi`) — current `aliases.zsh` is flat; not handled.

## Documentation updates

- `bin/README.md` — add an entry for `bin/check-alias-references` describing its role.
- `AGENTS.md` — add a one-line note in the Testing Guidelines section that the suite covers shell-surface validation, and a note about the new check in the "Add a shell alias" recipe in `OPERATING.md`.
- `OPERATING.md` — add a "Stale alias reference" entry to the Troubleshooting section showing how to interpret a `verify-shell-surface` failure.

## What this design deliberately does not do

- **No new dependencies.** Pure shell, runs against existing zsh + bats setup.
- **No reformatting of `aliases.zsh`.** Existing structure stands.
- **No moving aliases between files.** No reorganization, just validation.
- **No changes to `.zshrc`.** Out of scope by user decision (B-leaf, not B-full).

## Open questions deferred to implementation

These are design-shaped enough that the implementation plan will resolve them rather than re-litigating here:

- Whether `zsh -c 'source <file>'` should run with `set -e` and/or `set -u` for strictness, vs. matching the user's actual shell. *Default: match the user's shell, no strict mode, but assert empty stderr.*
- Whether the allowlist should be a flat file or have categorized sections enforced by tooling. *Default: flat file with section comments only.*
- Whether to add a `--fix` flag to the checker that proposes patch-shaped suggestions. *Default: no, out of scope.*
