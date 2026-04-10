# OPERATING.md

How this repo works — install, daily operations, making changes, troubleshooting.

## Who this is for

Two audiences:

- **Future-you on a fresh machine.** You have full mental context about why things are set up this way, but no muscle memory for which commands to run. This doc is your runbook.
- **AI assistants opening the repo.** You have zero context. This doc gives you orientation, current-state truth, and canonical recipes for changes.

For a public-facing overview (what this repo is and why), see [README.md](README.md). For contributing conventions and style, see [AGENTS.md](AGENTS.md).

---

## Install on a new machine

### Prerequisites (macOS only)

```bash
xcode-select --install
```

### Pick a path

| | Traditional (Homebrew) | Nix |
|---|---|---|
| Reproducibility | Partial — latest versions | Pinned via `flake.lock` |
| Rollback | Manual | Built-in (generations) |
| Cross-platform | macOS focus | Any platform |
| Learning curve | Lower | Higher |
| First-build speed | Faster | Slower (downloads everything) |

**Default recommendation:** Traditional for day-one bootstrap speed; add Nix later if you want version-pinning.

### Path A — Traditional (Homebrew)

One-liner (interactive):

```bash
curl -fsSL https://raw.githubusercontent.com/gr8monk3ys/dotfiles/main/install.sh | bash
```

Non-interactive (CI / repeatable):

```bash
DOTFILES_ASSUME_YES=1 DOTFILES_MACHINE_TYPE=personal DOTFILES_FORCE_PROMPT_STYLE=1 \
  curl -fsSL https://raw.githubusercontent.com/gr8monk3ys/dotfiles/main/install.sh | bash
```

Or clone first and run `make`:

```bash
git clone https://github.com/gr8monk3ys/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
make
```

### Path B — Nix

```bash
git clone https://github.com/gr8monk3ys/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
make nix-install     # installs Nix; restart terminal after
make nix             # applies nix-darwin on macOS
# or:
make nix-home        # applies Home Manager on any platform
```

### Fresh-laptop checklist

After either path completes:

1. **Set machine type:** `echo personal > ~/.machine_type` (or `work` / `server`).
2. **Create local override files** (git-ignored, machine-specific):
   ```bash
   cp ~/.config/zsh/zshrc.local.example ~/.config/zsh/zshrc.local
   cp ~/.config/git/config.local.example ~/.config/git/config.local
   ```
3. **SSH config:** drop any machine-specific snippets into `~/.config/ssh/config.d/`. `make link` ensures `~/.ssh/config` includes that directory.
4. **Run health check:** `make doctor`.
5. **Verify:** `make verify` should pass end-to-end.

---

## Daily operations

Commands you re-run routinely.

| Command | What it does |
|---|---|
| `make link` | Create/refresh all symlinks via Stow. Safe to re-run. |
| `make link-dry-run` | Preview symlink changes without applying. |
| `make doctor` | Comprehensive health check (symlinks, package managers, shell config, tool presence). |
| `make update` | Update all packages (Homebrew, npm, Cargo, Oh My Zsh, plugins). |
| `make backup` | Snapshot configs + package lists. `backup-compress` / `backup-cleanup` variants exist. |
| `make bench-shell` | Benchmark interactive zsh startup against a budget (default 900ms). |
| `make daily` | Fast pre-push check: shell syntax + doc links + tests. |
| `make verify` | Full repo verification: shell syntax + stale-ref check + doc links + tests + nix flake check. |
| `make clean` | Remove broken symlinks in `~/.config/`. |

### Worktree flow (parallel sessions)

For running multiple AI terminals or parallel feature work against the same repo:

```bash
make worktree-add name=<task>         # creates ../dotfiles-<task> on branch ai/<task>
make worktree-list                    # list active worktrees
make worktree-remove name=<task>      # remove worktree by name
make worktree-prune                   # clean up stale metadata
```

### Nix maintenance

```bash
make nix-update   # update flake inputs to latest
make nix          # re-apply (macOS) after updating
make nix-home     # re-apply (any platform) after updating
make nix-gc       # garbage-collect old generations
make nix-check    # validate flake without building
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

The `.config/new-app/README.md` should document why the config exists, any non-obvious choices, and a link to upstream docs. This is a repo-wide convention (see [AGENTS.md](AGENTS.md)).

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
- `~/.config/ssh/config.d/*.conf` — host-specific SSH snippets.

Both `zshrc.local.example` and `config.local.example` exist as templates.

### Machine profiles

Set `~/.machine_type` to `personal`, `work`, or `server`. On shell startup, `.config/zsh/.zshrc` reads this file into the `MACHINE_TYPE` env var (defaulting to `personal`). Use `MACHINE_TYPE` inside `zshrc.local` to conditionally load work-only tooling, set proxies, etc.

---

## Repo map

Top-level directories, one sentence each.

- **`.config/`** — XDG-compliant app configs (24 directories). Managed by Stow. Each has its own README.
- **`bin/`** — Helper scripts: platform detection, `dotfiles-doctor/update/backup/restore/bench-shell/worktree/nix`, doc-link validator. See `bin/README.md`.
- **`install/`** — Package manifests: `Brewfile`, `Caskfile`, `npmfile`, `Rustfile`, `pacmanfile`, `Codefile` (VSCodium extensions), `duti` (macOS file associations).
- **`test/`** — BATS test suite. Run with `make test`. Pattern: `test_*.bats`, helpers in `test_helper/`.
- **`nix/`** — Nix configs (`home.nix`, `darwin.nix`). Paired with `flake.nix` / `flake.lock` at repo root.
- **`.github/`** — CI workflows (`install.yml`, `test.yml`, `lint.yml`).
- **`docs/`** — Plans and specs for non-trivial changes.

The Stow target is `~/.config/`. The only exception is `.zshenv`, which is manually symlinked from the repo root to `~/.zshenv` because Zsh must find it in `$HOME`.

---

## Current state (primary vs backup)

Which tools are actually in use right now. Update this table when you swap tools.

| Category | Primary | Backup / transitional | Notes |
|---|---|---|---|
| Terminal | Ghostty | — | Zig-based GPU terminal |
| Multiplexer | Zellij | tmux | tmux config kept for SSH/legacy contexts |
| File manager | Yazi | — | lf has been removed |
| Shell | Zsh (+ Zinit) | — | Plugin manager: Zinit; prompt: Powerlevel10k |
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

### Nix `experimental-features` error

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

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

### First Nix build is extremely slow

Expected — it downloads and builds everything from scratch. Subsequent builds use the binary cache and are fast.
