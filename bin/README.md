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
- Package managers (Homebrew, npm, Cargo, Nix)
- Core tools (git, zsh, nvim, stow)
- Modern CLI tools (eza, bat, fd, rg, yazi, jj, etc.)
- Nix setup (flakes, Home Manager, nix-darwin)
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

### [dotfiles-nix](dotfiles-nix)

Manage Nix configuration (optional). Wraps all Nix operations.

**Usage:**
```bash
dotfiles-nix install    # Install Nix package manager
dotfiles-nix darwin     # Apply nix-darwin config (macOS)
dotfiles-nix home       # Apply Home Manager config (any platform)
dotfiles-nix update     # Update flake inputs
dotfiles-nix check      # Check flake for errors
dotfiles-nix gc         # Garbage collect Nix store
dotfiles-nix shell      # Enter development shell
# or
make nix-install / make nix / make nix-home / etc.
```

### [validate-doc-links](validate-doc-links)

Validates local Markdown links across repository documentation.

**Usage:**
```bash
validate-doc-links          # Validate links from current directory
validate-doc-links /path    # Validate from specific repo path
# or
make verify-doc-links
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
| dotfiles-nix | ✓ | ✓ | ✓ |
