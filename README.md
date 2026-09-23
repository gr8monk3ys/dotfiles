# dotfiles

[![CI](https://img.shields.io/github/actions/workflow/status/gr8monk3ys/dotfiles/ci.yml?branch=main&style=flat-square&logo=github)](https://github.com/gr8monk3ys/dotfiles/actions/workflows/ci.yml)

My macOS and Arch (incl. Omarchy) environment: 26 XDG configs linked with GNU
Stow, package manifests, and a `make verify` gate that keeps the two honest.

The part that matters: **every package has to justify itself.** Each manifest
line carries its rationale in its own comment, and `make verify` fails on a
package without one — the reason cannot drift away from the entry it explains. Same idea for the shell: `bin/check-alias-references`
rejects any unconditional alias whose target is not a manifest entry, a builtin,
or an allowlisted system tool. Tracked config carries no identity or real hosts;
a regression test grep-checks that too. The suite is 91 BATS tests; a second
interactive zsh start is budgeted at 900 ms and tested.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/gr8monk3ys/dotfiles/main/install.sh | bash
```

Or clone and look first:

```bash
git clone https://github.com/gr8monk3ys/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
make link-dry-run   # preview the symlinks
make                # macOS: brew + casks + npm/cargo globals + link; Arch: pacman + link
```

Non-interactive (what CI runs):

```bash
DOTFILES_ASSUME_YES=1 DOTFILES_MACHINE_TYPE=personal \
  curl -fsSL https://raw.githubusercontent.com/gr8monk3ys/dotfiles/main/install.sh | bash
```

Machine-specific values (git/jj identity, SSH hosts, work overrides) live in
gitignored local files; `OPERATING.md` lists them. `make` links a machine but
cannot configure one, so finish with:

```bash
make init          # git and jj identity, from their templates; prompts for what it needs
make init GIT_USER_NAME="Your Name" GIT_USER_EMAIL=you@example.com   # non-interactive
make init check=1  # report only; non-zero if anything is still unconfigured
```

## Verify

```bash
make test      # bats test
make verify    # linters, stale refs, palette check, doc links, bats, Docker fresh install
make doctor    # health check of the linked machine
```

## What is in it

| Area | Tools |
| --- | --- |
| Window management | AeroSpace, SketchyBar, Karabiner (vim-style navigation) |
| Terminal | Ghostty, zsh + zinit, Starship, Zellij (tmux kept as backup) |
| Editing / VCS | Neovim (LSP), git + delta, Jujutsu, lazygit |
| CLI | yazi, eza, bat, ripgrep, fd, zoxide, atuin, dust, procs, bottom, broot, navi, ouch |
| Packages | Homebrew, pacman, mise, cargo, npm |

`ls`, `cat`, `cd` are aliased to their replacements; `grep`, `find`, `du`,
`ps`, `top` deliberately are not. Why each tool is here: `dotfiles-why <tool>`,
or the comment on its line in [install/](install/).

Everything is themed from one place. [`.config/palette/`](.config/palette/)
holds the palette — OneDark, with two accents and two chrome fills tuned to
Matisse's _La Danse_ (1910), which `bin/wallpaper` also composes into the
desktop background. The artwork is public domain but is not tracked here;
the script fetches it and the repo carries the recipe.

## Layout

```
.config/     one directory per tool, each with a README
bin/         dotfiles-doctor/update/backup/restore/sync/why, palette, wallpaper, validators
install/     Brewfile, Caskfile, Caskfile.extra, npmfile, Rustfile, pacmanfile, Codefile, duti
test/        BATS suite
docs/        agent skill notes
install.sh   one-line installer
Makefile     install, link, verify targets (make help)
```

[OPERATING.md](OPERATING.md) is the runbook: install paths, machine profiles,
local overrides, `make` reference, troubleshooting, conventions.
[CHANGELOG.md](CHANGELOG.md) has the history. License: GPL-3.0.
