# Install Directory

This directory contains package lists for various package managers, making it easy to install all necessary tools and applications on a new system.

## Files Overview

### [Brewfile](Brewfile)
**Homebrew formulae** - Command-line tools and development packages.

Contains formulae (command-line tools) installed via [Homebrew](https://brew.sh), the package manager for macOS.

**Categories include:**
- **Development Tools**: gcc, node, python, rust-analyzer, lua-language-server
- **Version Control**: gh (GitHub CLI), git, lazygit
- **Shell & Terminal**: zsh-syntax-highlighting, tmux, fzf
- **Text Processing**: pandoc, ripgrep, fd, sk
- **Containers**: docker, docker-compose, colima
- **Language Runtimes**: deno, ghc (Haskell), zig, bun
- **Build Systems**: cmake, meson, ninja, bear
- **Python Tools**: pyenv, poetry, pipx, uv, jupyterlab
- **Media**: ffmpeg, imagemagick, yt-dlp
- **Document Tools**: zathura, mupdf, sphinx-doc, typst
- **Communication**: neomutt, msmtp, isync, himalaya
- **Utilities**: tldr, aria2, pass, timewarrior, ollama

**Taps (Third-party repositories):**
- `nikitabobko/tap` - AeroSpace window manager
- `homebrew-zathura/zathura` - Zathura document viewer
- `oven-sh/bun` - Bun JavaScript runtime

### [Caskfile](Caskfile)
**Homebrew Casks** - GUI applications for macOS.

Contains casks (graphical applications) installed via [Homebrew Cask](https://github.com/Homebrew/homebrew-cask).

**Applications include:**
- **Browsers**: firefox, brave-browser, zen, tor-browser
- **Development**: vscodium, figma, godot
- **Terminals**: kitty
- **Productivity**: obsidian, raycast, karabiner-elements
- **Security**: keepassxc, proton-drive, monero-wallet
- **Media**: audacity, obs, tidal
- **Utilities**: aerospace, balenaetcher, keycastr, spacedrive
- **Communication**: dorion (Discord client)
- **Fonts**: Nerd Fonts collection (0xproto, 3270, agave, fira-code, fontawesome)

### [npmfile](npmfile)
**Node.js packages** - Global npm packages.

Global Node.js packages installed via npm/pnpm.

**Packages include:**
- **Package Managers**: npm, pnpm, yarn
- **CLI Utilities**: @antfu/ni, fkill-cli, get-port-cli, gtop
- **Development Tools**: prettier, tsx, underscore-cli
- **Documentation**: tldr, remark-cli
- **Network**: fast-cli, local-web-server
- **Release Management**: release-it, npm-check-updates
- **Optimization**: svgo

### [Rustfile](Rustfile)
**Rust packages** - Cargo-installed tools.

Rust packages installed via [Cargo](https://doc.rust-lang.org/cargo/), Rust's package manager.

**Packages include:**
- `cargo-cache` - Manage cargo cache
- `cargo-update` - Update installed cargo packages
- `jless` - JSON viewer for the terminal
- `just` - Command runner (make alternative)

### [pacmanfile](pacmanfile)
**Arch Linux packages** - Pacman package list.

Packages for Arch Linux systems installed via [pacman](https://wiki.archlinux.org/title/Pacman).

**Packages include:**
- **Base**: base-devel, bash-completion
- **Search**: fd, fzf, zoxide
- **Version Control**: git, git-delta
- **Editor**: nano

### [Codefile](Codefile)
**VS Code extensions** - Currently empty placeholder.

This file is intended for VS Code extension installation but is currently empty. Can be populated with VS Code extension IDs for automated installation.

## Usage

### Installing Homebrew Packages

```bash
# Install formulae (command-line tools)
brew bundle --file=install/Brewfile

# Install casks (applications)
brew bundle --file=install/Caskfile
```

### Installing npm Packages

```bash
# Install global npm packages
cat install/npmfile | xargs npm install -g

# Or with pnpm
cat install/npmfile | xargs pnpm add -g
```

### Installing Rust Packages

```bash
# Install cargo packages
cat install/Rustfile | xargs -n1 cargo install
```

### Installing Arch Linux Packages

```bash
# Install pacman packages
cat install/pacmanfile | xargs sudo pacman -S --needed
```

## Maintenance

### Updating Package Lists

To update these files with currently installed packages:

**Homebrew:**
```bash
brew bundle dump --force --file=install/Brewfile
brew bundle dump --force --file=install/Caskfile --cask
```

**npm:**
```bash
npm list -g --depth=0 --parseable | awk -F'/node_modules/' '{print $2}' | grep -v '^npm$' > install/npmfile
```

**Cargo:**
```bash
cargo install --list | grep -v '^ ' | cut -d' ' -f1 > install/Rustfile
```

**Pacman:**
```bash
pacman -Qqe > install/pacmanfile
```

## Adding New Packages

### To add a new Homebrew formula:
1. Install it: `brew install <package>`
2. Add to Brewfile: `echo 'brew "<package>"' >> install/Brewfile`

### To add a new Homebrew cask:
1. Install it: `brew install --cask <cask>`
2. Add to Caskfile: `echo 'cask "<cask>"' >> install/Caskfile`

### To add a new npm package:
1. Install it: `npm install -g <package>`
2. Add to npmfile: `echo '<package>' >> install/npmfile`

### To add a new Rust package:
1. Install it: `cargo install <package>`
2. Add to Rustfile: `echo '<package>' >> install/Rustfile`

## Platform-Specific Notes

- **Brewfile/Caskfile**: macOS only (some formulae may work on Linux with Homebrew)
- **npmfile**: Cross-platform (macOS, Linux, Windows)
- **Rustfile**: Cross-platform (macOS, Linux, Windows)
- **pacmanfile**: Arch Linux and derivatives only

## Cleanup

To remove packages that are no longer in the bundle files:

```bash
# Remove Homebrew packages not in Brewfile/Caskfile
brew bundle cleanup --force

# This will uninstall any packages not listed in the files
```

## Resources

- [Homebrew Documentation](https://docs.brew.sh/)
- [Homebrew Bundle](https://github.com/Homebrew/homebrew-bundle)
- [npm Documentation](https://docs.npmjs.com/)
- [Cargo Book](https://doc.rust-lang.org/cargo/)
- [Pacman Wiki](https://wiki.archlinux.org/title/Pacman)
