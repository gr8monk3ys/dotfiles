# Makefile Documentation

Complete reference for all Makefile targets and usage patterns.

## Quick Reference

```bash
make              # Full installation (detects platform)
make doctor       # Health check
make update       # Update packages
make backup       # Backup configurations
make clean        # Remove broken symlinks
make link         # Create symlinks
make unlink       # Remove symlinks
```

## Installation Targets

### `make` or `make all`
Full installation for detected platform (macOS or Arch Linux).

**What it does:**
- Detects your platform automatically
- Runs platform-specific installation
- Installs packages and creates symlinks

**Usage:**
```bash
make
# or
make all
```

### `make macos`
Complete macOS installation.

**Includes:**
- Homebrew installation
- Core tools (bash, git, npm)
- All package managers (brew, npm, cargo)
- Symlink creation
- Default application setup (duti)
- Bun runtime

**Usage:**
```bash
make macos
```

### `make arch`
Complete Arch Linux installation.

**Includes:**
- System update via pacman
- Package installation from pacmanfile
- Symlink creation

**Usage:**
```bash
make arch
```

## Package Management Targets

### `make brew`
Install Homebrew package manager.

**Usage:**
```bash
make brew
```

### `make brew-packages`
Install Homebrew formulae from Brewfile.

**Usage:**
```bash
make brew-packages
```

### `make cask-apps`
Install Homebrew cask applications from Caskfile.

**Usage:**
```bash
make cask-apps
```

### `make node-packages`
Install global npm packages from npmfile.

**Usage:**
```bash
make node-packages
```

### `make rust-packages`
Install Cargo packages from Rustfile.

**Usage:**
```bash
make rust-packages
```

### `make vscode-extensions`
Install VSCodium extensions from Codefile.

**Usage:**
```bash
make vscode-extensions
```

### `make brew-update`
Update all Homebrew packages.

**What it does:**
- Updates Homebrew itself
- Upgrades all installed formulae and casks

**Usage:**
```bash
make brew-update
```

### `make brew-cleanup`
Clean up Homebrew cache and unused packages.

**What it does:**
- Removes old versions of packages
- Cleans Homebrew cache
- Removes packages not in Brewfile/Caskfile

**Usage:**
```bash
make brew-cleanup
```

## Symlink Management Targets

### `make link`
Create symlinks for all configurations.

**What it does:**
- Creates `~/.config/` directory
- Backs up existing `.zshenv` if it's not a symlink
- Links `.zshenv` to home directory
- Uses Stow to link all `.config/` contents
- Creates `~/.local/runtime` directory with proper permissions

**Usage:**
```bash
make link
```

**Important:** Back up your existing configs before running this!

### `make unlink`
Remove all configuration symlinks.

**What it does:**
- Removes Stow-managed symlinks from `~/.config/`
- Removes `.zshenv` symlink
- Restores `.zshenv` backup if it exists

**Usage:**
```bash
make unlink
```

### `make clean`
Remove broken symlinks.

**What it does:**
- Finds and removes broken symlinks in `~/.config/`
- Removes broken `.zshenv` symlink if present

**Usage:**
```bash
make clean
```

### `make restore`
Restore `.zshenv` from backup.

**What it does:**
- Restores `.zshenv.bak` to `.zshenv`
- Only works if backup exists

**Usage:**
```bash
make restore
```

## Utility Targets

### `make doctor`
Run system health check.

**What it checks:**
- System information and platform
- Dotfiles repository status
- Symlink integrity
- Package manager status
- Core tool availability
- Shell configuration
- File permissions

**Usage:**
```bash
make doctor

# With verbose output
bin/dotfiles-doctor --verbose
```

**Exit codes:**
- `0` - All checks passed
- `1` - Issues found

### `make update`
Update all packages and configurations.

**What it updates:**
- Dotfiles repository (git pull)
- Homebrew packages
- npm packages
- Cargo packages
- Oh My Zsh
- Tmux plugins (if TPM installed)
- Neovim plugins

**Usage:**
```bash
make update

# Skip specific updates
bin/dotfiles-update --skip-brew
bin/dotfiles-update --skip-npm
```

### `make backup`
Backup current configurations.

**What it backs up:**
- Homebrew packages (Brewfile, Caskfile)
- npm packages
- Cargo packages
- VSCode/VSCodium extensions
- Non-symlinked config files
- SSH configuration (not private keys)

**Usage:**
```bash
make backup

# With compression
make backup-compress

# With cleanup of old backups
make backup-cleanup
```

**Backup location:** `~/dotfiles-backup/YYYYMMDD_HHMMSS/`

### `make backup-compress`
Create compressed backup archive.

**Usage:**
```bash
make backup-compress
```

### `make backup-cleanup`
Remove old backups (keeps latest 5).

**Usage:**
```bash
make backup-cleanup
```

### `make test`
Run BATS test suite.

**What it tests:**
- Platform detection scripts
- bin/ utility scripts
- Package file validation

**Usage:**
```bash
make test
```

## Core Component Targets

### `make bash`
Install and configure Bash as shell.

**Usage:**
```bash
make bash
```

### `make git`
Install Git with extras.

**Usage:**
```bash
make git
```

### `make npm`
Install Node.js LTS via n.

**Usage:**
```bash
make npm
```

### `make duti`
Set default applications (macOS only).

**What it does:**
- Sets default applications for file types
- Requires duti to be installed

**Usage:**
```bash
make duti
```

### `make bun`
Install Bun JavaScript runtime.

**Usage:**
```bash
make bun
```

## Platform-Specific Targets

### `make core-macos`
Install core macOS tools.

**Includes:** Homebrew, bash, git, npm

### `make core-arch`
Update Arch Linux system.

**Includes:** `pacman -Syu`

### `make packages-macos`
Install all macOS packages.

**Includes:** brew packages, cask apps, npm packages, rust packages

### `make packages-arch`
Install all Arch Linux packages.

**Includes:** pacman packages from pacmanfile

### `make stow-macos`
Install Stow via Homebrew.

### `make stow-arch`
Install Stow via pacman.

## Variables

### Environment Variables

```makefile
DOTFILES_DIR    # Path to dotfiles repository (auto-detected)
OS              # Detected OS (macos or arch)
HOMEBREW_PREFIX # Homebrew installation path (/opt/homebrew or /usr/local)
N_PREFIX        # Node version manager prefix (~/.n)
XDG_CONFIG_HOME # XDG config directory (~/.config)
STOW_DIR        # Stow source directory (dotfiles repository)
ACCEPT_EULA     # Auto-accept EULAs (Y)
```

### Path Variables

```makefile
PATH            # Enhanced with Homebrew, dotfiles bin, and N prefix
SHELL           # Set to bash with enhanced PATH
SHELLS          # Path to shells file (/private/etc/shells)
BIN             # Homebrew bin directory
```

## Dependency Graph

```
all
├── macos
│   ├── sudo
│   ├── core-macos
│   │   ├── brew
│   │   ├── bash (depends on brew)
│   │   ├── git (depends on brew)
│   │   └── npm (depends on brew-packages)
│   ├── packages-macos
│   │   ├── brew-packages (depends on brew)
│   │   ├── cask-apps (depends on brew)
│   │   ├── node-packages (depends on npm)
│   │   └── rust-packages (depends on brew-packages)
│   ├── link (depends on stow-macos)
│   ├── duti
│   └── bun
│
└── arch
    ├── core-arch
    ├── packages-arch
    └── link (depends on stow-arch)
```

## Usage Examples

### Fresh Installation

```bash
# Clone repository
git clone https://github.com/gr8monk3ys/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Full installation
make

# Or step by step
make brew
make brew-packages
make cask-apps
make link
```

### Selective Installation

```bash
# Install only Homebrew packages
make brew-packages

# Install only npm packages
make node-packages

# Create symlinks only
make link
```

### Maintenance

```bash
# Check system health
make doctor

# Update everything
make update

# Backup before major changes
make backup-compress

# Clean up
make clean
make brew-cleanup
```

### Troubleshooting

```bash
# Check what went wrong
make doctor

# Unlink and try again
make unlink
make clean
make link

# Update packages
make brew-update
make update
```

## Advanced Usage

### Override Variables

```bash
# Use custom dotfiles directory
DOTFILES_DIR=~/my-dotfiles make link

# Use custom config directory
XDG_CONFIG_HOME=~/my-config make link
```

### CI/CD Usage

```bash
# Set GITHUB_ACTION to skip sudo prompts
GITHUB_ACTION=true make macos
```

### Dry Run

Most targets don't have a dry-run mode, but you can:

1. Review what will be installed:
   ```bash
   cat install/Brewfile
   cat install/Caskfile
   cat install/npmfile
   ```

2. Test symlink creation:
   ```bash
   # Check what would be linked
   stow -n -t ~/.config .config
   ```

## Common Issues

### Permission Errors

**Problem:** Permission denied errors

**Solution:**
```bash
# Run with sudo for initial setup
make sudo
make
```

### Symlink Conflicts

**Problem:** "File exists" errors

**Solution:**
```bash
# Backup existing configs
mv ~/.config/app ~/.config/app.backup

# Then link
make link
```

### Homebrew Issues

**Problem:** Homebrew not found or broken

**Solution:**
```bash
# Reinstall Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Check health
brew doctor
```

## Tips & Best Practices

1. **Always backup before major changes:**
   ```bash
   make backup-compress
   ```

2. **Run doctor after installation:**
   ```bash
   make doctor
   ```

3. **Keep packages updated:**
   ```bash
   make update
   make brew-cleanup
   ```

4. **Test changes in isolation:**
   ```bash
   # Unlink, make changes, re-link
   make unlink
   # ... make changes ...
   make link
   make doctor
   ```

5. **Regular maintenance:**
   ```bash
   # Weekly
   make update
   
   # Monthly
   make backup
   make brew-cleanup
   make clean
   ```

## See Also

- [README.md](README.md) - Main documentation
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guidelines
- [install/README.md](install/README.md) - Package details
- [test/README.md](test/README.md) - Testing guide
