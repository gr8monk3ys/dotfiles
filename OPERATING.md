# OPERATING.md

How this repo works — install, daily operations, making changes, troubleshooting.

## Who this is for

Two audiences:

- **Future-you on a fresh machine.** You have full mental context about why things are set up this way, but no muscle memory for which commands to run. This doc is your runbook.
- **AI assistants opening the repo.** You have zero context. This doc gives you orientation, current-state truth, and canonical recipes for changes.

For a public-facing overview (what this repo is and why), see [README.md](README.md). Contributing conventions and style are at the end of this file: [Contributing and conventions](#contributing-and-conventions). `AGENTS.md` and `CLAUDE.md` are pointer files for agent tools and carry no content of their own.

---

## Install on a new machine

### Prerequisites (macOS only)

```bash
xcode-select --install
```

### Install (Homebrew)

`make` picks a target from `bin/platform detect`: **macOS** installs
Homebrew packages, casks, npm/Cargo globals and links; **Arch** installs
`install/pacmanfile` and links; **other Linux** only links (`make link`
needs `stow` on PATH and stops with a hint if it is missing).

One-liner (interactive):

```bash
curl -fsSL https://raw.githubusercontent.com/gr8monk3ys/dotfiles/main/install.sh | bash
```

Non-interactive (CI / repeatable):

```bash
DOTFILES_ASSUME_YES=1 DOTFILES_MACHINE_TYPE=personal \
  curl -fsSL https://raw.githubusercontent.com/gr8monk3ys/dotfiles/main/install.sh | bash
```

Or clone first and run `make`:

```bash
git clone https://github.com/gr8monk3ys/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
make
```

### Arch: Omarchy

[Omarchy](https://github.com/basecamp/omarchy) is Arch + Hyprland. `bin/platform detect`
still says `arch` on it (`bin/platform is-omarchy` distinguishes it; the marker is the
`~/.local/share/omarchy` checkout — Omarchy does not write its own `/etc/os-release`),
so the install path is `make arch`: `pacman -Syu` via `bin/pacman` (sudo wrapper),
then `install/pacmanfile`, then `make link`. Facts below were checked against the
v3.8.4 tag and not on a live Omarchy box.

**Who owns what.** Omarchy owns `~/.local/share/omarchy` and, on install, copies its
`config/*` into `~/.config` (`hypr`, `waybar`, `walker`, `alacritty`, `kitty`, `foot`,
`btop`, `lazygit`, `uwsm`, `xdg-terminals.list`, …) and writes `~/.bashrc`. These
dotfiles own zsh, git, nvim, tmux, ghostty, yazi, jj, zellij, starship, atuin, and the
rest of `.config/`. Leave Omarchy's Hyprland/waybar/walker configs alone.

**Stow conflicts.** Omarchy also writes files these dotfiles ship, so `make link` will
refuse on a fresh box: `~/.config/ghostty/config`, `~/.config/tmux/tmux.conf`,
`~/.config/fastfetch/config.jsonc`, and `~/.config/nvim` (LazyVim, via
`omarchy-nvim-setup`). Move them aside, then link:

```bash
for p in ghostty/config tmux/tmux.conf fastfetch/config.jsonc nvim; do
  [[ -e ~/.config/$p ]] && mv ~/.config/$p ~/.config/$p.omarchy-backup; done
make link
```

Or `stow --adopt` then `git checkout -- .config` to discard the adopted copies.
`~/.config/git/config` (Omarchy's) does not collide: this repo ships `git/ignore` and a
`config.local.example`, not `git/config`. Starship: Omarchy writes `~/.config/starship.toml`;
`.zshrc` sets `STARSHIP_CONFIG` to `~/.config/starship/starship.toml`, so zsh uses ours.

**Shell.** Omarchy's login shell is bash and its boot chain (SDDM session script,
`~/.bashrc` → `~/.local/share/omarchy/default/bash/rc`, the `omarchy-*` helpers)
assumes it. Upstream advises against `chsh -s $(which zsh)`
([discussion #2495](https://github.com/basecamp/omarchy/discussions/2495)); instead
launch zsh from the terminal: `command = /usr/bin/zsh` in `~/.config/ghostty/config`
(ours), or `exec zsh` at the end of `~/.bashrc` guarded so it only fires interactively.
`make doctor` reports this. The terminal itself is picked with
`omarchy-install-terminal ghostty`, which rewrites `~/.config/xdg-terminals.list` for
`xdg-terminal-exec`; the manual's default is Alacritty.

**Packages.** `install/pacmanfile` overlaps Omarchy's base set on `base-devel`,
`bash-completion`, `fd`, `fzf`, `git`, `zoxide` (harmless re-install); only `git-delta`
and `nano` are new. Nothing in it conflicts with an Omarchy package.

**Updating.** `omarchy-update` (snapshot, `git pull` of the Omarchy checkout, migrations,
`pacman -Syu`) is separate from `make update`, which knows nothing about Omarchy. Run both.

### Fresh-laptop checklist

After installation completes:

- **Set machine type:** `echo personal > ~/.machine_type` (or `work` / `server`).
- **Create local override files** (git-ignored, machine-specific):

  ```bash
  cp ~/.config/zsh/zshrc.local.example ~/.config/zsh/zshrc.local
  cp ~/.config/git/config.local.example ~/.config/git/config.local
  ```

- **SSH config:** drop any machine-specific snippets into `~/.config/ssh/config.d/`. `make link` ensures `~/.ssh/config` includes that directory.
- **Run health check:** `make doctor`.
- **Verify:** `make verify` should pass end-to-end.

---

## Daily operations

Commands you re-run routinely.

| Command | What it does |
| --- | --- |
| `make link` | Create/refresh all symlinks via Stow. Safe to re-run. |
| `make link-dry-run` | Preview symlink changes without applying. |
| `make doctor` | Comprehensive health check (symlinks, package managers, shell config, tool presence). |
| `make update` | Update all packages (Homebrew, npm, Cargo, Zinit plugins). |
| `make backup` | Snapshot configs + package lists. `backup-compress` / `backup-cleanup` variants exist. |
| `make bench-shell` | Benchmark interactive zsh startup against a budget (default 900ms). |
| `make daily` | Fast pre-push check: shell syntax + doc links + tests. |
| `make verify` | Full repo verification: shell syntax + stale-ref check + doc links + tests. |
| `make clean` | Remove broken symlinks in `~/.config/`. |
| `make restore [backup=/path]` | Restore the latest (or a named) `dotfiles-backup` snapshot. |
| `make help` | List every target with its one-line description. |

`make <target>` wraps the matching `bin/dotfiles-*` script, which also runs standalone
(`dotfiles-doctor --verbose`, `dotfiles-update --skip-brew`, `dotfiles-restore --dry-run`).
See `bin/README.md` for flags.

### Testing and verification

| Command | What it does |
| --- | --- |
| `make test-setup` | Install BATS if missing. |
| `make test` | Run the BATS suite (`test/test_*.bats`). |
| `make verify-shell` | Syntax-check zsh/bash files. |
| `make verify-shell-surface` | Source `.zshenv`/aliases/functions and check every alias resolves. |
| `make verify-stale-refs` | Grep for strings left over from past migrations. |
| `make verify-doc-links` | Validate local Markdown links (`bin/validate-doc-links`). |
| `make verify-tool-docs` | Check `docs/TOOLS.md` against the install manifests (`bin/validate-tool-docs`). |
| `make test-docker` / `make test-docker-arch` | Run the install in an Ubuntu / Arch container. |

### Package-level targets

`make brew-packages`, `make cask-apps`, `make node-packages`, `make rust-packages`,
`make vscode-extensions`, `make duti` (macOS file associations) and
`make pacman-packages` (Arch) each install one manifest from `install/`.
`make brew-update` / `make brew-cleanup` maintain Homebrew alone.

### Automated sync (macOS)

A LaunchAgent can `git pull` the repo daily at 10:00 and notify only when
something changed (skips silently if the tree is dirty):

```bash
make sync-install     # load .config/macos/com.dotfiles.sync.plist
make sync-status      # is it loaded?
make sync-run         # run bin/dotfiles-sync once, now
make sync-uninstall
```

### Worktree flow (parallel sessions)

For running multiple AI terminals or parallel feature work against the same repo:

```bash
make worktree-add name=<task>         # creates ../dotfiles-<task> on branch ai/<task>
make worktree-list                    # list active worktrees
make worktree-remove name=<task>      # remove worktree by name
make worktree-prune                   # clean up stale metadata
```

### Update and uninstall

```bash
cd ~/.dotfiles && git pull && make link   # or the alias: dotsup
make unlink                               # remove all symlinks
```

---

## Making changes

Canonical recipes. Follow these patterns so new content stays consistent with existing content.

### Add a new app config

```bash
mkdir -p .config/new-app
# Place config files in .config/new-app/
echo "# New App Configuration" > .config/new-app/README.md
make link
```

The `.config/new-app/README.md` should document why the config exists, any non-obvious choices, and a link to upstream docs. This is a repo-wide convention (see [Per-config README](#per-config-readme)).

### Add a Homebrew formula (CLI tool)

```bash
brew install <package>
brew bundle dump --force --file=install/Brewfile
```

### Add a Homebrew cask (GUI app)

```bash
brew install --cask <app>
brew bundle dump --force --file=install/Caskfile --cask
```

### Add an npm package

```bash
npm install -g <package>
echo '<package>' >> install/npmfile
```

### Add a Cargo package

```bash
cargo install <package>
echo '<package>' >> install/Rustfile
```

### Add a shell alias

Edit `.config/zsh/aliases.zsh` (~400 lines, organized by tool). Find the relevant section header and add the alias there. Reload with `exec zsh`.

### Swap or remove a tool

1. Remove from the install manifest (`install/Brewfile`, `install/Rustfile`, etc.).
2. Remove or replace any `.config/<old-tool>/` directory.
3. Remove its aliases from `.config/zsh/aliases.zsh`.
4. Update `.config/<new-tool>/README.md` if replacing.
5. Update the "Current state" section of this file.
6. Run `make verify`.

### Local overrides (machine-specific, not in git)

- `~/.config/zsh/zshrc.local` — extra env vars, work-only PATH entries, secrets-shaped config.
- `~/.config/git/config.local` — user name/email, signing key.
- `~/.config/ssh/config.d/*.conf` — host-specific SSH snippets (gitignored; `pi-lab.conf.example` is the template).

Templates: `.config/zsh/zshrc.local.example` and `.config/git/config.local.example`
(the `cp` commands are in the fresh-laptop checklist above).

### Machine profiles

Set `~/.machine_type` to `personal`, `work`, or `server`. On shell startup, `.config/zsh/.zshrc` reads this file into the `MACHINE_TYPE` env var (defaulting to `personal`). Use `MACHINE_TYPE` inside `zshrc.local` to conditionally load work-only tooling, set proxies, etc.

---

## Repo map

Top-level directories, one sentence each.

- **`.config/`** — XDG-compliant app configs (26 directories). Managed by Stow. Each has its own README.
- **`bin/`** — Helper scripts: platform detection, `dotfiles-doctor/update/backup/restore/bench-shell/worktree/sync/why`, and the validators `validate-doc-links`, `validate-tool-docs`, `check-alias-references`. See `bin/README.md`.
- **`install/`** — Package manifests: `Brewfile`, `Caskfile`, `npmfile`, `Rustfile`, `pacmanfile`, `Codefile` (VSCodium extensions), `duti` (macOS file associations).
- **`test/`** — BATS test suite. Run with `make test`. Pattern: `test_*.bats`, helpers in `test_helper/`.
- **`.github/`** — `CODEOWNERS` only. There is no CI; `make verify` before pushing is the gate. `.pre-commit-config.yaml` is available for local hooks (`pre-commit install`).
- **`docs/`** — `TOOLS.md` (the tool catalog) plus `superpowers/plans/` and `superpowers/specs/` for non-trivial changes.

The Stow target is `~/.config/`. The only exception is `.zshenv`, which is manually symlinked from the repo root to `~/.zshenv` because Zsh must find it in `$HOME`.

---

## Current state (primary vs backup)

Which tools are actually in use right now. Update this table when you swap tools.

| Category | Primary | Backup / transitional | Notes |
| --- | --- | --- | --- |
| Terminal | Ghostty | — | Zig-based GPU terminal |
| Multiplexer | Zellij | tmux | tmux config kept for SSH/legacy contexts |
| File manager | Yazi | — | lf has been removed |
| Shell | Zsh (+ Zinit) | — | Plugin manager: Zinit; prompt: Starship |
| VCS | Jujutsu (`jj`) + Git | Git alone | `jj git init --colocate` for hybrid repos |
| Editor | Neovim | VSCodium | VSCodium for GUI/extension-heavy work |
| Window manager | AeroSpace | — | i3-like tiling for macOS |
| Keyboard remapping | Karabiner | — | macOS |

This table replaces the stale `NEW` tag system that used to live in README.md and CLAUDE.md. "NEW" decays into a lie; "primary vs backup" only changes when you actually swap tools.

---

## Troubleshooting

### Stow symlink conflict

```
WARNING! stowing .config would cause conflicts:
  * existing target is neither a link nor a directory: ...
```

Existing file/dir at the target is blocking Stow. Back it up, then re-link:

```bash
mv ~/.config/<app> ~/.config/<app>.backup
make link
```

### `.zshenv` symlink lost

```bash
make restore-zshenv
```

### Homebrew prefix confusion

- Apple Silicon: `/opt/homebrew`
- Intel: `/usr/local`

The `bin/platform is-arm64` helper detects this. Scripts should use `$(bin/platform select /opt/homebrew /usr/local "bin/platform is-arm64")`, never hardcode.

### Shell not loading config

```bash
ls -la ~/.zshenv                          # should be a symlink into the repo
echo $ZDOTDIR                             # should be ~/.config/zsh
source ~/.zshenv && exec zsh              # reload
```

### Broken symlinks in `~/.config/`

```bash
make clean
```

### Doc link validation fails (`make verify-doc-links`)

The validator (`bin/validate-doc-links`) reports the file + line of each bad link. Fix the path or update the link target.

### Stale reference check fails (`make verify-stale-refs`)

`make verify-stale-refs` scans for strings left over from past migrations (old theme names, removed file paths, typos). When it fires, grep for the reported pattern and either update or remove it.

### `verify-shell-surface` fails with "alias references unresolved command"

The alias references a command that is not a shell builtin, not in any install manifest, and not in `test/allowlist/system-tools.txt`. The error output names the offending alias's file:line and the unresolved command. Pick one fix:

1. **Manifest the dependency.** Add the command to the appropriate `install/` file (`Brewfile` for Homebrew formulae, `Rustfile` for Cargo, `npmfile` for npm globals).
2. **Guard the alias.** Wrap with `if command -v CMD &> /dev/null; then …; fi` — appropriate when the command is optional or not available on every supported platform.
3. **Allowlist the command.** Only when the command is a base-OS tool (e.g., `osascript`, `pbcopy`) that should not be manifested. Add it to `test/allowlist/system-tools.txt` with a one-line comment.

To iterate locally without committing, run `bin/check-alias-references` directly — it prints the same output as the BATS test.

---

## Contributing and conventions

Style, testing, and PR rules. `AGENTS.md` and `CLAUDE.md` point here.

### Where things go

- `.config/<app>/` — one directory per tool; keep tool-specific changes inside it.
- `bin/` — portable helper scripts, kebab-case names (`dotfiles-update`).
- `install/` — package manifests. `test/` — BATS tests (`test_*.bats`, helpers in `test_helper/`).
- `docs/` — `TOOLS.md` (tool catalog) and `superpowers/{plans,specs}/` design documents.

### Style

Follow `.editorconfig`: UTF-8, LF, final newline, no trailing whitespace; 2-space
indent by default, 4 spaces in shell scripts, tabs in Makefiles; Markdown lines
readable (max 80 configured). Prefer portable shell — no GNU-only flags in anything
sourced on macOS (see `file_mode` in `bin/dotfiles-doctor` for the `stat` split).

### Testing

Add or update a test whenever behavior changes; regression guards live in
`test/test_regressions.bats`. Iterate with targeted runs
(`bats test/test_regressions.bats -f "theme consistency"`), then `make test`.
`make verify-shell-surface` parses and sources `.zshenv`, `aliases.zsh`, and
`functions.zsh`, asserts a sentinel alias per conditional block, and runs
`bin/check-alias-references` so every unconditional alias resolves to a known command
(fixes are under [Troubleshooting](#verify-shell-surface-fails-with-alias-references-unresolved-command)).

### Commits and pull requests

Conventional-Commit style (`feat:`, `fix:`, `chore:`, optional scope); one focused
change per commit. Branch from the default branch, keep the PR small, describe what
was done and how it was validated. Before opening or pushing:

- `make test` passes and `make verify` succeeds — there is no CI; this is the gate.
- Docs updated when behavior or commands change.
- No secrets. Machine-specific values go in local files
  (`~/.config/zsh/zshrc.local`, `~/.config/git/config.local`), never in git.

### Per-config README

Every `.config/<app>/` directory carries a `README.md`: why the app is installed and
its role (primary / backup / specialized), non-obvious choices (keybindings,
overrides, themes), and a link to upstream. Required for new configs, in the same
commit as the config.

### Tool catalog

Every package in the install manifests has an entry in [docs/TOOLS.md](docs/TOOLS.md)
saying why it is in the stack. `bin/validate-tool-docs` (part of `make verify`)
enforces this both ways — undocumented packages and stale entries fail. Update the
catalog in the commit that adds or removes a package. Browse it with `dotfiles-why`.
