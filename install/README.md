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
- **Terminals**: ghostty
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
**VSCodium/VS Code extensions** - Editor extensions.

Contains VSCodium/VS Code extension IDs for automated installation.

**Extensions include:**
- **Language Support**: Python, Rust, Go, JavaScript/TypeScript, ESLint, Prettier
- **Editor Enhancement**: Vim keybindings
- **Git Integration**: GitLens, Git Graph
- **Utilities**: EditorConfig, Error Lens, Code Spell Checker, Path Intellisense
- **Markdown**: Markdown All in One, Markdownlint
- **Themes**: One Dark Pro (Material Theme)
- **Containers**: Docker support

Install with: `make vscode-extensions`

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
npm list -g --depth=0 --parseable | \
  awk -F'/node_modules/' '{print $2}' | grep -v '^npm$' > install/npmfile
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

### To add a new Homebrew formula

1. Install it: `brew install <package>`
2. Add to Brewfile: `echo 'brew "<package>"' >> install/Brewfile`

### To add a new Homebrew cask

1. Install it: `brew install --cask <cask>`
2. Add to Caskfile: `echo 'cask "<cask>"' >> install/Caskfile`

### To add a new npm package

1. Install it: `npm install -g <package>`
2. Add to npmfile: `echo '<package>' >> install/npmfile`

### To add a new Rust package

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

## Troubleshooting

### Homebrew Installation Issues

**Problem:** `brew bundle` fails with permission errors

**Solution:**

```bash
# Fix Homebrew permissions
sudo chown -R $(whoami) /usr/local/* /opt/homebrew/*

# Or reinstall Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**Problem:** Package installation fails due to conflicts

**Solution:**

```bash
# Update Homebrew first
brew update

# Try installing specific package
brew install <package>

# Check for issues
brew doctor
```

### npm Installation Issues

**Problem:** Permission errors when installing global packages

**Solution:**

```bash
# Node comes from Homebrew (brew "node"); its global prefix is user-writable.
# Or configure npm to use a different directory
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.zshrc
```

**Problem:** Package not found or outdated

**Solution:**

```bash
# Clear npm cache
npm cache clean --force

# Update npm itself
npm install -g npm@latest
```

### Cargo Installation Issues

**Problem:** Cargo not found

**Solution:**

```bash
# Install Rust toolchain
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env
```

**Problem:** Compilation errors

**Solution:**

```bash
# Update Rust toolchain
rustup update

# Ensure build tools are installed (macOS)
xcode-select --install
```

### Platform-Specific Issues

**macOS:**

- Ensure Xcode Command Line Tools are installed: `xcode-select --install`
- Some casks require Rosetta 2 on Apple Silicon: `softwareupdate --install-rosetta`

**Linux:**

- pacmanfile is for Arch-based distributions only
- For Debian/Ubuntu, you'll need to create a separate package list
- Some Homebrew formulae may not be available on Linux

## Backup & Restore

### Creating a Backup

Before installing or updating packages, create a backup of current packages:

```bash
# Create backup directory
mkdir -p ~/dotfiles-backup/$(date +%Y%m%d)

# Backup current Homebrew packages
brew bundle dump --file=~/dotfiles-backup/$(date +%Y%m%d)/Brewfile
brew bundle dump --file=~/dotfiles-backup/$(date +%Y%m%d)/Caskfile --cask

# Backup current npm packages
npm list -g --depth=0 > ~/dotfiles-backup/$(date +%Y%m%d)/npmfile.txt

# Backup current cargo packages
cargo install --list > ~/dotfiles-backup/$(date +%Y%m%d)/Rustfile.txt
```

### Restoring from Backup

To restore packages from a backup:

```bash
# Restore Homebrew packages
brew bundle --file=~/dotfiles-backup/YYYYMMDD/Brewfile

# Restore npm packages (parse the backup file)
# Manual restoration recommended

# Restore cargo packages
# Extract package names from backup and install
```

## Platform-Specific Quirks

### macOS

**Apple Silicon (M1/M2/M3) Considerations:**

- Homebrew installs to `/opt/homebrew` instead of `/usr/local`
- Some packages may require Rosetta 2 for x86_64 binaries
- Native ARM builds are available for most packages

**Common Issues:**

- **Karabiner-Elements** requires system permissions in Security & Privacy
- **AeroSpace** requires Accessibility permissions
- **Ghostty** may require Font Book to install Nerd Fonts properly

### Linux (Arch)

**Package Manager Differences:**

- Use `pacman` instead of Homebrew for system packages
- AUR packages may need a helper like `yay` or `paru`
- Some Homebrew formulae have different names in pacman

**Considerations:**

- GUI applications (casks) won't work - use pacman equivalents
- Terminal tools generally work the same way
- Font installation differs - use pacman or manual installation

## Package Explanations

### Why These Specific Packages?

**Development:**

- **gcc, cmake, ninja** - Build systems for compiling software
- **pyenv, poetry** - Python version and dependency management
- **rust-analyzer** - Rust language server for IDE support

**Shell Enhancement:**

- **zsh-syntax-highlighting** - Syntax highlighting for Zsh
- **tmux** - Terminal multiplexer for persistent sessions
- **fzf** - Fuzzy finder for quick file/command navigation

**Text & Search:**

- **ripgrep (rg)** - Fast grep alternative written in Rust
- **fd** - Fast find alternative
- **sk** - Fuzzy finder alternative to fzf

**Media:**

- **ffmpeg** - Video/audio processing
- **yt-dlp** - YouTube video downloader (youtube-dl fork)

**Security:**

- **pass** - Password manager using GPG
- **keepassxc** - Cross-platform password manager GUI

**Communication:**

- **neomutt, msmtp, isync** - Terminal-based email client setup
- **himalaya** - Modern terminal email client

## Resources

- [Homebrew Documentation](https://docs.brew.sh/)
- [Homebrew Bundle](https://github.com/Homebrew/homebrew-bundle)
- [npm Documentation](https://docs.npmjs.com/)
- [Cargo Book](https://doc.rust-lang.org/cargo/)
- [Pacman Wiki](https://wiki.archlinux.org/title/Pacman)
- [Homebrew on Linux](https://docs.brew.sh/Homebrew-on-Linux)
