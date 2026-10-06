# install/

What this system installs, one manifest per package manager. Nothing parses
these files except [`bin/manifest`](../bin/manifest); installing, updating and
recording them is [`bin/install-kind`](../bin/install-kind)'s job, and the
`make` targets below call it.

| File | Kind | Installed by | Platform |
| --- | --- | --- | --- |
| [Brewfile](Brewfile) | `brew` | `make brew-packages` (in `make macos`) | macOS |
| [Caskfile](Caskfile) | `cask` | `make cask-apps` (in `make macos`) | macOS |
| [Caskfile.extra](Caskfile.extra) | `cask-extra` | `make cask-apps-extra` only | macOS |
| [npmfile](npmfile) | `npm` | `make node-packages` (in `make macos`) | macOS |
| [Rustfile](Rustfile) | `rust` | `make rust-packages` (in `make macos`) | macOS |
| [Codefile](Codefile) | `code` | `make vscode-extensions` (in `make macos`) | macOS |
| [pacmanfile](pacmanfile) | `pacman` | `make pacman-packages` (in `make arch`) | Arch |
| [duti](duti) | — | `make duti` (in `make macos`) | macOS |

`duti` is not a manifest: it maps file types to apps, and lists no packages.
Caskfile holds what a fresh Mac needs to be usable; everything optional
(games, media production, extra fonts) is in Caskfile.extra and is never
installed unasked. `SKIP_KINDS` and `STRICT_PACKAGES` apply to every kind
(`make help`).

## Entry format

Every package entry documents itself on its own line: why it is here, and —
where it matters — what command it provides and how much `dotfiles-doctor`
cares about it. The line is the only place that rationale lives, so it cannot
drift from the entry it describes.

```text
brew "ripgrep"                         # cmd=rg tier=essential Fast recursive grep ...
cask "ghostty"                         # Primary terminal: ...
jujutsu                                # cmd=jj Jujutsu VCS. Arch's name for Homebrew's `jj`.
```

The comment after `#` is zero or more `key=value` metadata tokens, then the
rationale (the rest of the line). Keys:

| Key | Value | Meaning |
| --- | --- | --- |
| `cmd` | a command name | The command the package puts on PATH, when it differs from the package name (`ripgrep` installs `rg`). |
| `tier` | `core`, `essential`, `next-gen`, `additional` | `dotfiles-doctor` probes the command, at that severity. Absent: doctor does not probe it. |

An unknown key, a tier outside that list, or a repeated key makes the line
unparseable, and `bin/manifest` fails on it like any other malformed entry. A
missing rationale does not stop an install, but `test/test_packages.bats`
fails on it: every package needs one on at least one of its lines. When the
same package name is in two manifests (usually the Brewfile and the
pacmanfile), the rationale and metadata go on one line — the Brewfile's, by
convention — and the other stays bare.

Read it with `dotfiles-why <package-or-command>`, or `bin/manifest describe`.
Keep a rationale to one line; a note that needs paragraphs belongs in the
tool's `.config/<app>/README.md`.

## Adding or removing a package

Add the line, with its rationale, to the manifest for its kind, then run that
kind's `make` target; `make test` fails on a line without a rationale. To
remove one, delete the line; its rationale and any doctor probe go with it.
If an alias in `.config/zsh/aliases.zsh` uses the command, `make test` fails
until the alias goes too, or is guarded (OPERATING.md § Troubleshooting).

Never regenerate a manifest from what is installed (`brew bundle dump
--force`, `pacman -Qqe >`, …): a dump carries no rationales and would erase
every one. To see drift instead, compare against a listing:

```bash
comm -13 <(bin/manifest list brew | sort) <(brew leaves | sort)   # installed, not listed
```

Nor run `brew bundle cleanup --force` against one file: formulae and casks
live in separate manifests, so it would uninstall everything in the others.
