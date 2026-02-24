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

### [dotfiles-template](dotfiles-template)

Template processor for machine-specific configurations.

**Usage:**
```bash
dotfiles-template --list              # List variables
dotfiles-template config.tmpl config  # Process template
dotfiles-template --dry-run file.tmpl # Preview
```

**Variables:** `{{HOSTNAME}}`, `{{OS_TYPE}}`, `{{MACHINE_TYPE}}`, `{{USER}}`, `{{HOME}}`

### [dotfiles-secrets](dotfiles-secrets)

Secret management using age encryption.

**Usage:**
```bash
dotfiles-secrets init                    # Initialize
dotfiles-secrets encrypt ~/.ssh/config   # Encrypt
dotfiles-secrets decrypt file.age        # Decrypt
dotfiles-secrets edit file.age           # Edit in-place
dotfiles-secrets status                  # Show status
```

**Requires:** `age` (`brew install age`)

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
| dotfiles-worktree | ✓ | ✓ | ✓ |
| dotfiles-template | ✓ | ✓ | ✓ |
| dotfiles-secrets | ✓ | ✓ | ✓ |
