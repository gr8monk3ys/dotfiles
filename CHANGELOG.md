# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Removed
- **Go CLI** (`cmd/dotfiles/`) - Interactive TUI installer; `make` targets are sufficient
- **dotfiles-secrets** (`bin/dotfiles-secrets`) - age-based encryption tool (never operationally used)
- **dotfiles-template** (`bin/dotfiles-template`) - Template processor (no templates existed in repo)
- `age` from Brewfile (only needed for dotfiles-secrets)
- Makefile targets: `cli`, `cli-install`, `secrets-init`, `secrets-status`, `template-list`, `verify-go`
- Go CLI build job from CI test workflow
- `SETUP.md` (content folded into `OPERATING.md`)
- `CONTRIBUTING.md` (content folded into `AGENTS.md`)

### Changed
- Nix demoted from "primary" to "optional" in all documentation
- Nix flake CI check is now blocking (was `continue-on-error`)
- Nix Makefile targets delegate to `bin/dotfiles-nix` (thin Makefile, logic in script)
- 5 previously-skipped tests now run with mocked environments
- Consolidated top-level documentation. `CLAUDE.md` reduced to a pointer file. `AGENTS.md` absorbed `CONTRIBUTING.md`'s workflow and PR checklist, and gained a per-config README convention. `README.md` got an `OPERATING.md` signpost; all stale `NEW` tags removed.

### Added
- **bin/dotfiles-nix** - Wrapper script for all Nix operations (install, darwin, home, update, check, gc, shell)
- CLAUDE.md - Comprehensive AI assistant guide for working with the repository
- CONTRIBUTING.md - Contribution guidelines and development workflow
- `OPERATING.md`: single source of truth for operators and AI assistants (install paths, daily commands, making changes, repo map, current-state table, troubleshooting)
- CHANGELOG.md - This file to track changes
- LICENSE - GPL-3.0 License for the project
- .gitattributes - Line ending and language detection configuration
- .shellcheckrc - ShellCheck configuration for linting shell scripts
- .pre-commit-config.yaml - Pre-commit hooks for automated linting and validation
- Populated install/Codefile with useful VSCodium extensions
- **bin/dotfiles-doctor** - Health check script for system and configurations
- **bin/dotfiles-update** - Update script for all packages and configurations
- **bin/dotfiles-backup** - Backup script for configurations and packages
- **Makefile targets**: `make doctor`, `make update`, `make backup`, `make backup-compress`, `make backup-cleanup`
- **Testing infrastructure**:
  - test/ directory with BATS testing framework
  - test/README.md - Comprehensive testing documentation
  - test/test_platform.bats - Platform detection tests
  - test/test_bin_scripts.bats - Utility script tests
  - test/test_packages.bats - Package file validation tests
  - test/test_helper/common.bash - Common test helper functions
- **MAKEFILE.md** - Comprehensive Makefile documentation with all targets, dependency graph, usage examples
- **GitHub Actions workflows**:
  - .github/workflows/lint.yml - ShellCheck, markdownlint, package validation
  - .github/workflows/test.yml - BATS tests and integration tests
  - Updated .github/workflows/install.yml with health checks and BATS
  - .github/README.md - Comprehensive CI/CD workflow documentation
- **CI/CD badges** added to README.md
- Documentation improvements across the repository:
  - README.md: Added FAQ section, expanded troubleshooting, documentation links, CI badges
  - install/README.md: Added troubleshooting, backup/restore, platform quirks, package explanations

### Changed
- TODO.md - Updated with comprehensive task lists and marked completed items
- README.md - Enhanced with Documentation section, FAQ, and comprehensive troubleshooting
- install/README.md - Significantly expanded with troubleshooting and platform-specific guidance
- **bin/dotfiles-doctor** - Added --help flag and --verbose mode
- **bin/dotfiles-update** - Added --help flag, --verbose mode, and skip options (--skip-brew, --skip-npm, --skip-cargo)
- **bin/dotfiles-backup** - Already had --help flag and options
- **install/Brewfile** - Added comprehensive comments for 110+ packages, organized by category
- **install/Caskfile** - Added comprehensive comments for 32 applications, organized by category
- **install/npmfile** - Added comprehensive comments for 18 packages, organized by category
- **install/Rustfile** - Added comments for 4 core packages and 12 optional tools
- **.editorconfig** - Expanded to support 20+ file types and languages with specific rules
- **Makefile** - Added new targets: `clean`, `restore`, `brew-update`, `brew-cleanup`
- **MAKEFILE.md** - Created comprehensive documentation for all Makefile targets and usage

### Fixed
- Makefile directory references now work with current structure
- Symlink handling for .zshenv with automatic backup

## [1.0.0] - 2025-10-24

### Added
- Initial release of comprehensive dotfiles repository
- Complete .config/ directory with application configurations:
  - AeroSpace tiling window manager
  - Kitty terminal emulator
  - Zsh shell with Oh My Zsh integration
  - Tmux terminal multiplexer
  - Neovim editor with LSP support
  - Git configuration
  - Firefox preferences
  - macOS system defaults and dock configuration
  - MPD, Newsboat, Zathura, and more
- Package management via Homebrew, npm, Cargo, and pacman
- Utility scripts for platform detection (bin/ directory)
- Automated installation via Makefile
- Comprehensive README with setup instructions
- Individual README files for major configurations

### Platform Support
- Full macOS support (Apple Silicon and Intel)
- Partial Arch Linux support

## Release Notes Format

### [Version] - YYYY-MM-DD

#### Added
- New features, files, or capabilities

#### Changed
- Changes in existing functionality

#### Deprecated
- Features that will be removed in upcoming releases

#### Removed
- Removed features or files

#### Fixed
- Bug fixes

#### Security
- Security-related changes or fixes

---

## Versioning Guidelines

This project uses [Semantic Versioning](https://semver.org/):
- **MAJOR** version for incompatible changes (e.g., breaking changes to Makefile targets)
- **MINOR** version for new functionality in a backwards-compatible manner
- **PATCH** version for backwards-compatible bug fixes

## Upgrade Notes

### Upgrading to 1.0.0
- First stable release
- Back up existing configurations before installing
- Run `make link` to create symlinks
- Review .config/macos/ scripts before applying system defaults

---

For a detailed view of changes, see the [commit history](https://github.com/gr8monk3ys/dotfiles/commits/main).
