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

## Platform

Which OS and architecture a **checkout** is running on, answered by
`bin/platform`: `macos`, `arch`, `linux`, `unknown`, plus Omarchy as a
refinement of `arch`. macOS and Arch are the two real adapters; anything that
branches on the OS belongs behind this module rather than testing `$OSTYPE`
inline.

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
preserve. Contrast doctor's tool tiers (**command vs package**), which are an
editorial choice and so are recorded rather than derived.

## Link

Changing **link state** is `bin/link`'s job, and only its: `link-state` is the
read side, `link` the write side. It owns the `.zshenv` symlink and its backup,
the stow invocation, the SSH `Include` line (one definition; `dotfiles-init`
asks `link has-include`), and `~/.local/runtime`.

Three modes, one planner. `apply` and `dry-run` compute the same plan — every
action decided and every conflict found before anything is touched — and print
the same rows; only `apply` performs them. `undo` plans the reverse. A dry run
with its own code path would drift from the real one.

A **tool-owned path** is a config directory a tool writes its own files into.
stow folds a directory it can link whole into one symlink, so those writes land
in the checkout; tool-owned directories are linked **unfolded** instead — a
real directory holding one link per shipped file — and a folded link left by an
older `make link` is converted in place. The list is curated in `bin/link`
(`link tool-owned` prints it), each entry with the write that justifies it.
Karabiner is the deliberate exception: it must stay folded, because
Karabiner-Elements does not notice changes to a symlinked `karabiner.json`.

## Local config

The gitignored per-machine files the **checkout** expects but deliberately does
not track, because they carry identity or real hosts (`CLAUDE.md` § Gotchas,
enforced by `test_dotfiles_init.bats`). `bin/dotfiles-init` classifies and writes
them; `dotfiles-doctor` reports the classification.

Four subjects, each with a tracked template beside it:

| Subject | Local file | Template |
| --- | --- | --- |
| `git-identity` | `~/.config/git/config.local` | `config.local.example` |
| `jj-identity` | `~/.config/jj/conf.d/user.toml` | `user.toml.example` |
| `ssh-include` | the `Include` line in `~/.ssh/config` | — |
| `ssh-hosts` | `~/.config/ssh/config.d/*.conf` | `*.conf.example` |

| State | Meaning |
| --- | --- |
| `configured` | The local file is there and carries everything required |
| `incomplete` | Present, but missing a field |
| `unconfigured` | Nothing local exists |
| `ineffective` | Written and complete, but the tool does not read it |
| `optional` | Nothing local exists, and that is a legitimate end state |

`ineffective` exists because git reaches `config.local` through an `[include]`
in whichever global config it loads, and a chain can be complete at one end and
unread at the other. Only git can answer that, so git identity is classified by
asking `git config --global --includes` rather than by reading the file — note
the flag: under `--global`, git does **not** follow includes by default, so
without it an identity that lives only in the local file is invisible. jj
needs no equivalent: it reads `conf.d/*.toml` directly.

`optional` keeps `ssh-hosts` from ever failing a check. A machine that reaches
nothing over SSH is correctly configured with no snippets, and a state that
cannot be satisfied is a state people learn to ignore.

Writing is one-shot per file: an existing local file is never rewritten, not
even to complete it. This is the one place on a machine whose contents nothing
else can reproduce, so `incomplete` is reported and left alone.

## Manifest

A file under `install/` listing packages for one package manager — `Brewfile`,
`Caskfile`, `Caskfile.extra`, `npmfile`, `Rustfile`, `pacmanfile`, `Codefile`.
The authoritative answer to what this system installs, read only through
`bin/manifest` — never parsed inline. `install/duti` is deliberately not a
manifest: it lists file associations, not packages.

A manifest **kind** is the abstract name for one of them (`brew`, `cask`,
`cask-extra`, `npm`, `rust`, `pacman`, `code`); callers ask for a kind, not a
path. Each entry carries its own rationale in the comment on its line
(install/README.md § Entry format), with optional `cmd=` and `tier=`
metadata (**command vs package**). `dotfiles-why` shows it and
`test_packages.bats` fails on a package with none. The line is the only
catalog: a separate one rots while its headings still match.

A kind answers three verbs, all in `bin/install-kind`: **install** from its
manifest, **update** everything its tool manages (not only manifest entries),
and **record** its **snapshot** record under the name `bin/lib/snapshot.sh`
gives it. Callers keep only what is theirs: the Makefile the dependency edges
between kinds, `dotfiles-update` and `dotfiles-backup` the order and the
report. `SKIP_KINDS` names kinds to skip and `STRICT_PACKAGES` decides whether
a failure is fatal, for every verb — one axis, one spelling, so "skip
cask-extra but not cask" is expressible. Boolean knobs share one truthiness
rule, `knob_on` in `bin/lib/preamble.sh`: `1`/`true` is on; unset, `0` and
`false` are off.

Which kinds a caller cares about is that caller's policy, not the module's:
`check-alias-references` reads only the kinds that put a command on PATH, and
`dotfiles-doctor` only the entries that carry a `tier=`.

## Command vs package

A **package** is what a manifest installs (`ripgrep`); a **command** is what
lands on PATH (`rg`). They usually match and sometimes do not, so the manifest
line says so: `cmd=rg` on the entry (install/README.md § Entry format); with
no `cmd=`, the package name is the command. `dotfiles-doctor` probes
commands, and `dotfiles-why rg` finds ripgrep, both by reading that.

Doctor's severity tiers (core / essential / next-gen / additional) stay a
curated editorial judgement — the manifests say what is installed, not what
matters — but the judgement is recorded where the package is: `tier=` on its
manifest line. Removing a package removes its probe. The only commands doctor
names itself are the core ones no macOS manifest installs (`git`, `zsh`,
`stow`): macOS ships the first two and `make link` bootstraps the third.

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

## Palette

The colours every themed tool shares, defined once in
`.config/palette/danse.conf` and read only by `bin/palette`. Its interface is
three verbs: `render` writes every **rendered file** from its **template**,
`check` fails with a diff when a committed rendered file differs from what
its template produces, and `fill` expands slots on stdin for scripts.

A **template** lives under `.config/palette/templates/` at the path of the
file it renders, relative to the **checkout** root, and names colours as
**slots**: `{{blue}}`, `{{blue:0x}}`, `{{blue:rgb}}`. The three formats are
the adapters — one per spelling a real consumer needs — and a literal colour
in a template is an error, because typing one is how off-palette colours got
in.

A **rendered file** is committed at its real path, because stow links it and
the tool reads it; it is never edited by hand. It is either **whole** (the
template is the file) or a **region** (the lines between a `palette:begin`
and `palette:end` comment in an otherwise hand-edited file, such as
`.zshrc`). Nothing parses the palette at runtime: shell, lua and sketchybar
consumers read rendered values, and `install.sh`, which runs before any
checkout exists, carries its colours as a region.

Retuning is an edit to `danse.conf` plus `palette render`; `make verify` fails
until the render is committed.

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

## Reporter

A caller that maps a state vocabulary — **sync state**, **link state**,
**local config** — to output. The reporter is the seam:
`dotfiles-update` uses `bin/lib/ui.sh`'s printers, `dotfiles-sync` uses a
local `notify()` over `osascript`, `dotfiles-doctor` uses its engine (below).
Reporters live on the caller side of the seam; platform-specific output
(`osascript`) stays out of the shared module.

`dotfiles-doctor` is one reporter over many classifiers. Each section is a
**classifier** that prints `state<TAB>subject<TAB>detail` rows and judges
nothing — `bin/link-state`, `dotfiles-init --status` and `git_sync_status`
plug in unchanged, and the system, package-manager, tool, shell and
permission probes emit the same shape. One table maps (vocabulary, state) to
a severity and an optional note:

| Severity | Printed | Effect |
| --- | --- | --- |
| `pass` | ✓ | — |
| `info` | ℹ | — |
| `warn` | ⚠ | counted; never fails the run |
| `fail` | ✗ | counted; exit 1 |
| `skip` | nothing | — (`broken-foreign`: not ours to judge) |

The table is the interface: `dotfiles-doctor --states` prints it, and a test
checks it covers every state each classifier's own vocabulary lists. A state
the table does not map is reported as `fail`, so a classifier that grows a
state cannot pass silently. Missing tools and local config are `warn`, never
`fail`: `make link` installs and configures nothing, so a freshly linked
machine must be able to pass.
