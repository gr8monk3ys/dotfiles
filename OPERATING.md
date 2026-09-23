# OPERATING.md

How this repo works — install, daily operations, making changes, troubleshooting.

## Who this is for

Two audiences:

- **Future-you on a fresh machine.** You have full mental context about why things are set up this way, but no muscle memory for which commands to run. This doc is your runbook.
- **AI assistants opening the repo.** You have zero context. This doc gives you orientation, current-state truth, and canonical recipes for changes.

For a public-facing overview (what this repo is and why), see [README.md](README.md). Contributing conventions and style are at the end of this file: [Contributing and conventions](#contributing-and-conventions). `CLAUDE.md` is a short fact sheet for agent tools.

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
so the install path is `make arch`: `pacman -Syu` (through `sudo` unless already root),
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
`.zshenv` sets `STARSHIP_CONFIG` to `~/.config/starship/starship.toml`, so zsh uses ours.

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
`pacman -Syu`) is separate from `make update`, which knows nothing about Omarchy.
`make update` runs `pacman -Syu` too, as the pacman kind's update, but without
Omarchy's snapshot and migrations; on Omarchy run `omarchy-update`, then
`make update SKIP_KINDS=pacman`.

### Fresh-laptop checklist

After installation completes:

- **Set machine type:** `echo personal > ~/.machine_type` (or `work` / `server`).
- **Configure identity:** `make init`. It creates the git-ignored
  `~/.config/git/config.local` and `~/.config/jj/conf.d/user.toml` from their
  templates, prompting for name and email. It is safe to re-run and never
  rewrites a file that already exists. For a scripted setup, pass the values
  instead of being prompted:

  ```bash
  make init GIT_USER_NAME="Your Name" GIT_USER_EMAIL=you@example.com
  make init check=1   # report what is still unconfigured; non-zero if any
  ```

- **Shell overrides** (optional): `cp ~/.config/zsh/zshrc.local.example ~/.config/zsh/zshrc.local`.
- **SSH config:** drop any machine-specific snippets into `~/.config/ssh/config.d/`. `make link` ensures `~/.ssh/config` includes that directory.
- **Run health check:** `make doctor`. Its Local Configuration section reports the same thing `make init check=1` does.
- **Verify:** `make verify` should pass end-to-end.

---

## Daily operations

Commands you re-run routinely.

| Command | What it does |
| --- | --- |
| `make link` | Create/refresh all symlinks via Stow. Safe to re-run. |
| `make link-dry-run` | Preview symlink changes without applying. |
| `make init` | Create the git-ignored identity files (git, jj). Safe to re-run; never overwrites. |
| `make doctor` | Comprehensive health check (symlinks, package managers, shell config, local config, tool presence). |
| `make update` | Update every manifest kind (Homebrew, casks, npm, Cargo, pacman, editor extensions), then Zinit and Neovim plugins. |
| `make backup` | Snapshot configs + package lists. `backup-compress` / `backup-cleanup` variants exist. |
| `make bench-shell` | Benchmark interactive zsh startup against a budget (default 900ms). |
| `make daily` | Fast pre-push check: doc links + tests. |
| `make verify` | The pre-push gate; see [Testing and verification](#testing-and-verification). |
| `make clean` | Remove broken symlinks in `~/.config/`. |
| `make restore [backup=/path]` | Restore the latest (or a named) `dotfiles-backup` snapshot. |
| `make help` | Every public target, one line each. |

`make <target>` wraps the matching `bin/dotfiles-*` script, which also runs standalone
(`dotfiles-doctor --verbose`, `dotfiles-update --skip brew`, `dotfiles-restore --dry-run`).
Every script answers `--help`; [bin/README.md](bin/README.md) is the index.

### Testing and verification

`make verify` is the gate: run it before pushing. It is three parts, each
runnable alone:

| Command | What it does |
| --- | --- |
| `make lint` | shellcheck over `bin/`, markdownlint, the stale-reference grep, `bin/palette check`, and the doc-link validator. No bats, no packages. |
| `make test` | The BATS suite (`bats test`). `make test-setup` installs its prerequisites: bats, bats-support, bats-assert, zsh, stow. |
| `make verify-docker` | `make test-docker` (Ubuntu: `make`, which only links there) and `make test-docker-arch` (Arch: `make arch` with the whole pacmanfile), each followed by the suite and doctor in a clean container. Skipped with a warning when Docker is not reachable. |

`SKIP_DOCKER=1` skips both containers and `SKIP_ARCH_DOCKER=1` only the Arch
one, which runs under amd64 emulation on Apple Silicon and takes about 25
minutes. `SKIP_LINTERS=1` skips shellcheck and markdownlint; a missing linter
is a warning locally and a failure under CI. Each part of `lint` is also its
own `verify-*` target (`make help`). `make daily` is doc links and the suite
only.

`make verify-config-live` is not in the gate: it asks each installed tool
whether it reads its tracked config, which needs a linked machine and a login
shell's environment. Run it after `make link` or when a tool misbehaves.

CI (`.github/workflows/ci.yml`) runs the same targets, each once: `make lint`;
`make test-setup` and `make test` plus a link/unlink round-trip on macOS and
Ubuntu; `make test-docker` and `make test-docker-arch`; the `curl | bash`
installer; and a bare `make` on fresh macOS 15 and Ubuntu runners. How to write
a test is in [test/README.md](test/README.md).

### Package-level targets

`make brew-packages`, `make cask-apps`, `make node-packages`, `make rust-packages`,
`make vscode-extensions`, `make duti` (macOS file associations) and
`make pacman-packages` (Arch) each install one manifest from `install/`
([install/README.md](install/README.md) has which is which).
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

If the config carries colours, put a template under
`.config/palette/templates/` instead of typing hexes and run `bin/palette
render` ([.config/palette/README.md](.config/palette/README.md)).

If the app writes its own files into its config directory (caches, generated
defaults, saved state), add it to `TOOL_OWNED` in `bin/link` with the write that
justifies it, so it is linked unfolded and those files stay out of the repo.

The `.config/new-app/README.md` follows [Per-config README](#per-config-readme).

### Add or remove a package

Edit the manifest line, rationale included, and run that kind's `make`
target. [install/README.md](install/README.md) has the entry format and the
two commands never to run against a manifest.

### Add a shell alias

Edit `.config/zsh/aliases.zsh` (organized by tool). Find the relevant section header and add the alias there. Reload with `exec zsh`.

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
- `~/.config/jj/conf.d/user.toml` — jj name/email.
- `~/.config/ssh/config.d/*.conf` — host-specific SSH snippets (gitignored; `pi-lab.conf.example` is the template).

Each has a tracked template beside it (`zshrc.local.example`,
`config.local.example`, `user.toml.example`, `pi-lab.conf.example`).
`make init` writes the two identity files from theirs; the other two are a
`cp` away. `make init check=1` and `make doctor` both report which are missing.

### Machine profiles

Set `~/.machine_type` to `personal`, `work`, or `server`. On shell startup, `.config/zsh/.zshrc` reads this file into the `MACHINE_TYPE` env var (defaulting to `personal`). Use `MACHINE_TYPE` inside `zshrc.local` to conditionally load work-only tooling, set proxies, etc.

---

## Repo map

Top-level directories, one sentence each.

- **`.config/`** — one directory per tool, linked by Stow. Each has its own README. `.config/palette/` holds the colours and the templates every themed file is rendered from.
- **`bin/`** — the scripts `make` wraps, plus the modules they share. Index: [bin/README.md](bin/README.md).
- **`install/`** — package manifests, one per package manager, and `duti`. See [install/README.md](install/README.md).
- **`test/`** — the BATS suite, one `test_<module>.bats` per module, and `test/Dockerfile` for the container runs. See [test/README.md](test/README.md).
- **`.github/`** — `workflows/ci.yml` (see [Testing and verification](#testing-and-verification)) and `dependabot.yml`.
- **`docs/`** — `agents/`: notes the engineering skills read.

The Stow target is `~/.config/`. The only exception is `.zshenv`, which `bin/link` symlinks from the repo root to `~/.zshenv` because Zsh must find it in `$HOME`.

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
make link     # relinks it; a real ~/.zshenv in the way is moved to ~/.zshenv.bak
make unlink   # the reverse: removes the links and restores ~/.zshenv.bak
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

### Palette check fails (`make verify-palette`)

A rendered file differs from what its template produces. If you edited
`.config/palette/danse.conf` or a template, run `bin/palette render` and
commit the result. If you edited the rendered file itself, move the change
into its template under `.config/palette/templates/` and render; the
rendered copy is overwritten on the next render.

### Alias check fails with "alias references unresolved command"

The alias references a command that is not a shell builtin, not in any install manifest, and not in `test/allowlist/system-tools.txt`. The error output names the offending alias's file:line and the unresolved command. Pick one fix:

1. **Manifest the dependency.** Add the command to the appropriate `install/` file (`Brewfile` for Homebrew formulae, `Rustfile` for Cargo, `npmfile` for npm globals).
2. **Guard the alias.** Wrap with `if command -v CMD &> /dev/null; then …; fi` — appropriate when the command is optional or not available on every supported platform.
3. **Allowlist the command.** Only when the command is a base-OS tool (e.g., `osascript`, `pbcopy`) that should not be manifested. Add it to `test/allowlist/system-tools.txt` with a one-line comment.

To iterate locally without committing, run `bin/check-alias-references` directly — it prints the same output as the BATS test.

---

## Contributing and conventions

Style, testing, and PR rules. `CLAUDE.md` points here.

### Where things go

- `.config/<app>/` — one directory per tool; keep tool-specific changes inside it.
- `bin/` — portable helper scripts, kebab-case names (`dotfiles-update`).
- `install/` — package manifests. `test/` — BATS tests (`test_*.bats`, helpers in `test_helper/`).

### Style

Follow `.editorconfig`: UTF-8, LF, final newline, no trailing whitespace; 2-space
indent by default, 4 spaces in shell scripts, tabs in Makefiles; Markdown lines
readable (max 80 configured). Prefer portable shell — no GNU-only flags in anything
sourced on macOS (OS differences go behind `bin/platform`, e.g. `platform file-mode` for the `stat` split).

### Testing

Add or update a test whenever behavior changes, in the `test_*.bats` file of
the module it guards; conventions are in [test/README.md](test/README.md).
Iterate with targeted runs (`bats test/test_link.bats -f "dry-run"`), then
`make test`.

### Commits and pull requests

Conventional-Commit style (`feat:`, `fix:`, `chore:`, optional scope); one focused
change per commit. Branch from the default branch, keep the PR small, describe what
was done and how it was validated. Before opening or pushing:

- `make test` passes and `make verify` succeeds locally; CI re-runs the same checks on the PR.
- Docs updated when behavior or commands change.
- No secrets. Machine-specific values go in local files
  (`~/.config/zsh/zshrc.local`, `~/.config/git/config.local`), never in git.

### Per-config README

Every `.config/<app>/` directory carries a `README.md`, written in the same
commit as the config: what the tool is and its role (primary, backup,
specialized), why these choices, gotchas, and platform notes. It does not
restate the config line by line or list keybindings the config file already
shows; the config is the reference for what is set.

### Package rationale

Every package says why it is in the stack in the comment on its own manifest
line ([install/README.md](install/README.md) § Entry format), and `make test`
fails on one that does not. Browse them with `dotfiles-why`.
