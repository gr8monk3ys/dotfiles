# dotfiles

[![Installation](https://github.com/gr8monk3ys/dotfiles/workflows/Dotfiles%20Installation/badge.svg)](https://github.com/gr8monk3ys/dotfiles/actions/workflows/install.yml)
[![Tests](https://github.com/gr8monk3ys/dotfiles/workflows/Tests/badge.svg)](https://github.com/gr8monk3ys/dotfiles/actions/workflows/test.yml)
[![Lint](https://github.com/gr8monk3ys/dotfiles/workflows/Lint/badge.svg)](https://github.com/gr8monk3ys/dotfiles/actions/workflows/lint.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Personal configuration files (dotfiles) for macOS, with support for Linux systems.

## Highlights

- Comprehensive [.config](.config/) directory with detailed documentation
- Minimal installation using [Makefile](./Makefile)
- Package management via [Homebrew](https://brew.sh), npm, Cargo, and pacman
- Keyboard-driven workflow with tiling window manager (AeroSpace)
- Modern terminal setup (Kitty + Zsh + Tmux)
- Neovim configuration with LSP support
- Well-documented configurations with individual README files
- Supports both Apple Silicon (M1) and Intel Macs

## Structure

```
dotfiles/
├── .config/              # Application configurations (XDG Base Directory)
│   ├── aerospace/        # AeroSpace window manager
│   ├── curl/             # cURL defaults
│   ├── firefox/          # Firefox user preferences
│   ├── git/              # Git global config
│   ├── kitty/            # Kitty terminal
│   ├── latexmk/          # LaTeX automation
│   ├── lf/               # File manager
│   ├── macos/            # macOS-specific settings
│   ├── mpd/              # Music Player Daemon
│   ├── newsboat/         # RSS reader
│   ├── nvim/             # Neovim editor
│   ├── tmux/             # Terminal multiplexer
│   ├── wget/             # Wget defaults
│   ├── zathura/          # Document viewer
│   ├── zsh/              # Zsh shell config
│   └── .aliases          # Shell aliases
├── install/              # Package lists for various package managers
│   ├── Brewfile          # Homebrew formulae
│   ├── Caskfile          # Homebrew casks
│   ├── npmfile           # npm packages
│   ├── Rustfile          # Cargo packages
│   └── pacmanfile        # Arch Linux packages
└── Makefile              # Installation automation
```

Each directory in `.config/` contains a README with detailed information about that specific configuration.

## Key Tools

### Window Management & Desktop
- **AeroSpace** - i3-like tiling window manager for macOS
- **Karabiner-Elements** - Keyboard customization

### Terminal & Shell
- **Kitty** - GPU-accelerated terminal emulator
- **Zsh** - Enhanced shell with Oh My Zsh and Powerlevel10k
- **Tmux** - Terminal multiplexer for session management

### Development
- **Neovim** - Modern, extensible text editor
- **Git** - Version control with custom configuration
- **VSCodium** - Open-source VS Code
- **Lazygit** - Terminal UI for git

### Document & Media
- **Zathura** - Minimal document viewer with Vim keybindings
- **MPD** - Music Player Daemon
- **LaTeXmk** - LaTeX build automation

### Utilities
- **lf** - Terminal file manager
- **Newsboat** - RSS/Atom feed reader
- **fzf** - Fuzzy finder
- **ripgrep** - Fast grep alternative

## Installation

### Prerequisites

On a fresh macOS installation:

```bash
# Install Xcode Command Line Tools
xcode-select --install
```

### Clone Repository

```bash
git clone https://github.com/gr8monk3ys/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

### Install Everything

Use the Makefile to install packages and symlink configurations:

```bash
make
```

This will:
1. Install Homebrew packages from `install/Brewfile` and `install/Caskfile`
2. Install npm packages from `install/npmfile`
3. Install Rust packages from `install/Rustfile`
4. Symlink configuration files from `.config/` to `~/.config/`

### Selective Installation

You can also install specific package managers:

```bash
make brew           # Install Homebrew packages
make npm            # Install npm packages
make rust           # Install Rust packages
```

## Post-Installation

### 1. Configure Git

```bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
git config --global github.user "your-github-username"
```

### 2. Apply macOS Settings

```bash
# Configure macOS system defaults
./.config/macos/defaults.sh

# Set up Dock
./.config/macos/dock.sh

# Restart for changes to take effect
sudo shutdown -r now
```

### 3. Set Up Zsh

Install Oh My Zsh and Powerlevel10k:

```bash
# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install Powerlevel10k theme
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Configure prompt
p10k configure
```

### 4. Configure Neovim

The Neovim configuration will automatically install plugins on first launch. See [.config/nvim/README.md](.config/nvim/README.md) for details.

## Configuration Details

Each tool has its own README with detailed information:

- [.config/README.md](.config/README.md) - Overview of all configurations
- [install/README.md](install/README.md) - Package installation details

Individual tool documentation:
- [aerospace](.config/aerospace/README.md) - Window manager setup
- [kitty](.config/kitty/README.md) - Terminal configuration
- [zsh](.config/zsh/README.md) - Shell setup
- [tmux](.config/tmux/README.md) - Terminal multiplexer
- [nvim](.config/nvim/README.md) - Editor configuration
- [git](.config/git/README.md) - Version control setup
- And more in each .config subdirectory...

## Package Management

### Adding Packages

**Homebrew formula:**
```bash
brew install <package>
brew bundle dump --force --file=install/Brewfile
```

**Homebrew cask:**
```bash
brew install --cask <app>
brew bundle dump --force --file=install/Caskfile --cask
```

**npm package:**
```bash
npm install -g <package>
echo '<package>' >> install/npmfile
```

**Cargo package:**
```bash
cargo install <package>
echo '<package>' >> install/Rustfile
```

### Updating Packages

```bash
# Update Homebrew packages
brew update && brew upgrade

# Update npm packages
npm update -g

# Update Cargo packages
cargo install-update -a
```

## Customization

Fork this repository and customize to your preferences:

1. Modify configurations in `.config/`
2. Update package lists in `install/`
3. Adjust macOS settings in `.config/macos/`
4. Add your own aliases to `.config/.aliases`

## Platform Support

- **macOS**: Full support (primary target)
- **Linux**: Partial support (Arch Linux package list included)
- **Windows**: Not supported

## Maintenance

### Backup

All configurations are version controlled. To backup:

```bash
cd ~/.dotfiles
git add .
git commit -m "Update configurations"
git push
```

### Clean Up

```bash
# Remove unused Homebrew packages
brew bundle cleanup --force

# Clean Homebrew cache
brew cleanup

# Clean cargo cache
cargo cache --autoclean
```

## Troubleshooting

### Symlinks Not Working

Ensure the `.config` directory is properly linked:

```bash
ln -sf ~/.dotfiles/.config ~/.config
```

### Homebrew Installation Fails

Make sure Xcode Command Line Tools are installed:

```bash
xcode-select --install
```

### Shell Configuration Not Loading

Source the configuration manually:

```bash
source ~/.config/zsh/.zshrc
```

Or start a new shell session.

## Resources

- [Dotfiles Guide](https://dotfiles.github.io/)
- [XDG Base Directory Spec](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
- [Arch Wiki - Dotfiles](https://wiki.archlinux.org/title/Dotfiles)

## Credits

Inspired by the [dotfiles community](https://dotfiles.github.io) and various configurations from across GitHub.

## Documentation

- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Guidelines for contributing to this repository
- **[CHANGELOG.md](CHANGELOG.md)** - Version history and release notes
- **[CLAUDE.md](CLAUDE.md)** - AI assistant guide for working with this repository
- **[MAKEFILE.md](MAKEFILE.md)** - Complete Makefile reference and usage guide
- **[LICENSE](LICENSE)** - MIT License

## FAQ

### Can I use these dotfiles on my system?

Yes! Fork the repository and customize to your preferences. The dotfiles are designed to be modular - you can use only the parts you need.

### How do I update my dotfiles?

```bash
cd ~/.dotfiles
git pull
make link  # Re-create symlinks if needed
```

### How do I uninstall?

```bash
cd ~/.dotfiles
make unlink  # Remove all symlinks
```

Then manually delete the repository directory if desired.

### Can I use these on Linux?

Partial support exists for Arch Linux. See `install/pacmanfile` for the package list. Other distributions will require creating appropriate package lists.

### What if I already have configurations?

The `make link` command backs up your existing `.zshenv` automatically. For other configs in `~/.config/`, back them up manually before running `make link`.

### How do I add my own configurations?

1. Add configurations to `.config/[app-name]/`
2. Run `make link` to create symlinks
3. Update package lists in `install/` if needed
4. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines

## Troubleshooting

### Symlink creation fails

**Problem:** "File exists" errors during `make link`

**Solution:** Backup and remove existing configurations:
```bash
mv ~/.config/[app] ~/.config/[app].backup
make link
```

### Homebrew installation fails

**Problem:** Permission errors or command not found

**Solution:**
```bash
# Ensure Xcode Command Line Tools are installed
xcode-select --install

# Check Homebrew installation
brew doctor
```

### Shell configuration not loading

**Problem:** Changes to `.zshrc` not taking effect

**Solution:**
```bash
# Ensure .zshenv is properly linked
ls -la ~/.zshenv

# If not, relink
make link

# Start new shell or source
source ~/.zshenv
```

### Packages fail to install

**Problem:** npm or cargo packages fail

**Solution:**
```bash
# Ensure prerequisite packages are installed
make brew-packages  # Install Homebrew packages first
make npm           # Ensure Node.js is installed

# Try installing packages individually
npm install -g <package-name>
cargo install <package-name>
```

For more troubleshooting, see individual configuration READMEs in `.config/*/README.md`.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Take anything you want and customize to your needs!
