# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

Everything since 1.0.0 (2025-10-24), by theme.

### Added

- `.github/workflows/ci.yml`: shellcheck, markdownlint, validators, BATS on macOS and Ubuntu, and the curl installer, on every PR

- Tool catalog: `docs/TOOLS.md` with a rationale per package, `bin/dotfiles-why` to browse it, and `bin/validate-tool-docs` (run by `make verify`) to keep it in sync with the install manifests
- 16 modern CLI tools (yazi, eza, bat, ripgrep, fd, zoxide, atuin, dust, procs, bottom, broot, navi, ouch, delta, …) with guarded aliases in `.config/zsh/aliases.zsh`
- Jujutsu (`jj`), Zellij, SketchyBar and Karabiner vim-navigation configs
- `bin/dotfiles-restore`, `bin/dotfiles-bench-shell`, `bin/dotfiles-worktree`, `bin/dotfiles-sync` (daily launchd pull) and matching `make` targets
- `make verify` pipeline (shell syntax, shell-surface, stale-ref, doc-link, tool-doc checks, BATS) and `make daily` subset
- Shell-surface test suite and `bin/check-alias-references` (every unconditional alias must resolve to a manifest entry, builtin, or allowlisted system tool)
- Generic-Linux `make link` path (`stow-linux`)
- `OPERATING.md` (runbook) and `AGENTS.md` (conventions); `CLAUDE.md` reduced to a pointer
- Baseline repo files: `LICENSE` (GPL-3.0), `SECURITY.md`, `CODE_OF_CONDUCT.md`, `.editorconfig`, `.shellcheckrc`, `.pre-commit-config.yaml`, this changelog

### Changed

- Terminal: Kitty → Ghostty; theme standardised on OneDark across CLI tools (Ghostty and SketchyBar keep their own)
- Shell: Oh My Zsh → Zinit; prompt: Powerlevel10k → Starship; ~3x faster startup, Homebrew put on PATH before prompt selection
- File manager: lf → yazi
- `.config/macos/defaults.sh` replaced with a small, current, sudo-free script
- `bin/` scripts resolve their own checkout instead of assuming `~/.dotfiles`
- `.zshenv` symlink is backed up before being replaced by `make link`
- Test suite trimmed of structural tests that only asserted files exist

### Removed

- `AGENTS.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`, `CODEOWNERS`, `docs/superpowers/` (AI-session plans); jj identity moved to a gitignored `conf.d/user.toml`

- Nix layer (flake, `bin/dotfiles-nix`, Makefile targets)
- Go CLI (`cmd/dotfiles/`), `bin/dotfiles-secrets`, `bin/dotfiles-template` and the `age` dependency
- GitHub Actions workflows and CI badges (repo is private; `make verify` is the gate)
- Foreign `.local/bin` scripts and vendored Neovim repo infrastructure
- `SETUP.md`, `CONTRIBUTING.md`, `MAKEFILE.md`, `TODO.md` (folded into the three top-level docs)

### Fixed

- `make clean` on macOS; `make node-packages` / `make rust-packages` installing nothing
- Stale Homebrew taps and the gh-dash install method
- Sketchybar tap; theme claims in README and Yazi config

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
