<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/gr8monk3ys/dotfiles/main/.github/assets/banner-dark.svg">
  <source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/gr8monk3ys/dotfiles/main/.github/assets/banner-light.svg">
  <img alt="Lorenzo's Dotfiles" src="https://raw.githubusercontent.com/gr8monk3ys/dotfiles/main/.github/assets/banner-dark.svg">
</picture>

<div align="center">

```
██╗      ██████╗ ██████╗ ███████╗███╗   ██╗███████╗ ██████╗ ███████╗
██║     ██╔═══██╗██╔══██╗██╔════╝████╗  ██║╚══███╔╝██╔═══██╗██╔════╝
██║     ██║   ██║██████╔╝█████╗  ██╔██╗ ██║  ███╔╝ ██║   ██║███████╗
██║     ██║   ██║██╔══██╗██╔══╝  ██║╚██╗██║ ███╔╝  ██║   ██║╚════██║
███████╗╚██████╔╝██║  ██║███████╗██║ ╚████║███████╗╚██████╔╝███████║
╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝╚══════╝ ╚═════╝ ╚══════╝

██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗███████╗
██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██║██║     ██╔════╝██╔════╝
██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗  ███████╗
██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║
██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗███████║
╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝
```

**A keyboard-driven development environment**

[![License](https://img.shields.io/badge/license-GPL--3.0-98c379?style=flat-square)](LICENSE)
[![Nix](https://img.shields.io/badge/Nix-Optional-5277C3?style=flat-square&logo=nixos)](flake.nix)
[![Theme](https://img.shields.io/badge/theme-OneDark-61afef?style=flat-square)](#theme)

[Installation](#-quick-start) •
[Features](#-features) •
[Structure](#-structure) •
[Customization](#-customization) •
[Documentation](#-documentation)

</div>

---

## ⚡ Quick Start

### Option 1: Traditional Installation (Homebrew-based)

```bash
curl -fsSL https://raw.githubusercontent.com/gr8monk3ys/dotfiles/main/install.sh | bash
```

Non-interactive (installs packages, links dotfiles, applies prompt style):

```bash
DOTFILES_ASSUME_YES=1 DOTFILES_MACHINE_TYPE=personal \
curl -fsSL https://raw.githubusercontent.com/gr8monk3ys/dotfiles/main/install.sh | bash
```

### Option 2: Nix Installation (Optional)

```bash
# Clone the repository
git clone https://github.com/gr8monk3ys/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Install Nix (if needed)
make nix-install

# Apply configuration (macOS)
make nix

# Or just user environment (any platform)
make nix-home
```

<details>
<summary>📋 <strong>Manual Installation (Traditional)</strong></summary>

```bash
# Clone the repository
git clone https://github.com/gr8monk3ys/dotfiles.git ~/.dotfiles

# Navigate to directory
cd ~/.dotfiles

# Run installation
make
```

</details>

<details>
<summary>🍎 <strong>Prerequisites (macOS)</strong></summary>

```bash
# Install Xcode Command Line Tools
xcode-select --install
```

</details>

---

> **Working on this repo?** If you're future-you on a new machine or an AI assistant needing to make changes, read **[OPERATING.md](OPERATING.md)** — install paths, daily commands, making changes, repo map, and troubleshooting. For conventions and style, see **[AGENTS.md](AGENTS.md)**.

---

## ✨ Features

<table>
<tr>
<td width="50%">

### 🖥️ Window Management
- **AeroSpace** - i3-like tiling for macOS
- **Karabiner** - Keyboard customization

### 🐚 Terminal & Shell
- **Ghostty** - Zig-based GPU terminal- **Zsh + Zinit** - Fast plugin manager
- **Starship** - Fast, single-binary prompt
- **Zellij** - Modern multiplexer- **Tmux** - Session management (backup)

### ✏️ Development
- **Neovim** - Modern editor with LSP
- **Jujutsu (jj)** - Next-gen Git- **Lazygit** - Terminal Git UI
- **VSCodium** - Open-source VS Code

</td>
<td width="50%">

### 🛠️ Modern CLI Tools (Rust-powered)
- **yazi** - Blazing fast file manager- **eza** - Better `ls` with icons
- **bat** - `cat` with syntax highlighting
- **ripgrep** - Blazing fast grep
- **fd** - User-friendly find
- **zoxide** - Smarter `cd`
- **delta** - Beautiful git diffs
- **atuin** - Magical shell history
- **broot** - Tree with fuzzy search- **navi** - Interactive cheatsheets- **ouch** - Universal archives
### 📦 Package Management
- **Nix Flakes** - Reproducible (optional)
- **Homebrew** - macOS packages
- **mise** - Universal version manager
- **Cargo** - Rust packages

</td>
</tr>
</table>

---

## 🎨 Theme

These dotfiles use a consistent **OneDark** color scheme across the core CLI tools, with two intentional exceptions (Ghostty and SketchyBar):

| Color | Hex | Usage |
|-------|-----|-------|
| 🔴 Red | `#e06c75` | Errors, deletions |
| 🟢 Green | `#98c379` | Success, additions |
| 🟡 Yellow | `#e5c07b` | Warnings, modified |
| 🔵 Blue | `#61afef` | Info, directories |
| 🟣 Magenta | `#c678dd` | Special elements |
| 🔵 Cyan | `#56b6c2` | Links, symlinks |
| 🟠 Orange | `#d19a66` | Constants |

**Themed tools:** Neovim, Yazi, bat, eza, git-delta, zellij, fzf, starship, atuin
**Own theme:** Ghostty (adaptive Horizon Bright / Broadcast with frosted glass),
SketchyBar (Catppuccin Mocha)

---

## 📁 Structure

```
~/.dotfiles/
├── 📁 .config/              # XDG configurations
│   ├── 📁 aerospace/        # Window manager
│   ├── 📁 ghostty/          # Terminal emulator
│   ├── 📁 yazi/             # File manager
│   ├── 📁 jj/               # Jujutsu VCS
│   ├── 📁 zellij/           # Terminal multiplexer
│   ├── 📁 git/              # Git + Delta config
│   ├── 📁 nvim/             # Neovim editor
│   ├── 📁 tmux/             # Tmux (backup)
│   ├── 📁 zsh/              # Shell configuration
│   │   └── 📄 aliases.zsh   # Modern CLI aliases
│
├── 📁 nix/                  # Nix configuration
│   ├── 📄 home.nix          # Home Manager config
│   └── 📄 darwin.nix        # macOS system config
│
├── 📁 bin/                  # Utility scripts
│   ├── 📄 dotfiles-doctor   # Health check
│   ├── 📄 dotfiles-update   # Update packages
│   └── 📄 dotfiles-backup   # Backup configs
│
├── 📁 install/              # Package lists
│   ├── 📄 Brewfile          # Homebrew formulae
│   ├── 📄 Caskfile          # macOS applications
│   └── 📄 Rustfile          # Cargo packages
│
├── 📁 test/                 # BATS test suite
├── 📁 docs/                 # TOOLS.md tool catalog + plans
├── 📄 flake.nix             # Nix flake
├── 📄 install.sh            # One-line installer
└── 📄 Makefile              # Automation
```

### 🔎 Why is that tool here?

Every package has a rationale entry in [docs/TOOLS.md](docs/TOOLS.md) —
what it is, why it was chosen, and what the alternatives were. Browse it
from the terminal:

```bash
dotfiles-why            # fzf browser with live preview
dotfiles-why ripgrep    # print one tool's entry
```

`make verify` keeps the catalog honest: adding a package without
documenting it (or documenting a tool that is no longer installed) fails
verification.

---

## 🔧 Commands

### Traditional Installation (Homebrew)

| Command | Description |
|---------|-------------|
| `make` | Full installation for detected OS |
| `make link` | Create symlinks only |
| `make link-dry-run` | Preview changes |
| `make unlink` | Remove symlinks |

### Nix Installation (Reproducible)

| Command | Description |
|---------|-------------|
| `make nix-install` | Install Nix package manager |
| `make nix` | Apply full nix-darwin config (macOS) |
| `make nix-home` | Apply Home Manager config (any platform) |
| `make nix-update` | Update flake inputs |
| `make nix-gc` | Garbage collect Nix store |

### Maintenance

| Command | Description |
|---------|-------------|
| `make doctor` | Health check |
| `make update` | Update all packages |
| `make backup` | Backup configurations |
| `make restore [backup=/path]` | Restore latest/specified backup snapshot |
| `make bench-shell [runs=7] [budget=900]` | Enforce shell startup performance budget |
| `make daily` | Run core pre-push checks (shell, docs, tests) |
| `make worktree-add name=<task>` | Create isolated worktree (`ai/<task>`) for parallel sessions |
| `make worktree-list` | List active worktrees |
| `make worktree-remove name=<task>` | Remove a worktree by task name |
| `make clean` | Remove broken symlinks |
| `make verify` | Run full repository verification |
| `make help` | Show all available commands |

### Testing

| Command | Description |
|---------|-------------|
| `make test-setup` | Install BATS if missing |
| `make test` | Run BATS tests |
| `make test-docker` | Test in Ubuntu container |
| `make test-docker-arch` | Test in Arch container |

---

## 🎛️ Customization

### Local Overrides

Machine-specific settings that won't be committed:

```bash
# Zsh customizations
cp ~/.config/zsh/zshrc.local.example ~/.config/zsh/zshrc.local

# Git customizations (name, email, signing key)
cp ~/.config/git/config.local.example ~/.config/git/config.local

# SSH snippets are managed under ~/.config/ssh/config.d/
# make link will ensure ~/.ssh/config includes that directory
```

### Machine Profiles

Set your machine type for conditional configs:

```bash
echo "personal" > ~/.machine_type  # or: work, server
```

---

## 🛠️ Modern CLI Aliases

These aliases are automatically set when tools are installed:

```bash
# File manager (yazi)
y     → yazi (with cd-on-exit)
fm    → yazi

# File listing (eza)
ls    → eza --icons --group-directories-first
ll    → eza -la --icons --git
tree  → eza --tree --icons

# File viewing (bat)
cat   → bat --paging=never

# Search (use rg and fd directly — they are not aliased over grep/find)
rgi   → rg -i (case-insensitive ripgrep)

# System (dust, procs, bottom — du/ps/top are deliberately NOT shadowed)
dus   → dust -s
psa   → procs -a
pst   → procs --tree
htop  → btm

# Jujutsu (next-gen git)
j     → jj
js    → jj status
jl    → jj log

# Terminal multiplexer (zellij)
zj    → zellij
zja   → zellij attach

# Cheatsheets (navi)
cheat → navi

# Archives (ouch)
extract   → ouch decompress
compress  → ouch compress

# History (atuin)
hs    → atuin search
```

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [OPERATING.md](OPERATING.md) | Install, daily ops, making changes, troubleshooting |
| [AGENTS.md](AGENTS.md) | Conventions, style, testing, PR checklist |
| [CHANGELOG.md](CHANGELOG.md) | Version history |

Each `.config/` directory has its own README with detailed documentation.

---

## ❓ FAQ

<details>
<summary><strong>Can I use these dotfiles?</strong></summary>

Yes! Fork the repo and customize. The dotfiles are modular—use only what you need.

</details>

<details>
<summary><strong>How do I update?</strong></summary>

```bash
cd ~/.dotfiles && git pull && make link
# Or use the alias:
dotsup
```

</details>

<details>
<summary><strong>How do I uninstall?</strong></summary>

```bash
cd ~/.dotfiles
make unlink
```

</details>

<details>
<summary><strong>What about existing configs?</strong></summary>

The installer backs up `.zshenv` automatically. For other configs, back them up manually:

```bash
mv ~/.config/nvim ~/.config/nvim.backup
make link
```

</details>

<details>
<summary><strong>Linux support?</strong></summary>

Partial support for Arch Linux. See `install/pacmanfile`. Other distros need custom package lists.

With Nix, you get full Linux support:
```bash
make nix-home  # Works on any Linux distro
```

</details>

<details>
<summary><strong>What's the difference between traditional and Nix installation?</strong></summary>

| Aspect | Traditional | Nix |
|--------|------------|-----|
| Reproducibility | Partial | Pinned versions |
| Rollback | Manual | Built-in |
| Cross-platform | macOS focus | Any platform |
| Package versions | Latest | Locked |
| Complexity | Simpler | Steeper learning curve |

**Recommendation:** Start with traditional (`make`). Nix is optional for users who want pinned reproducibility.

</details>

<details>
<summary><strong>How do I switch from lf to yazi?</strong></summary>

Yazi is pre-configured. Just use the `y` alias:
```bash
y           # Opens yazi with cd-on-exit
```

The lf configuration has been removed; yazi is the sole file manager.

</details>

<details>
<summary><strong>How do I use Jujutsu alongside Git?</strong></summary>

Jujutsu is Git-compatible and can coexist:
```bash
# In a git repo, initialize jj
jj git init --colocate

# Use jj commands (git still works)
jj status
jj log
git status  # Still works!
```

</details>

---

## 🐛 Troubleshooting

<details>
<summary><strong>Symlink creation fails</strong></summary>

```bash
# Backup existing config
mv ~/.config/[app] ~/.config/[app].backup
make link
```

</details>

<details>
<summary><strong>Shell config not loading</strong></summary>

```bash
# Verify symlink
ls -la ~/.zshenv

# Reload shell
source ~/.zshenv
exec zsh
```

</details>

<details>
<summary><strong>Homebrew issues</strong></summary>

```bash
# Ensure Xcode tools installed
xcode-select --install

# Run diagnostics
brew doctor
```

</details>

---

## 🙏 Credits

Inspired by the [dotfiles community](https://dotfiles.github.io) and these amazing repos:

- [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles)
- [holman/dotfiles](https://github.com/holman/dotfiles)
- [thoughtbot/dotfiles](https://github.com/thoughtbot/dotfiles)

---

<div align="center">

**[⬆ Back to Top](#)**

Made with ☕ by [Lorenzo](https://github.com/gr8monk3ys)

</div>
