# Context

Domain language for this repo. Terms defined here are the ones to use in
commit messages, issues, tests and refactor proposals; don't drift to
synonyms this file avoids.

See `docs/agents/domain.md` for how the engineering skills consume this file.

## Checkout

A working copy of the dotfiles repository that `bin/dotfiles-*` operates on,
addressed as `DOTFILES_DIR`. Not necessarily the primary clone — `bin/dotfiles-worktree`
creates additional checkouts as git worktrees, and every module that inspects
one must handle a worktree's `.git` being a file rather than a directory.

## Sync state

The classification of a **checkout** against its upstream, produced by
`bin/lib/git-sync.sh`. One vocabulary, three reporters: `dotfiles-update`
prints it, `dotfiles-sync` notifies on it, `dotfiles-doctor` warns on it.

| State | Meaning |
| --- | --- |
| `missing-dir` | `DOTFILES_DIR` does not exist |
| `not-a-repo` | Exists, but is not the root of a git repository |
| `dirty` | Uncommitted changes present. Carries **no verdict** — see below |
| `no-upstream` | The branch tracks nothing, so the checkout can never sync |
| `fetch-failed` | The remote could not be reached |
| `clean-uptodate` | Level with upstream |
| `clean-behind` | Behind upstream and safe to fast-forward |
| `diverged` | Both sides have moved, or histories are unrelated |
| `pulled` | `git_sync_apply` fast-forwarded successfully |
| `pull-failed` | `git_sync_apply` attempted a pull and it failed |

`dirty` is deliberately verdict-free: it is fatal to nothing on its own, and
each caller decides. `dotfiles-sync` treats it as a benign skip; `dotfiles-update`
skips the repository step and carries on with package updates.

## Link state

The classification of a managed path against the **checkout**, produced by
`bin/link-state`. `dotfiles-doctor` reports it; `make clean` acts on it.

| State | Meaning |
| --- | --- |
| `linked` | Resolves into the checkout (folded or unfolded) |
| `partial` | Unfolded directory, some shipped files not linked |
| `unlinked` | The checkout ships it, nothing is at the target |
| `unmanaged` | Something is there, but it is not ours |
| `broken-ours` | A broken link pointing into the checkout |
| `broken-foreign` | A broken link pointing somewhere else |

Folded versus unfolded is deliberately absent: no caller acts on the
difference, so it stays an implementation detail rather than interface.

The directory list is **derived** from what the checkout ships, not curated —
`stow` links all of `.config/`, so there is no editorial judgement to
preserve. This is the opposite of the tool lists in **command vs package**,
where the severity tiers are a real editorial choice and the validator checks
a curated list instead of replacing it.

## Reporter

A caller that maps **sync state** to output. The reporter is the seam:
`dotfiles-update` uses `bin/lib/ui.sh`'s printers, `dotfiles-sync` uses a
local `notify()` over `osascript`, `dotfiles-doctor` uses `check_warn`.
Reporters live on the caller side of the seam; platform-specific output
(`osascript`) stays out of the shared module.

## Manifest

A file under `install/` listing packages for one package manager — `Brewfile`,
`Caskfile`, `Caskfile.extra`, `npmfile`, `Rustfile`, `pacmanfile`, `Codefile`.
The authoritative answer to what this system installs, read only through
`bin/manifest` — never parsed inline. `install/duti` is deliberately not a
manifest: it lists file associations, not packages.

A manifest **kind** is the abstract name for one of them (`brew`, `cask`,
`cask-extra`, `npm`, `rust`, `pacman`, `code`); callers ask for a kind, not a
path. `docs/TOOLS.md` carries one rationale entry per manifest entry, and
`bin/validate-tool-docs` fails when the two disagree in either direction.

Installing a kind is `bin/install-kind`'s job; the Makefile keeps only the
dependency edges between kinds. `SKIP_KINDS` names kinds to skip and
`STRICT_PACKAGES` decides whether a package failure is fatal — one axis, one
spelling, replacing four booleans that could not express "skip cask-extra but
not cask".

Which kinds a caller cares about is that caller's policy, not the module's:
`validate-tool-docs` excludes `font-*` casks (its Fonts section covers them),
`check-alias-references` reads only the kinds that put a command on PATH.

## Snapshot

A timestamped directory written by `bin/dotfiles-backup` under `$BACKUP_DIR`.
Its layout is described once, in `bin/lib/snapshot.sh`; backup and restore
both read that table rather than each knowing the filenames.

A snapshot is a **forensic record, not a replayable installer**. Replay lives
in the **manifests** and `make`. What a snapshot uniquely holds is drift:
what was actually on the machine at that moment, including things no manifest
tracks.

Each artifact has a class:

| Class | Meaning | Members |
| --- | --- | --- |
| `tree` | A directory of files; `dotfiles-restore` replays it | `configs/`, `ssh/` |
| `record` | Text record of installed state; preserved, never replayed | `Brewfile`, `Caskfile`, `npm-global-list.txt`, `cargo-installed.txt`, the extension lists |
| `metadata` | Describes the snapshot itself | `MANIFEST.txt` |

`Brewfile` is a `record` even though `brew bundle` could replay it: recording
a capability nothing uses would mislead the next reader about what restore
does. Records carry a provenance header naming the command that produced
them, so none can be mistaken for a file under `install/`.

A row may name a `legacy` filename, so a snapshot taken before a rename still
resolves — `npm-global-list.txt` was once `npmfile.txt`, which was misleading
because it is `npm list` tree output, not the bare-name format of
`install/npmfile`.

## Command vs package

A **package** is what a manifest installs (`ripgrep`); a **command** is what
lands on PATH (`rg`). They usually match and sometimes do not, so
`dotfiles-doctor` — which probes commands — cannot read its tool lists
straight from the manifests. `test/allowlist/command-packages.txt` records
the cases where they differ, plus the commands no manifest tracks (`zsh`,
`stow`), and `bin/validate-doctor-tools` fails when the two drift apart.

Doctor's severity tiers (core / essential / next-gen / additional) stay a
curated editorial judgement: the manifests say what is installed, not what
matters.

## Firefox profile state

The classification of one Firefox profile's `user.js` against the **checkout**,
produced by `bin/firefox-user-js`. Profiles are discovered from `profiles.ini`,
never by globbing `Profiles/*/`: a glob finds profiles Firefox has abandoned
and cannot say which one is live.

| State | Meaning |
| --- | --- |
| `linked` | `user.js` is a symlink resolving to the checkout's copy |
| `installed` | `user.js` is a regular file identical to the checkout's copy |
| `foreign` | A `user.js` is present that this checkout did not write |
| `absent` | The profile exists and has no `user.js` |
| `missing` | `profiles.ini` names the profile, but the directory is not there |

`linked` and `installed` are the same intent under two placement modes
(symlink, the default, and `--copy` for sandboxed builds); which one counts as
current depends on the mode asked for, and switching between them is not a
clobber. `foreign` is the only state that earns a backup.

A profile also carries a **role**, `default` or `other`. `default` is the
profile Firefox actually opens, which is what an `[Install…]` section's
`Default=` names — not a `[Profile N]` section's `Default=1`, which is only
the legacy fallback. The two disagree on the machine this was written for, and
trusting `Default=1` would harden a profile that has never been opened.

This is deliberately a separate vocabulary from **link state**, not an
extension of it. Stow links `.config/firefox/` to `~/.config/firefox/`, a path
Firefox never reads; the stowed copy is the source of truth and the profile
copy is the effective one, so a profile can be `absent` while its link state is
perfectly `linked`.

## Shell surface

The files a login shell sources: `.zshenv`, then `$ZDOTDIR/.zshrc`, which
sources `lib.zsh`, `aliases.zsh` and `functions.zsh` **in that order**.

The order is load-bearing, not incidental. `aliases.zsh` builds the `copy`
alias out of `lib.zsh`'s `_dotfiles_clipboard`, and zsh expands aliases when a
function body is _parsed_, so `functions.zsh` must come last for `cx` to pick
up `l`. `test_shell_boot.bats` boots a real interactive zsh and asserts the
helper is live, which makes this a checked constraint rather than a comment.

Anything with a runtime observable is asserted against that booted shell
rather than by grepping the config files — a grep cannot tell a setting that
parses from one that takes effect. Text checks remain only where there is no
cheap runtime observable, or the rule is inherently static.

## Platform

Which OS and architecture a **checkout** is running on, answered by
`bin/platform`: `macos`, `arch`, `linux`, `unknown`, plus Omarchy as a
refinement of `arch`. macOS and Arch are the two real adapters; anything that
branches on the OS belongs behind this module rather than testing `$OSTYPE`
inline.
