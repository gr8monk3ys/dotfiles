# CLAUDE.md - AI Assistant Guide

This document provides context for AI assistants (like Claude) working with this dotfiles repository. It explains the structure, conventions, and important details to help you understand and modify the codebase effectively.

## Project Overview

**Type:** Personal dotfiles repository
**Primary Platform:** macOS (with partial Linux/Arch support)
**Purpose:** Manage personal configuration files and automate system setup
**Management Style:** Symlink-based using GNU Stow
**Package Managers:** Homebrew, npm, Cargo, pacman

## Quick Reference

### Key Files
- **Makefile** - Main automation script for installation and linking
- **.zshenv** - Root-level Zsh environment file (linked to home directory)
- **.config/** - XDG Base Directory compliant configurations (managed by Stow)
- **install/** - Package lists for various package managers
- **bin/** - Utility scripts for platform detection and helpers

### Important Paths
- Working Directory: Repository root (e.g., `~/.dotfiles`)
- Config Target: `~/.config/` (XDG_CONFIG_HOME)
- Zsh Env: `~/.zshenv` (symlinked from repo root)
- Homebrew: `/opt/homebrew` (Apple Silicon) or `/usr/local` (Intel)

## Repository Structure

```
dotfiles/
├── .config/              # Application configurations (Stow managed)
│   ├── aerospace/        # AeroSpace tiling window manager
│   ├── curl/             # cURL defaults
│   ├── firefox/          # Firefox user.js preferences
│   ├── git/              # Git configuration
│   ├── kitty/            # Kitty terminal emulator
│   ├── latexmk/          # LaTeX build automation
│   ├── lf/               # Terminal file manager
│   ├── macos/            # macOS system defaults and dock scripts
│   ├── mpd/              # Music Player Daemon
│   ├── newsboat/         # RSS feed reader
│   ├── nvim/             # Neovim editor
│   ├── tmux/             # Terminal multiplexer
│   ├── wget/             # Wget defaults
│   ├── zathura/          # Document viewer
│   ├── zsh/              # Zsh shell configuration
│   ├── .aliases          # Shell aliases
│   └── README.md         # Overview of configurations (All 15 dirs have READMEs)
│
├── install/              # Package management (All files fully documented)
│   ├── Brewfile          # Homebrew formulae - 110+ packages with categories
│   ├── Caskfile          # Homebrew casks - 32 apps with categories
│   ├── Codefile          # VSCodium extensions - categorized and documented
│   ├── npmfile           # npm packages - 18 packages with categories
│   ├── Rustfile          # Cargo packages - 4 core + 12 optional tools
│   ├── pacmanfile        # Arch Linux packages
│   ├── duti              # Default application associations
│   └── README.md         # Comprehensive package installation guide
│
├── bin/                  # Utility scripts
│   ├── is-arch           # Detect Arch Linux
│   ├── is-arm64          # Detect ARM64 architecture
│   ├── is-executable     # Check if command exists
│   ├── is-macos          # Detect macOS
│   ├── is-supported      # Execute command if available
│   ├── dotfiles-doctor   # Health check script (--help, --verbose)
│   ├── dotfiles-update   # Update all packages (--help, skip options)
│   ├── dotfiles-backup   # Backup configurations (--help, --compress, --cleanup)
│   └── README.md         # Script documentation
│
├── test/                 # BATS testing framework
│   ├── test_platform.bats     # Platform detection tests
│   ├── test_bin_scripts.bats  # Script validation tests
│   ├── test_packages.bats     # Package file validation
│   ├── test_helper/
│   │   └── common.bash        # Test helper functions
│   └── README.md              # Testing documentation
│
├── .github/              # GitHub Actions workflows
│   ├── workflows/
│   │   ├── install.yml   # Installation testing
│   │   ├── test.yml      # BATS tests
│   │   └── lint.yml      # Linting workflow
│   └── README.md         # CI/CD documentation
│
├── .editorconfig         # Editor configuration (20+ file types)
├── .gitattributes        # Git line endings and language detection
├── .gitignore            # Git ignore patterns
├── .shellcheckrc         # ShellCheck linting configuration
├── .pre-commit-config.yaml   # Pre-commit hooks
├── .zshenv               # Root-level Zsh environment (linked to ~/)
├── Makefile              # Installation and linking automation
├── MAKEFILE.md           # Comprehensive Makefile documentation
├── README.md             # User-facing documentation (with CI badges, FAQ)
├── TODO.md               # Project roadmap (26+ completed tasks)
├── CLAUDE.md             # This file (AI assistant guide)
├── CONTRIBUTING.md       # Contribution guidelines
├── CHANGELOG.md          # Version history (Keep a Changelog format)
└── LICENSE               # MIT License
```

## Critical Concepts

### 1. Symlink Management with Stow

The repository uses GNU Stow to create symlinks:
- **Stow Directory:** Repository root (`STOW_DIR`)
- **Target Directory:** `~/.config/` for everything in `.config/`
- **Special Case:** `.zshenv` is manually symlinked from repo root to `~/`

**How it works:**
```bash
# Stow creates symlinks like:
# ~/.config/zsh/ -> ~/.dotfiles/.config/zsh/
stow -t ~/.config .config
```

**Important:** When adding new configs, place them in `.config/[app-name]/` so Stow can manage them.

### 2. Platform Detection

The `bin/` scripts handle platform-specific logic:
- `is-macos` - Returns 0 if macOS, 1 otherwise
- `is-arch` - Returns 0 if Arch Linux, 1 otherwise
- `is-arm64` - Returns 0 if ARM64/Apple Silicon, 1 otherwise
- `is-supported` - Executes command only if it exists
- `is-executable` - Checks if a command is available

**Usage in Makefile:**
```makefile
OS := $(shell bin/is-supported bin/is-macos macos $(shell bin/is-supported bin/is-arch arch linux))
HOMEBREW_PREFIX := $(shell bin/is-supported bin/is-arm64 /opt/homebrew /usr/local)
```

### 3. Makefile Targets

**Primary targets:**
- `make` or `make all` - Full installation for detected OS
- `make macos` - macOS-specific installation
- `make arch` - Arch Linux-specific installation
- `make link` - Create symlinks only
- `make unlink` - Remove symlinks

**Component targets:**
- `make brew` - Install Homebrew
- `make packages-macos` - Install all macOS packages
- `make brew-packages` - Install Homebrew formulae
- `make cask-apps` - Install Homebrew casks
- `make node-packages` - Install npm packages
- `make rust-packages` - Install Cargo packages
- `make vscode-extensions` - Install VSCodium extensions
- `make duti` - Set default applications
- `make bun` - Install Bun runtime

**Utility targets:**
- `make doctor` - Run comprehensive health check
- `make update` - Update all packages and configurations
- `make backup` - Backup configurations and packages
- `make backup-compress` - Create compressed backup
- `make backup-cleanup` - Remove old backups (keep latest 5)
- `make clean` - Remove broken symlinks
- `make restore` - Restore .zshenv from backup
- `make brew-update` - Update Homebrew packages
- `make brew-cleanup` - Clean Homebrew cache
- `make test` - Run BATS test suite

**See MAKEFILE.md for complete documentation with examples and dependency graph.**

### 4. XDG Base Directory Specification

This repo follows XDG conventions:
- **XDG_CONFIG_HOME:** `~/.config/` (configuration files)
- **XDG_CACHE_HOME:** `~/.cache/` (cache data)
- **XDG_DATA_HOME:** `~/.local/share/` (data files)
- **XDG_STATE_HOME:** `~/.local/state/` (state data)
- **XDG_RUNTIME_DIR:** `~/.local/runtime/` (runtime files)

Applications are configured to use these directories where possible.

### 5. Shell Configuration

**Zsh Loading Order:**
1. `.zshenv` (sourced for all shells, linked from repo root)
2. `.zprofile` (login shells)
3. `.zshrc` (interactive shells, located in `.config/zsh/.zshrc`)

**Key Variables in .zshenv:**
- Sets `ZDOTDIR=~/.config/zsh` to move Zsh config to XDG location
- Other environment variables are set in `.config/zsh/`

## Common Tasks

### Adding a New Configuration

1. **Create directory structure:**
   ```bash
   mkdir -p .config/new-app
   ```

2. **Add configuration files:**
   ```bash
   # Place config files in .config/new-app/
   echo "config content" > .config/new-app/config.conf
   ```

3. **Create README (recommended):**
   ```bash
   echo "# New App Configuration" > .config/new-app/README.md
   ```

4. **Stow will automatically link it:**
   ```bash
   make link
   ```

### Adding Packages

**Homebrew formula (CLI tool):**
```bash
brew install package-name
brew bundle dump --force --file=install/Brewfile
```

**Homebrew cask (GUI app):**
```bash
brew install --cask app-name
brew bundle dump --force --file=install/Caskfile --cask
```

**npm package:**
```bash
npm install -g package-name
echo 'package-name' >> install/npmfile
```

**Cargo package:**
```bash
cargo install package-name
echo 'package-name' >> install/Rustfile
```

### Modifying the Makefile

**Things to know:**
- Uses bash (not sh)
- PATH includes: Homebrew, dotfiles bin/, Node n prefix
- Platform-specific logic via `$(OS)` variable
- Homebrew prefix varies: `/opt/homebrew` (ARM) or `/usr/local` (Intel)
- `GITHUB_ACTION` environment variable skips interactive prompts in CI

**Pattern for new targets:**
```makefile
target-name: dependencies
	@echo "Doing something..."
	command-here
```

## Important Conventions

### File Organization
- **All configs** go in `.config/[app-name]/`
- **Package lists** go in `install/`
- **Utility scripts** go in `bin/`
- **Documentation** at each level (README.md in directories)

### Documentation Standards
- Each `.config/[app-name]/` should have a README.md
- Document complex configurations
- Explain non-obvious choices
- Include installation instructions if special steps needed

### Package File Format
- **Brewfile/Caskfile:** Generated by `brew bundle dump`
- **npmfile/Rustfile/pacmanfile:** One package per line
- **Codefile:** One VS Code extension ID per line
- **duti:** Format is `bundle_id UTI role`

### Error Handling in Makefile
- Use `|| true` to continue on errors when appropriate
- Use `@if command -v tool >/dev/null 2>&1` to check for tools
- Provide helpful error messages for missing dependencies

## Watch Out For

### 1. Symlink Conflicts
- **Problem:** Existing files/dirs at `~/.config/[name]/` block Stow
- **Solution:** Backup existing configs before running `make link`
- **Makefile handles:** `.zshenv` backup automatically

### 2. Homebrew Prefix
- Apple Silicon uses `/opt/homebrew`
- Intel Macs use `/usr/local`
- Scripts use `is-arm64` to detect and set correctly

### 3. Stow Behavior
- Stow creates symlinks at the **file/directory level**
- If `.config/app/` exists (not as symlink), Stow will try to merge
- Clean existing configs before Stow to avoid conflicts

### 4. Shell Initialization
- `.zshenv` must be in home directory (not in `.config/`)
- Sets `ZDOTDIR` to point to `.config/zsh/`
- Don't move `.zshenv` into `.config/` - Zsh won't find it

### 5. Package Installation Order
- Core packages must install first (brew, git, npm)
- Some packages depend on others (npm needs Node)
- Makefile handles order via target dependencies

### 6. Platform-Specific Code
- Check which platform before using platform-specific commands
- Use `bin/is-supported` wrapper for commands that may not exist
- Test changes on target platform if possible

### 7. Empty Package Files
- `Codefile` is currently empty (VSCode extensions)
- Either populate or remove reference in Makefile
- Don't leave empty files if they're not used

## Working with This Repo as an AI

### When Reading Code
1. Check platform-specific logic (is-macos, is-arch, etc.)
2. Understand Stow's symlink behavior
3. Know what directories are managed vs manual
4. Check Makefile dependencies between targets

### When Suggesting Changes
1. **Maintain symlink structure** - Keep configs in `.config/`
2. **Follow XDG conventions** - Don't put configs in home directory
3. **Test platform detection** - Use existing `bin/` scripts
4. **Update documentation** - Add/update READMEs for changes
5. **Consider package order** - Some packages depend on others
6. **Check Stow compatibility** - Ensure symlink approach works

### When Creating New Features
1. **Add to appropriate directory** (`.config/`, `install/`, `bin/`)
2. **Create README.md** explaining the feature
3. **Update main README.md** if it's a major addition
4. **Add Makefile target** if installation needed
5. **Add to TODO.md** if incomplete
6. **Test on target platform** if possible

### Common Pitfalls to Avoid
- ❌ Putting configs directly in home directory
- ❌ Hardcoding `/opt/homebrew` or `/usr/local`
- ❌ Assuming commands exist without checking
- ❌ Breaking Stow's symlink structure
- ❌ Forgetting to update package lists after installing
- ❌ Not documenting complex configurations

## Testing Considerations

### Manual Testing
```bash
# Test in clean environment
cd /tmp
git clone <repo-url> test-dotfiles
cd test-dotfiles

# Test linking (won't install packages)
make link

# Check symlinks
ls -la ~/.config/
ls -la ~/.zshenv
```

### Automated Testing
- **BATS testing framework** fully implemented
- **test/** directory with comprehensive test suite:
  - `test_platform.bats` - Platform detection tests
  - `test_bin_scripts.bats` - Script validation tests
  - `test_packages.bats` - Package file validation
  - `test_helper/common.bash` - Test helper functions
- Run with: `make test`
- Tests cover: symlink creation, package validation, platform detection, script syntax
- See test/README.md for complete testing documentation

## File-Specific Notes

### .zshenv (Root Level)
- **Critical:** Must stay in root, gets linked to `~/`
- Sets `ZDOTDIR=~/.config/zsh`
- Minimal content - most config in `.config/zsh/`

### Makefile
- Uses bash, not sh
- Defines platform-specific logic
- Exports environment variables for sub-processes
- Uses `bin/` scripts for platform detection

### install/Codefile
- **Populated** with VSCodium extensions
- Categorized: Language support, Git, Utilities, Themes, Docker
- Format: one extension ID per line (publisher.extension)
- Install with: `make vscode-extensions`

### install/duti
- Sets default applications on macOS
- Format: `bundle_id UTI role`
- Requires duti to be installed

## Resources for Understanding

### Dotfiles Concepts
- [Dotfiles Guide](https://dotfiles.github.io/)
- [XDG Base Directory Spec](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
- [GNU Stow Manual](https://www.gnu.org/software/stow/manual/stow.html)

### Tools Used
- [Homebrew Docs](https://docs.brew.sh/)
- [Zsh Documentation](https://zsh.sourceforge.io/Doc/)
- [Tmux Manual](https://man.openbsd.org/OpenBSD-current/man1/tmux.1)
- [Neovim Docs](https://neovim.io/doc/)

## New Features & Tools

### Utility Scripts (bin/)
Three powerful maintenance scripts with professional UX:

**dotfiles-doctor** - Comprehensive health check
- Checks system, repository, symlinks, packages, shell config, permissions
- Color-coded output (✓ pass, ✗ fail, ⚠ warning)
- Usage: `make doctor` or `bin/dotfiles-doctor --help`

**dotfiles-update** - Update automation
- Updates dotfiles repo, Homebrew, npm, Cargo, Oh My Zsh, plugins
- Skip options: `--skip-brew`, `--skip-npm`, `--skip-cargo`
- Usage: `make update` or `bin/dotfiles-update --help`

**dotfiles-backup** - Backup tool
- Backs up packages, extensions, configs, SSH config
- Options: `--compress`, `--cleanup`
- Usage: `make backup` or `bin/dotfiles-backup --help`

### Testing & CI/CD

**BATS Testing Framework:**
- Platform detection tests
- Script validation tests
- Package file validation tests
- Run locally: `make test`

**GitHub Actions Workflows:**
- **install.yml** - Tests installation on macOS 14/15 and Ubuntu
- **test.yml** - Runs BATS tests and integration tests
- **lint.yml** - ShellCheck, markdownlint, package validation

**Pre-commit Hooks:**
- ShellCheck for shell scripts
- Markdownlint for documentation
- Package file format validators
- EditorConfig checker
- Install: `pip install pre-commit && pre-commit install`

### Documentation

**Comprehensive guides available:**
- **README.md** - Main docs with FAQ, troubleshooting, CI badges
- **CLAUDE.md** - This file (AI assistant guide)
- **CONTRIBUTING.md** - Contribution guidelines
- **CHANGELOG.md** - Version history
- **MAKEFILE.md** - Complete Makefile reference
- **LICENSE** - MIT License
- **.github/README.md** - CI/CD workflow documentation
- **install/README.md** - Package installation guide
- **test/README.md** - Testing guide

All 15 .config/ directories have individual READMEs.

## Package Documentation

All package files now have comprehensive comments:
- **Brewfile**: 110+ packages organized by category
- **Caskfile**: 32 applications organized by category
- **npmfile**: 18 packages organized by category  
- **Rustfile**: 4 core + 12 optional tools documented

Each package/app includes a comment explaining its purpose.

## Version Information

This guide reflects the repository state after major improvements session (October 2025).

**Recent major additions:**
- 26+ TODO items completed
- 16+ new files created
- 13+ files enhanced
- 5000+ lines of code/documentation added
- Full testing infrastructure
- Complete CI/CD pipeline
- Comprehensive documentation suite

Last updated: October 24, 2025
