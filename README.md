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

[![Installation](https://img.shields.io/github/actions/workflow/status/gr8monk3ys/dotfiles/install.yml?label=install&style=flat-square&logo=github)](https://github.com/gr8monk3ys/dotfiles/actions/workflows/install.yml)
[![Tests](https://img.shields.io/github/actions/workflow/status/gr8monk3ys/dotfiles/test.yml?label=tests&style=flat-square&logo=github)](https://github.com/gr8monk3ys/dotfiles/actions/workflows/test.yml)
[![Lint](https://img.shields.io/github/actions/workflow/status/gr8monk3ys/dotfiles/lint.yml?label=lint&style=flat-square&logo=github)](https://github.com/gr8monk3ys/dotfiles/actions/workflows/lint.yml)
[![License](https://img.shields.io/badge/license-MIT-98c379?style=flat-square)](LICENSE)
[![Theme](https://img.shields.io/badge/theme-OneDark-61afef?style=flat-square)](#theme)

[Installation](#-quick-start) •
[Features](#-features) •
[Structure](#-structure) •
[Customization](#-customization) •
[Documentation](#-documentation)

</div>

---

## ⚡ Quick Start

**One command to rule them all:**

```bash
curl -fsSL https://raw.githubusercontent.com/gr8monk3ys/dotfiles/main/install.sh | bash
```

<details>
<summary>📋 <strong>Manual Installation</strong></summary>

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

## ✨ Features

<table>
<tr>
<td width="50%">

### 🖥️ Window Management
- **AeroSpace** - i3-like tiling for macOS
- **Karabiner** - Keyboard customization

### 🐚 Terminal & Shell
- **Kitty** - GPU-accelerated terminal
- **Zsh + Zinit** - Fast plugin manager
- **Powerlevel10k** - Beautiful prompt
- **Tmux** - Session management

### ✏️ Development
- **Neovim** - Modern editor with LSP
- **Lazygit** - Terminal Git UI
- **VSCodium** - Open-source VS Code

</td>
<td width="50%">

### 🛠️ Modern CLI Tools
- **eza** - Better `ls` with icons
- **bat** - `cat` with syntax highlighting
- **ripgrep** - Blazing fast grep
- **fd** - User-friendly find
- **zoxide** - Smarter `cd`
- **delta** - Beautiful git diffs
- **atuin** - Magical shell history

### 📦 Package Management
- **Homebrew** - macOS packages
- **mise** - Universal version manager
- **Cargo** - Rust packages
- **npm/pnpm** - Node packages

</td>
</tr>
</table>

---

## 🎨 Theme

These dotfiles use a consistent **OneDark** color scheme across all tools:

| Color | Hex | Usage |
|-------|-----|-------|
| 🔴 Red | `#e06c75` | Errors, deletions |
| 🟢 Green | `#98c379` | Success, additions |
| 🟡 Yellow | `#e5c07b` | Warnings, modified |
| 🔵 Blue | `#61afef` | Info, directories |
| 🟣 Magenta | `#c678dd` | Special elements |
| 🔵 Cyan | `#56b6c2` | Links, symlinks |
| 🟠 Orange | `#d19a66` | Constants |

**Themed tools:** Kitty, Neovim, bat, eza, git-delta, tmux, fzf

---

## 📁 Structure

```
~/.dotfiles/
├── 📁 .config/              # XDG configurations
│   ├── 📁 aerospace/        # Window manager
│   ├── 📁 bat/              # Cat replacement (OneDark)
│   ├── 📁 eza/              # Ls replacement (OneDark)
│   ├── 📁 git/              # Git + Delta config
│   ├── 📁 kitty/            # Terminal emulator
│   ├── 📁 nvim/             # Neovim editor
│   ├── 📁 tmux/             # Terminal multiplexer
│   ├── 📁 zsh/              # Shell configuration
│   └── 📄 .aliases          # Modern CLI aliases
│
├── 📁 bin/                  # Utility scripts
│   ├── 📄 dotfiles-doctor   # Health check
│   ├── 📄 dotfiles-update   # Update packages
│   ├── 📄 dotfiles-backup   # Backup configs
│   ├── 📄 dotfiles-secrets  # Secret management
│   └── 📄 dotfiles-template # Config templating
│
├── 📁 install/              # Package lists
│   ├── 📄 Brewfile          # Homebrew formulae
│   ├── 📄 Caskfile          # macOS applications
│   ├── 📄 npmfile           # Node packages
│   └── 📄 Rustfile          # Cargo packages
│
├── 📁 test/                 # BATS test suite
├── 📄 install.sh            # One-line installer
└── 📄 Makefile              # Automation
```

---

## 🔧 Commands

### Installation

| Command | Description |
|---------|-------------|
| `make` | Full installation for detected OS |
| `make link` | Create symlinks only |
| `make link-dry-run` | Preview changes |
| `make unlink` | Remove symlinks |

### Maintenance

| Command | Description |
|---------|-------------|
| `make doctor` | Health check |
| `make update` | Update all packages |
| `make backup` | Backup configurations |
| `make clean` | Remove broken symlinks |

### Testing

| Command | Description |
|---------|-------------|
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
```

### Machine Profiles

Set your machine type for conditional configs:

```bash
echo "personal" > ~/.machine_type  # or: work, server
```

### Secret Management

Encrypt sensitive files with `age`:

```bash
make secrets-init                         # Initialize encryption
dotfiles-secrets encrypt ~/.ssh/config    # Encrypt a file
dotfiles-secrets decrypt file.age         # Decrypt a file
```

### Templates

Generate configs with machine-specific values:

```bash
make template-list                        # List variables
dotfiles-template config.tmpl config      # Process template
```

Available: `{{HOSTNAME}}`, `{{OS_TYPE}}`, `{{MACHINE_TYPE}}`, `{{USER}}`

---

## 🛠️ Modern CLI Aliases

These aliases are automatically set when tools are installed:

```bash
# File listing (eza)
ls    → eza --icons --group-directories-first
ll    → eza -la --icons --git
tree  → eza --tree --icons

# File viewing (bat)
cat   → bat --paging=never

# Search (ripgrep, fd)
grep  → rg
find  → fd

# System (dust, procs, bottom)
du    → dust
ps    → procs
top   → btm

# History (atuin)
hs    → atuin search
```

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [CLAUDE.md](CLAUDE.md) | AI assistant guide |
| [MAKEFILE.md](MAKEFILE.md) | Makefile reference |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Contribution guidelines |
| [CHANGELOG.md](CHANGELOG.md) | Version history |
| [CODE_QUALITY_REPORT.md](CODE_QUALITY_REPORT.md) | Quality analysis |

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
