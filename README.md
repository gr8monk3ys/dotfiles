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

**A keyboard-driven development environment for macOS (and, partially, Linux)**

[![Tests](https://img.shields.io/github/actions/workflow/status/gr8monk3ys/dotfiles/test.yml?branch=main&label=tests&style=flat-square&logo=github)](https://github.com/gr8monk3ys/dotfiles/actions/workflows/test.yml)
[![Install](https://img.shields.io/github/actions/workflow/status/gr8monk3ys/dotfiles/install.yml?branch=main&label=install&style=flat-square&logo=github)](https://github.com/gr8monk3ys/dotfiles/actions/workflows/install.yml)
[![Lint](https://img.shields.io/github/actions/workflow/status/gr8monk3ys/dotfiles/lint.yml?branch=main&label=lint&style=flat-square&logo=github)](https://github.com/gr8monk3ys/dotfiles/actions/workflows/lint.yml)
[![License](https://img.shields.io/badge/license-GPL--3.0-98c379?style=flat-square)](LICENSE)
[![Theme](https://img.shields.io/badge/theme-OneDark-61afef?style=flat-square)](#-theme)

[Quick start](#-quick-start) •
[Features](#-features) •
[Theme](#-theme) •
[Structure](#-structure) •
[Documentation](#-documentation)

</div>

---

## ⚡ Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/gr8monk3ys/dotfiles/main/install.sh | bash
```

That installs Homebrew packages, symlinks `.config/` with Stow, and sets up
the prompt. Prefer to look first? `git clone` the repo to `~/.dotfiles`, then
`make link-dry-run` to preview and `make` to install.

Everything else — non-interactive install, machine profiles, local overrides,
the `make` command reference, and troubleshooting — lives in
**[OPERATING.md](OPERATING.md)**.

---

## ✨ Features

<table>
<tr>
<td width="50%">

### 🖥️ Window Management

- **AeroSpace** - i3-like tiling for macOS
- **SketchyBar** - Status bar
- **Karabiner** - Keyboard remapping (vim-style navigation)

### 🐚 Terminal & Shell

- **Ghostty** - GPU-accelerated terminal
- **Zsh + Zinit** - Fast plugin manager
- **Starship** - Single-binary prompt
- **Zellij** - Multiplexer (tmux config kept as backup)

### ✏️ Development

- **Neovim** - LSP-configured editor
- **Jujutsu (jj)** - Git-compatible VCS, alongside Git + delta
- **Lazygit** - Terminal Git UI
- **VSCodium** - GUI editor for extension-heavy work

</td>
<td width="50%">

### 🛠️ Modern CLI Tools

- **yazi** - Terminal file manager
- **eza** - `ls` with icons and git status
- **bat** - `cat` with syntax highlighting
- **ripgrep** / **fd** - Fast search (not aliased over `grep`/`find`)
- **zoxide** - Smarter `cd`
- **atuin** - Searchable shell history
- **dust** / **procs** / **bottom** - Disk, process and system viewers
  (`du`/`ps`/`top` are deliberately not shadowed)
- **broot**, **navi**, **ouch** - Tree search, cheatsheets, archives

### 📦 Package Management

- **Homebrew** - macOS packages and casks
- **mise** - Runtime version manager
- **Cargo** / **npm** - Rust and Node globals

</td>
</tr>
</table>

Every package has a rationale entry in [docs/TOOLS.md](docs/TOOLS.md) —
what it is, why it was chosen, and what the alternatives were. Browse it
from the terminal with `dotfiles-why` (fzf browser) or
`dotfiles-why ripgrep` (one entry). `make verify` fails if a package is
installed without a catalog entry, or documented without being installed.

---

## 🎨 Theme

A consistent **OneDark** palette across every themed tool:

| Color | Hex | Usage |
| ------- | ----- | ------- |
| 🔴 Red | `#e06c75` | Errors, deletions |
| 🟢 Green | `#98c379` | Success, additions |
| 🟡 Yellow | `#e5c07b` | Warnings, modified |
| 🔵 Blue | `#61afef` | Info, directories |
| 🟣 Magenta | `#c678dd` | Special elements |
| 🔵 Cyan | `#56b6c2` | Links, symlinks |
| 🟠 Orange | `#d19a66` | Constants |

**Themed tools:** Neovim, Yazi, bat, eza, git-delta, zellij, fzf, starship, atuin, zsh-syntax-highlighting, Ghostty (Atom One Dark, frosted glass), SketchyBar

---

## 📁 Structure

```
~/.dotfiles/
├── .config/         # 26 XDG app configs, one directory per tool, each with a README
├── bin/             # dotfiles-doctor / update / backup / restore / sync / why, validators
├── install/         # Package manifests: Brewfile, Caskfile, npmfile, Rustfile, pacmanfile, Codefile, duti
├── test/            # BATS test suite (make test)
├── docs/            # TOOLS.md tool catalog + design plans/specs
├── install.sh       # One-line installer
└── Makefile         # Install, link, verify, maintenance targets (make help)
```

---

## 📚 Documentation

| Document | Description |
| ---------- | ------------- |
| [OPERATING.md](OPERATING.md) | Install paths, daily ops, `make` reference, local overrides, troubleshooting, contributing conventions |
| [AGENTS.md](AGENTS.md) | Pointer file for agent tools (Codex, Cursor); content is in OPERATING.md |
| [docs/TOOLS.md](docs/TOOLS.md) | Why each tool is here |
| [CHANGELOG.md](CHANGELOG.md) | Version history |

Each `.config/<app>/` directory has its own README describing that config.

---

## 🙏 Credits

Inspired by the [dotfiles community](https://dotfiles.github.io) and these repos:

- [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles)
- [holman/dotfiles](https://github.com/holman/dotfiles)
- [thoughtbot/dotfiles](https://github.com/thoughtbot/dotfiles)

---

<div align="center">

Made with ☕ by [Lorenzo](https://github.com/gr8monk3ys)

</div>
