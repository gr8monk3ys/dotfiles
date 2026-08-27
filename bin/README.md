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
platform is-arch             # Exit 0 if Arch Linux
platform is-linux            # Exit 0 if Linux
platform is-arm64            # Exit 0 if ARM64

# Command existence
platform has brew            # Exit 0 if brew exists

# Conditional execution
platform run-if brew update  # Only runs if brew exists

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

## Compatibility Helpers

### [is-executable](is-executable)

Legacy compatibility shim for older Makefile references. Returns success if a
command exists on PATH.

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
|--------|-------|-------|------|
| platform | ✓ | ✓ | ✓ |
| dotfiles-doctor | ✓ | ✓ | ✓ |
| dotfiles-update | ✓ | ✓ | ✓ |
| dotfiles-backup | ✓ | ✓ | ✓ |
| dotfiles-restore | ✓ | ✓ | ✓ |
| dotfiles-bench-shell | ✓ | ✓ | ✓ |
| dotfiles-worktree | ✓ | ✓ | ✓ |
| dotfiles-sync | ✓ | — | — |
