# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

Everything since 1.0.0 (2025-10-24), by theme.

### Added

- `bin/dotfiles-init` (and `make init`): creates the gitignored local files `make` cannot — git identity and jj identity — from their tracked templates, and reports on the SSH Include line and host snippets it can only look at. Idempotent, and it never rewrites an existing local file, not even to complete it. Values come from flags or from `GIT_USER_NAME`/`GIT_USER_EMAIL`/`GIT_SIGNING_KEY`/`JJ_USER_NAME`/`JJ_USER_EMAIL`, so CI and a scripted setup never block on a prompt; `--check` reports and exits non-zero, so the state can be asserted. `test/test_dotfiles_init.bats` covers it against fixture HOMEs, and never touches the real `~/.gitconfig`, `~/.config/jj` or `~/.ssh`
- `.config/jj/conf.d/user.toml.example`: the template jj identity had never had, even though `config.toml` has always pointed at `conf.d/user.toml` for it. `.gitignore` now excludes `conf.d/*` rather than `conf.d/`, because ignoring the directory stops git descending into it and would swallow the template with it
- `CONTEXT.md` § Local config: the `configured`/`incomplete`/`unconfigured`/`ineffective`/`optional` vocabulary, the four subjects it applies to, and why git identity is classified by asking git rather than by reading the file
- `install/pacmanfile` brought to parity with the Brewfile: 8 packages to 124. A fresh Arch machine previously got no zsh, neovim, starship, eza, bat, ripgrep, yazi, zellij, atuin, jj, tmux or stow — so `.config/zsh/aliases.zsh` guarded almost all of itself off, there was no prompt, and the shell the whole repo is built around was not installed. Every name was checked with `pacman -Si` inside `test/Dockerfile.arch`; the Arch spellings (`jujutsu`, `github-cli`, `nodejs`, `pandoc-cli`, `onetbb`, `python-poetry`, `timew`, `typos`, …) have their own `docs/TOOLS.md` entries, and `wl-clipboard`/`xclip` supply the Linux branch of the `pbcopy`/`pbpaste` aliases
- `.github/workflows/ci.yml`: a `Container` matrix job running the suite in both the Ubuntu and Arch images on every PR. `make test-docker-arch` had existed for a while in no gate at all, which is how the pacmanfile stayed at 8 packages without failing anything
- `SKIP_ARCH_DOCKER=1` opts out of just the Arch container in `make verify`, for hosts where amd64 emulation makes it slow
- `bin/firefox-user-js` (and `make firefox`): installs this checkout's `user.js` into the Firefox profiles that actually read it, discovering them from `profiles.ini` rather than by globbing `Profiles/*/`. Symlinks by default so edits reach Firefox at its next start, `--copy` for sandboxed builds, backs up a `user.js` it did not write, and warns when Firefox is running (`user.js` is read only at startup). `test/test_firefox_user_js.bats` covers it against a fixture profile tree — the real profiles are never touched by tests
- `CONTEXT.md` § Firefox profile state: the `linked`/`installed`/`foreign`/`absent`/`missing` vocabulary, and why a profile's `default` role comes from an `[Install…]` section rather than `Default=1`
- `bin/lib/git-sync.sh`: shared git fast-forward state machine behind one interface, with `dotfiles-update`, `dotfiles-sync` and `dotfiles-doctor` as three reporters over it; `test/test_git_sync.bats` covers it directly
- `bin/manifest`: the single reader of the `install/` manifests (`list <kind>`, `kinds`, `taps`), replacing five parsers that disagreed with each other; `test/test_manifest.bats` covers it
- `bin/validate-doctor-tools` (and `make verify-doctor-tools`, in CI): fails when `dotfiles-doctor`'s probed tool lists and the install manifests drift apart, in either direction; the command-to-package mapping lives in `test/allowlist/command-packages.txt`
- `.config/zsh/lib.zsh`: helpers both `aliases.zsh` and `functions.zsh` need, sourced before either. Holds `_dotfiles_clipboard`, the pbcopy/wl-copy/xclip chain that was previously written out in both files with fallbacks that had drifted apart
- `bin/link-state`: classifies every managed path against the checkout, read by `dotfiles-doctor` and `make clean`; `test/test_link_state.bats` covers the classification directly, which had no test of any kind before
- `bin/install-kind`: installs one manifest kind, owning the manifest lookup, install command, tap-trusting, skip and strict policy that six Makefile targets each re-derived; `test/test_install_kind.bats` runs it for real against stub binaries
- `bin/lib/snapshot.sh`: the snapshot layout described once, read by both `dotfiles-backup` and `dotfiles-restore`; `test/test_snapshot.bats` covers it against a fixture snapshot, with a drift check that the two cannot disagree again
- `bin/lib/preamble.sh`: shared checkout resolution and `command_exists`, collapsing three copies in `bin/`
- `bin/platform file-mode <path>`: the BSD/GNU `stat` adapter pair, moved out of `dotfiles-doctor` where it was private to one caller
- `dotfiles-doctor --list-checked-tools`: lists every command the health check probes
- `CONTEXT.md`: domain glossary (checkout, sync state, reporter, manifest, command vs package, platform)
- `docs/agents/`: issue-tracker, triage-label and domain-doc conventions for the engineering skills
- `make verify-shellcheck` and `make verify-markdown`, both in the `make verify` chain: shellcheck and markdownlint previously ran only in CI, so a green local gate could still fail on push. `SKIP_LINTERS=1` opts out; a missing linter warns rather than failing
- `shellcheck` (Brewfile) and `markdownlint-cli` (npmfile) are now manifest-tracked, with catalog entries
- `macos-14` dropped from the fresh-install matrix: Homebrew no longer publishes bottles for `gnupg`, `gum`, `mise`, `topgrade`, `simdutf` or `tesseract` on it, so `brew bundle` cannot complete there. `STRICT_PACKAGES=1` surfaced what `|| true` had been hiding; testing a platform the Brewfile cannot install on is testing a fiction
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

- `dotfiles-doctor` now has a Local Configuration section and is a reporter over `bin/dotfiles-init --status`, carrying no detection of its own. It used to name the problem ("git identity not set") without being able to point at a fix, and asked `git config --global user.email` to find out — which, because `--global` defaults to `--no-includes`, could not see an identity that arrived through `config.local`'s `[include]`, the only place this repo puts one
- `make help` documents `GIT_USER_NAME`, `GIT_USER_EMAIL`, `GIT_SIGNING_KEY`, `JJ_USER_NAME` and `JJ_USER_EMAIL`, with a test that fails if an identity variable the Makefile reads is missing from it
- The fresh-laptop checklist in `OPERATING.md` is now `make init` rather than two `cp` commands and a note about jj that had no template behind it
- `make verify` now runs both container tests, not just Ubuntu. The Arch half of the repo's claimed platform support was never exercised by any gate
- `bin/platform` is now the only place in `bin/` that reads `$OSTYPE` or `uname`: seven inline branches in `dotfiles-doctor` and `dotfiles-backup` go through it, and `install.sh` uses it once the checkout exists (its own copy remains for the pre-clone stretch, where nothing can be sourced)
- `install.sh` now accepts `amd64` as `x86_64`, matching `bin/platform`
- `bin/check-alias-references` now resolves aliases against every manifest kind that puts a command on PATH (previously 4 of 6: no `Caskfile.extra`, no `pacmanfile`) and matches tap-qualified formulae by their PATH name, so `sketchybar` resolves where `FelixKratz/formulae/sketchybar` did not. It therefore rejects fewer aliases; the ones it stopped rejecting were false positives
- Manifest format validation moved from seven hand-rolled regexes in `test/test_packages.bats` into `bin/manifest`, so the rule that parses a manifest is the rule that validates it
- Regression tests that asserted on config _file text_ now assert on runtime behaviour where one exists: `alias c`, `$BAT_THEME` and the live starship prompt hook moved onto the booted shell in `test_shell_boot.bats`, and the delta theme check asks `git config --get` instead of grepping git's syntax. Text checks remain only where there is no cheap runtime observable (bat's config, nvim's plugin spec) or the rule is inherently static (portable shell, no personal identity)
- `SKIP_KINDS="rust pacman"` replaces `SKIP_BREW`/`SKIP_CASKS`/`SKIP_NPM`/`SKIP_RUST`, and `STRICT_PACKAGES` replaces `BREW_BUNDLE_STRICT`/`DOTFILES_STRICT_PACKAGES`. One axis, one spelling, using the same word `bin/manifest` already used — and able to express "skip cask-extra but not cask", which the booleans could not. The old names still work and print a deprecation notice
- Package install failures are now uniformly tolerant by default and uniformly fatal under `STRICT_PACKAGES`. Previously brew and editor extensions were tolerant while npm, rust and pacman were fatal — an inconsistency nobody chose. `install.sh` still defaults to strict; CI's fresh-install matrix now sets it explicitly, closing a gap where a broken Brewfile passed CI because bare `make` swallowed the failure
- `make help` documents `SKIP_KINDS`, `STRICT_PACKAGES`, `SKIP_DOCKER` and `SKIP_LINTERS`; a test now fails if any `SKIP_`/`STRICT_` variable the Makefile reads is missing from it
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

- `install.sh`'s OS dispatch: it cased on `bin/platform detect` and called `make macos`/`make arch`/`make link` itself, duplicating the Makefile's own `OS := $(shell bin/platform detect)` / `all: $(OS)`. It now just runs `make`
- The `bun` make target: bun is already in the Brewfile (`brew "oven-sh/bun/bun"`), so the target only ever printed "already installed" — and it put a `curl | bash` in the default install path for no gain
- The `brew-taps` make target: trusting taps is a step within installing a brew kind, not ordering between kinds, so it moved inside `bin/install-kind`
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

- Both test Dockerfiles copied the checkout's `.git` verbatim. From a git worktree — which `bin/dotfiles-worktree` hands out — that is a pointer file naming a gitdir absent from the image, so every git command inside the container exited 128 and the two tests that ask git about the checkout (leaked identity, ignored SSH hosts) failed for a reason unrelated to the dotfiles. The image now rebuilds a real one-commit repo when it receives a pointer
- `test/Dockerfile.arch` lacked `diffutils`, so `cmp` was missing and two `bin/firefox-user-js` tests failed only on Arch
- `test/test_doctor_tools.bats` proved a removed package is caught by deleting it from the Brewfile alone. The validator asks whether a package is in _any_ manifest, so once `ripgrep` was in the pacmanfile too the test passed vacuously; it now removes it from both
- `.config/firefox/user.js` had never taken effect. Stow links it to `~/.config/firefox/user.js`, which Firefox does not read: `user.js` is per-profile, loaded at startup from inside the profile directory, and neither profile on this machine had one. 81KB of arkenfox hardening was tracked, linked, and applying to nothing. `bin/firefox-user-js` installs it where Firefox looks; the stowed copy stays the source of truth
- Picking the default Firefox profile by `Default=1` would have hardened the wrong one. `Default=1` in a `[Profile N]` section is the legacy fallback; an `[Install…]` section's `Default=` names the profile the installed Firefox actually opens. On this machine they disagree — `Default=1` points at a 4KB profile that has never been opened, while the live one holds 124MB — so `bin/firefox-user-js` reads the `[Install…]` entry first
- `make link` appended a duplicate `Include ~/.config/ssh/config.d/*.conf` block to `~/.ssh/config` on every run. `link` and `link-dry-run` each carried their own copy of the match pattern with different escaping; make does not collapse `\\`, so `link`'s grep received an escaped backslash plus a quantifier instead of a literal `*` and never matched. Both targets now read one `SSH_INCLUDE_RE`, and `make link` is idempotent
- `dotfiles-restore` silently handled 2 of the 9 artifacts `dotfiles-backup` writes, while its help promised to "restore files from a dotfiles backup". It now replays every `tree` artifact from the shared table, names the records it preserved, and warns about artifacts it does not recognise instead of walking past them
- Backup's `npmfile.txt` and `Rustfile.txt` were `npm list -g` and `cargo install --list` output — decorated listings, not the bare-name format of `install/npmfile` and `install/Rustfile`, and not replayable. Renamed to `npm-global-list.txt` and `cargo-installed.txt`, and every record now carries a provenance header naming the command that produced it. Old snapshots still resolve via a legacy name in the table
- `dotfiles-backup` captured only one editor's extensions (`code` **or** `codium`) while the Makefile preferred the other; it now captures both when both exist
- `dotfiles-backup --cleanup` removed old snapshot directories but never the `.tar.gz` archives `--compress` made from them, so archives accumulated unbounded and nothing ever read them
- `MANIFEST.txt` counted only Homebrew formulae and casks; it now reports every record artifact actually written
- `make` had no target for `unknown`, the fourth value `bin/platform detect` can return, so `make` on an unsupported OS died with "No rule to make target". Only `install.sh` covered for that — which is why the two dispatches could disagree. Added `unknown: link`
- `make pacman-packages` piped `install/pacmanfile` straight into `pacman -S --noconfirm -`, comments included; it worked only because that file happens to have none. It now goes through `bin/manifest list pacman` like every other kind, and gained skip support it never had
- `alias l` was defined twice: unconditionally as `ls -lF`, and again as `eza -l …` inside a `command -v eza` guard. On any machine with eza the first was dead, and on one without, `l` survived only by accident of that duplicate. The `ls` forms are now a real `else` branch, so `l`, `la` and `ll` exist either way
- `.zshrc` resolved `ZDOTDIR` five times with two different defaults — `${ZDOTDIR:-$HOME}` for the completion dump and `${ZDOTDIR:-$HOME/.config/zsh}` everywhere else — so a shell started without `.zshenv` wrote its dump where nothing else looked. Resolved once at the top
- `test_shell_boot.bats` symlinked its fixture at `$DOTFILES_DIR/.config/zsh` and deleted `.zcompdump*` inside the checkout, so the suite wrote to its own subject. It now copies, and a new test asserts a boot creates nothing new in the checkout
- `dotfiles-doctor` judged 8 hardcoded `.config` directories while `stow` links all 26 the checkout ships, so 18 were never checked and nothing failed when the list fell behind. It now derives the list, and immediately surfaced two real problems: `.config/npm` was not linked at all, and `.config/atuin` holds a real file where a link should be
- Neovim's LSP setup used `require("lspconfig").<server>.setup()`, deprecated on nvim 0.11+ and slated for removal in nvim-lspconfig v3.0.0; opening a file printed a deprecation warning and a stack traceback. Migrated to `vim.lsp.config` / `vim.lsp.enable` with an `LspAttach` autocmd replacing the per-server `on_attach`. Verified against a real cargo project: `rust_analyzer` attaches under both the old and new config, and the warning is gone
- nvim-treesitter was pinned by the lockfile to its `main` branch — a ground-up rewrite with no `nvim-treesitter.configs` module — while the config uses the `master` API, so the whole block errored on every startup and treesitter highlighting and indent were silently off. Pinned to `master`, the branch the config is written for
- `ensure_installed` asked for a `zsh` parser, which does not exist, so every startup printed "Parser not available" — and `bash`, the parser that actually handles shell files, was not in the list at all
- Two `:contentReference[oaicite:N]` artifacts left in `plugins.lua` by whatever generated it
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
