# Bin Directory

Utility scripts for system management and dotfiles operations.

## Platform Detection

### [platform](platform)

Unified platform detection utility (replaces individual is-* scripts).

**Usage:**

```bash
# Detect OS
platform detect              # Output: macos, arch, linux, or unknown

# Detect architecture
platform arch                # Output: arm64, x86_64, or unknown

# Boolean checks (exit codes)
platform is-macos            # Exit 0 if macOS
platform is-linux            # Exit 0 if Linux
platform is-arm64            # Exit 0 if ARM64

# Command existence
platform has brew            # Exit 0 if brew exists

# Platform-specific behaviour behind one interface
platform file-mode <path>    # Octal permission bits (BSD stat vs GNU stat)

# Value selection
platform select /opt/homebrew /usr/local "platform is-arm64"
```

**Examples:**

```bash
# Conditional logic
if platform is-macos; then
    echo "Running on macOS"
fi

# Homebrew prefix detection
HOMEBREW_PREFIX=$(platform select /opt/homebrew /usr/local "platform is-arm64")

# Check before running
platform has docker && docker ps
```

## Utility Scripts

### [dotfiles-doctor](dotfiles-doctor)

Comprehensive health check for your dotfiles installation.

**Usage:**

```bash
dotfiles-doctor [--verbose]
# or
make doctor
```

**Checks:**

- System information
- Dotfiles repository status
- Symlink integrity
- Package managers (Homebrew, npm, Cargo)
- Core tools (git, zsh, nvim, stow)
- Modern CLI tools (eza, bat, fd, rg, yazi, jj, etc.)
- Shell configuration
- File permissions

### [dotfiles-update](dotfiles-update)

Update all packages and configurations.

**Usage:**

```bash
dotfiles-update [--skip-brew] [--skip-npm] [--skip-cargo]
# or
make update
```

### [dotfiles-backup](dotfiles-backup)

Backup configurations and package lists.

**Usage:**

```bash
dotfiles-backup [--compress] [--cleanup]
# or
make backup
```

### [dotfiles-restore](dotfiles-restore)

Restore files from snapshots produced by `dotfiles-backup`.

**Usage:**

```bash
dotfiles-restore                              # restore latest backup
dotfiles-restore ~/dotfiles-backup/20260224_120000
dotfiles-restore --dry-run
# or
make restore
```

### [dotfiles-bench-shell](dotfiles-bench-shell)

Benchmark interactive zsh startup and enforce a maximum average startup budget.

**Usage:**

```bash
dotfiles-bench-shell --runs 7 --budget-ms 900
# or
make bench-shell runs=7 budget=900
```

### [dotfiles-worktree](dotfiles-worktree)

Create isolated git worktrees/branches for parallel sessions (for example,
multiple AI terminals working the same repository).

**Usage:**

```bash
dotfiles-worktree add ghostty-pass      # creates ../dotfiles-ghostty-pass on ai/ghostty-pass
dotfiles-worktree list                  # show active worktrees
dotfiles-worktree remove ghostty-pass   # remove by name
dotfiles-worktree prune                 # cleanup stale metadata
# or
make worktree-add name=ghostty-pass
```

### [dotfiles-sync](dotfiles-sync)

Lightweight automated sync for launchd (macOS only). Designed for
unattended execution — for interactive updates, use `dotfiles-update`.

**Behavior:**

- Pulls git changes if available
- Skips silently if uncommitted changes exist
- Shows macOS notification only when something happens
- Silent when already up to date

**Usage:**

```bash
dotfiles-sync            # Run manually (typically invoked by launchd)
# or
make sync-install        # Enable daily auto-sync (10:00 AM)
make sync-uninstall      # Disable auto-sync
make sync-status         # Check sync service status
make sync-run            # Run sync manually
```

### [check-alias-references](check-alias-references)

Validates that every unconditional alias in `.config/zsh/aliases.zsh` resolves
to a known source: a shell builtin, an entry in `install/Brewfile`, `install/Caskfile`,
`install/Rustfile`, or `install/npmfile`, or an entry in
`test/allowlist/system-tools.txt`.

Aliases inside `if command -v X &> /dev/null; then ... fi` blocks are exempt
(the guard itself declares the dependency).

**Usage:**

```bash
check-alias-references  # Validate all unconditional aliases
# or
make verify-shell-surface
```

**On failure:** Prints the offending alias's file:line, the unresolved command, and
three suggested fixes:

1. Add the command to a package manifest (Brewfile, etc.)
2. Wrap the alias with a guard condition
3. Add the command to `test/allowlist/system-tools.txt` if it's a base system tool

### [validate-doc-links](validate-doc-links)

Validates local Markdown links across repository documentation.

**Usage:**

```bash
validate-doc-links          # Validate links from current directory
validate-doc-links /path    # Validate from specific repo path
# or
make verify-doc-links
```

### [validate-tool-docs](validate-tool-docs)

Keeps [docs/TOOLS.md](../docs/TOOLS.md) in sync with the install manifests:
every package needs a catalog entry, and every entry must still be installed
by a manifest (entries under "Not installed by manifests" are exempt).

**Usage:**

```bash
validate-tool-docs          # Validate from current directory
# or
make verify-tool-docs
```

### [dotfiles-why](dotfiles-why)

Explains why a tool is part of these dotfiles, backed by
[docs/TOOLS.md](../docs/TOOLS.md).

**Usage:**

```bash
dotfiles-why                # fzf browser with entry preview
dotfiles-why ripgrep        # print one tool's entry
dotfiles-why --list         # list all documented tools
```

### [lib/ui.sh](lib/ui.sh)

Shared terminal UI helpers (`print_header`, `print_success`, `print_info`,
`print_warn`, `print_error`) sourced by the dotfiles-* scripts. Plain ANSI
output by default (stable for tests/CI); headers upgrade to styled
[gum](https://github.com/charmbracelet/gum) boxes when gum is installed and
stdout is a terminal.

**Usage (inside a script):**

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/ui.sh"
```

### [lib/snapshot.sh](lib/snapshot.sh)

The layout of a `dotfiles-backup` snapshot, described once. Backup writes a
snapshot and restore reads one; before this they each knew the filenames
separately and had drifted, so backup wrote nine artifacts and restore
handled two.

Artifacts have a class — `tree` (restore replays it), `record` (preserved,
never replayed) and `metadata`. See CONTEXT.md § Snapshot for the table and
the reasoning. Rows may carry a legacy filename so older snapshots still
resolve after a rename.

```bash
snapshot_names_of_class tree      # configs, ssh
snapshot_class Brewfile           # record
snapshot_present "$dir" npm-global-list.txt   # path, or legacy name, or 1
```

### [lib/preamble.sh](lib/preamble.sh)

Checkout resolution (`DOTFILES_DIR`) and the `command_exists` predicate,
sourced by the `dotfiles-*` scripts. `SCRIPT_DIR` is deliberately _not_ here —
a script needs it to find this file — so every caller starts with:

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/preamble.sh"
```

Non-bash callers use `bin/platform has` for the same predicate; `install.sh`
keeps its own copy because it runs before the checkout exists.

### [lib/git-sync.sh](lib/git-sync.sh)

Shared git fast-forward state machine, sourced by `dotfiles-update`,
`dotfiles-sync` and `dotfiles-doctor`. One module decides whether a checkout
is safe to fast-forward; each caller maps the resulting state to its own
output. See CONTEXT.md § Sync state for the vocabulary.

Both entry points always return 0 — the result is `GIT_SYNC_STATE`, not the
exit code — and neither ever `cd`s or suppresses git's stderr (captured into
`GIT_SYNC_DETAIL` instead).

**Usage (inside a script):**

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/git-sync.sh"

git_sync_status "$DOTFILES_DIR"           # diagnose only; fetches
git_sync_status "$DOTFILES_DIR" no-fetch  # diagnose against the last fetch
git_sync_apply  "$DOTFILES_DIR"           # diagnose, then pull when safe

case "$GIT_SYNC_STATE" in
    "$GIT_SYNC_PULLED") echo "pulled $GIT_SYNC_BEHIND commit(s)" ;;
esac
```

### [manifest](manifest)

The single reader of the `install/` package manifests. Every consumer that
needs to know what this system installs asks here: the Makefile installer
targets, `validate-tool-docs`, `check-alias-references` and
`test/test_packages.bats`. Replaced five separate parsers that disagreed
about tap-qualified names and which manifests to read.

```bash
manifest list <kind>   # one normalized package name per line
manifest kinds         # brew cask cask-extra npm rust pacman code
manifest taps          # Homebrew taps declared in the Brewfile
```

`list` exits non-zero on a line it cannot parse, or a name that breaks that
ecosystem's grammar — that strictness is what lets the format tests be a
single `assert_success`. Tap-qualified formulae are reduced to the last
segment (`oven-sh/bun/bun` -> `bun`), the name that lands on PATH.
`install/duti` is not a kind: it lists file associations, not packages.
Point it at another checkout with `DOTFILES_DIR`.

### [install-kind](install-kind)

Installs one manifest **kind**. How a kind installs — which manifest, which
command, whether to skip it, whether a failure is fatal — used to be
re-derived in six Makefile targets, which is why the only way to test any of
it was to grep `make -n` output.

```bash
install-kind brew          # trust taps, then brew bundle the Brewfile
install-kind code          # extensions, preferring codium over code
SKIP_KINDS="rust pacman" install-kind rust   # skipped
STRICT_PACKAGES=1 install-kind npm           # a failure is fatal
```

The Makefile keeps every dependency edge between kinds — ordering is what
make is genuinely deep at. A missing tool is not a failure: `install-kind
rust` with no cargo warns and exits 0.

### [validate-doctor-tools](validate-doctor-tools)

Fails when `dotfiles-doctor`'s probed tool lists and the `install/` manifests
drift apart. Doctor probes _commands_ (`rg`); manifests list _packages_
(`ripgrep`), so the mapping and the deliberate exemptions live in
`test/allowlist/command-packages.txt`.

Checks both directions: every probed command must resolve to a manifest
package (directly, via the mapping, or as an explicit `-` exemption), and
every mapping entry must still name a package that exists and a command
doctor still probes. Run by `make verify-doctor-tools`.

## Compatibility Helpers

### [pacman](pacman)

Wrapper that invokes `/usr/bin/pacman`, using `sudo` automatically when needed.
Helps non-root installations on Arch Linux.

## Adding New Scripts

1. Create script with shebang (`#!/usr/bin/env bash`)
2. Make executable: `chmod +x script-name`
3. Document in this README
4. Test on target platforms

## Platform Compatibility

| Script | macOS | Linux | Arch |
| --- | --- | --- | --- |
| platform | ✓ | ✓ | ✓ |
| dotfiles-doctor | ✓ | ✓ | ✓ |
| dotfiles-update | ✓ | ✓ | ✓ |
| dotfiles-backup | ✓ | ✓ | ✓ |
| dotfiles-restore | ✓ | ✓ | ✓ |
| dotfiles-bench-shell | ✓ | ✓ | ✓ |
| dotfiles-worktree | ✓ | ✓ | ✓ |
| dotfiles-sync | ✓ | — | — |
