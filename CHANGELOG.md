# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

Everything since 1.0.0 (2025-10-24), by theme.

### Added

- `bin/lib/git-sync.sh`: shared git fast-forward state machine behind one interface, with `dotfiles-update`, `dotfiles-sync` and `dotfiles-doctor` as three reporters over it; `test/test_git_sync.bats` covers it directly
- `bin/manifest`: the single reader of the `install/` manifests (`list <kind>`, `kinds`, `taps`), replacing five parsers that disagreed with each other; `test/test_manifest.bats` covers it
- `bin/validate-doctor-tools` (and `make verify-doctor-tools`, in CI): fails when `dotfiles-doctor`'s probed tool lists and the install manifests drift apart, in either direction; the command-to-package mapping lives in `test/allowlist/command-packages.txt`
- `bin/lib/snapshot.sh`: the snapshot layout described once, read by both `dotfiles-backup` and `dotfiles-restore`; `test/test_snapshot.bats` covers it against a fixture snapshot, with a drift check that the two cannot disagree again
- `bin/lib/preamble.sh`: shared checkout resolution and `command_exists`, collapsing three copies in `bin/`
- `bin/platform file-mode <path>`: the BSD/GNU `stat` adapter pair, moved out of `dotfiles-doctor` where it was private to one caller
- `dotfiles-doctor --list-checked-tools`: lists every command the health check probes
- `CONTEXT.md`: domain glossary (checkout, sync state, reporter, manifest, command vs package, platform)
- `docs/agents/`: issue-tracker, triage-label and domain-doc conventions for the engineering skills
- `make verify-shellcheck` and `make verify-markdown`, both in the `make verify` chain: shellcheck and markdownlint previously ran only in CI, so a green local gate could still fail on push. `SKIP_LINTERS=1` opts out; a missing linter warns rather than failing
- `shellcheck` (Brewfile) and `markdownlint-cli` (npmfile) are now manifest-tracked, with catalog entries
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

- `bin/platform` is now the only place in `bin/` that reads `$OSTYPE` or `uname`: seven inline branches in `dotfiles-doctor` and `dotfiles-backup` go through it, and `install.sh` uses it once the checkout exists (its own copy remains for the pre-clone stretch, where nothing can be sourced)
- `install.sh` now accepts `amd64` as `x86_64`, matching `bin/platform`
- `bin/check-alias-references` now resolves aliases against every manifest kind that puts a command on PATH (previously 4 of 6: no `Caskfile.extra`, no `pacmanfile`) and matches tap-qualified formulae by their PATH name, so `sketchybar` resolves where `FelixKratz/formulae/sketchybar` did not. It therefore rejects fewer aliases; the ones it stopped rejecting were false positives
- Manifest format validation moved from seven hand-rolled regexes in `test/test_packages.bats` into `bin/manifest`, so the rule that parses a manifest is the rule that validates it
- Regression tests that asserted on config _file text_ now assert on runtime behaviour where one exists: `alias c`, `$BAT_THEME` and the live starship prompt hook moved onto the booted shell in `test_shell_boot.bats`, and the delta theme check asks `git config --get` instead of grepping git's syntax. Text checks remain only where there is no cheap runtime observable (bat's config, nvim's plugin spec) or the rule is inherently static (portable shell, no personal identity)
- `dotfiles-doctor`'s `check_pass`/`check_fail`/`check_warn`/`check_info` now wrap `lib/ui.sh`'s printers instead of restating its escape codes, so a change to shared output formatting actually reaches the health check
- `dotfiles-update` no longer aborts the entire run when the checkout has uncommitted changes; it skips the repository step, continues with package updates, and says so in the summary
- Terminal: Kitty → Ghostty; theme standardised on OneDark across CLI tools (Ghostty and SketchyBar keep their own)
- Shell: Oh My Zsh → Zinit; prompt: Powerlevel10k → Starship; ~3x faster startup, Homebrew put on PATH before prompt selection
- File manager: lf → yazi
- `.config/macos/defaults.sh` replaced with a small, current, sudo-free script
- `bin/` scripts resolve their own checkout instead of assuming `~/.dotfiles`
- `.zshenv` symlink is backed up before being replaced by `make link`
- Test suite trimmed of structural tests that only asserted files exist

### Removed

- `bin/is-executable`: a one-line `command -v` wrapper with a single caller; `make brew` uses `bin/platform has brew` instead
- `platform run-if` and `platform is-arch`: no callers; `platform has` and `platform is-omarchy` cover their uses
- `test_regressions.bats` "legacy theme names are absent": duplicated `make verify-stale-refs`, which checks 9 patterns over more paths in the same `make verify`
- `AGENTS.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`, `CODEOWNERS`, `docs/superpowers/` (AI-session plans); jj identity moved to a gitignored `conf.d/user.toml`
- Nix layer (flake, `bin/dotfiles-nix`, Makefile targets)
- Go CLI (`cmd/dotfiles/`), `bin/dotfiles-secrets`, `bin/dotfiles-template` and the `age` dependency
- GitHub Actions workflows and CI badges (repo is private; `make verify` is the gate)
- Foreign `.local/bin` scripts and vendored Neovim repo infrastructure
- `SETUP.md`, `CONTRIBUTING.md`, `MAKEFILE.md`, `TODO.md` (folded into the three top-level docs)

### Fixed

- `make link` appended a duplicate `Include ~/.config/ssh/config.d/*.conf` block to `~/.ssh/config` on every run. `link` and `link-dry-run` each carried their own copy of the match pattern with different escaping; make does not collapse `\\`, so `link`'s grep received an escaped backslash plus a quantifier instead of a literal `*` and never matched. Both targets now read one `SSH_INCLUDE_RE`, and `make link` is idempotent
- `dotfiles-restore` silently handled 2 of the 9 artifacts `dotfiles-backup` writes, while its help promised to "restore files from a dotfiles backup". It now replays every `tree` artifact from the shared table, names the records it preserved, and warns about artifacts it does not recognise instead of walking past them
- Backup's `npmfile.txt` and `Rustfile.txt` were `npm list -g` and `cargo install --list` output — decorated listings, not the bare-name format of `install/npmfile` and `install/Rustfile`, and not replayable. Renamed to `npm-global-list.txt` and `cargo-installed.txt`, and every record now carries a provenance header naming the command that produced it. Old snapshots still resolve via a legacy name in the table
- `dotfiles-backup` captured only one editor's extensions (`code` **or** `codium`) while the Makefile preferred the other; it now captures both when both exist
- `dotfiles-backup --cleanup` removed old snapshot directories but never the `.tar.gz` archives `--compress` made from them, so archives accumulated unbounded and nothing ever read them
- `MANIFEST.txt` counted only Homebrew formulae and casks; it now reports every record artifact actually written
- Worktrees are no longer reported as "Not a git repository": the sync state machine uses `git rev-parse --show-prefix` instead of `[[ -d .git ]]`, which is false in any checkout made by `bin/dotfiles-worktree`
- A checkout with no upstream no longer reports "up to date" forever; it is now a distinct `no-upstream` state that `dotfiles-doctor` surfaces
- `dotfiles-sync` no longer discards git's stderr into `/dev/null`, so `make sync-log` can show why a sync failed
- `test/Dockerfile` installed Ubuntu's `bats` 1.2.1, which predates `bats_require_minimum_version` and `run --separate-stderr`: `test_shell_boot.bats` died with status 127 and the container run silently lost two tests. Installs bats-core 1.11.0 from source instead, and `make verify` (with Docker) passes again
- `SECURITY.md` markdown violations (`MD022`, `MD032`), which CI's markdownlint step was not catching
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
