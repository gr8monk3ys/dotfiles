# Perfect Reproducibility Setup Guide

This guide explains how to achieve 100% reproducible development environment on a new device.

## The Vision

When you get a new machine, you should be able to run a single command and have your exact development environment ready - same tools, same versions, same configurations.

## Two Installation Paths

### Path 1: Quick Start (Traditional)

Best for: Quick setup, macOS-focused, simpler to understand

```bash
# One command does everything
curl -fsSL https://raw.githubusercontent.com/gr8monk3ys/dotfiles/main/install.sh | bash
```

**Pros:**
- Familiar tools (Homebrew)
- Faster initial setup
- Easier to debug

**Cons:**
- Versions may drift over time
- Harder to rollback
- macOS-focused

### Path 2: Full Reproducibility (Nix)

Best for: Perfect reproducibility, multi-platform, version locking

```bash
# Clone and apply
git clone https://github.com/gr8monk3ys/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
make nix-install  # Install Nix (one-time)
make nix          # Apply configuration
```

**Pros:**
- 100% reproducible
- Version-locked packages
- Easy rollback
- Cross-platform
- Declarative

**Cons:**
- Steeper learning curve
- Larger disk usage
- Slower first build

## Recommended Setup Flow

### For macOS (New Machine)

```bash
# 1. Install Xcode Command Line Tools
xcode-select --install

# 2. Clone dotfiles
git clone https://github.com/gr8monk3ys/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# 3. Install Nix
make nix-install
# Restart terminal after installation

# 4. Apply full configuration
make nix

# This will:
# - Install all packages via Nix
# - Set up Homebrew for GUI apps (casks)
# - Configure macOS system preferences
# - Set up Home Manager for dotfiles
# - Apply shell configuration
```

### For Linux (Any Distro)

```bash
# 1. Clone dotfiles
git clone https://github.com/gr8monk3ys/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# 2. Install Nix
make nix-install
# Restart terminal

# 3. Apply Home Manager configuration
make nix-home

# This gives you the same CLI tools on any Linux distro!
```

## What Gets Configured

### System-Level (nix-darwin, macOS only)
- macOS defaults (Dock, Finder, keyboard)
- Homebrew casks (GUI apps)
- System fonts (Nerd Fonts)
- Touch ID for sudo

### User-Level (Home Manager, cross-platform)
- All CLI tools (eza, bat, fd, ripgrep, etc.)
- Shell configuration (Zsh, aliases, integrations)
- Git configuration (delta, aliases)
- Jujutsu configuration
- Editor (Neovim reference)
- Terminal (Ghostty reference)

## Keeping Synchronized

### After Making Changes

```bash
# 1. Edit configuration files
vim ~/.dotfiles/nix/home.nix

# 2. Apply changes
make nix  # or make nix-home

# 3. Commit changes
cd ~/.dotfiles
git add -A
git commit -m "feat: update configuration"
git push
```

### On Another Machine

```bash
cd ~/.dotfiles
git pull
make nix  # Apply updated configuration
```

### Updating Packages

```bash
# Update all Nix inputs to latest
make nix-update

# Apply updates
make nix

# Commit lock file
git add flake.lock
git commit -m "chore: update flake inputs"
```

## Rollback

One of Nix's killer features - instant rollback:

```bash
# List generations
darwin-rebuild --list-generations  # macOS
home-manager generations           # Any platform

# Rollback to previous
darwin-rebuild --rollback          # macOS
# Or switch to specific generation
darwin-rebuild switch --generation 42
```

## Machine-Specific Configuration

### Using Flake Configurations

The flake defines multiple configurations:
- `macbook` - Apple Silicon Mac
- `macbook-intel` - Intel Mac
- `linux` - x86_64 Linux
- `linux-arm` - ARM64 Linux

### Local Overrides

For machine-specific settings not in git:

```bash
# Create local Zsh config
echo 'export WORK_SECRET="..."' > ~/.config/zsh/zshrc.local

# Create local Git config
cat > ~/.config/git/config.local << EOF
[user]
    signingkey = YOUR_KEY
EOF
```

## Quick Reference

| Task | Command |
|------|---------|
| First-time setup (macOS) | `make nix` |
| First-time setup (Linux) | `make nix-home` |
| Update packages | `make nix-update && make nix` |
| Apply changes | `make nix` |
| Rollback | `darwin-rebuild --rollback` |
| Clean old generations | `make nix-gc` |
| Check for errors | `make nix-check` |

## Troubleshooting

### "experimental-features" error
```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### Slow builds
First build downloads everything. Subsequent builds are fast due to caching.

### Homebrew conflicts
Nix and Homebrew can coexist. GUI apps go through Homebrew casks (managed by nix-darwin).

### Missing tool after switch
```bash
# Ensure PATH is correct
echo $PATH | tr ':' '\n' | grep nix

# Re-source shell
exec zsh
```

## Philosophy

1. **Declarative over imperative** - Describe what you want, not how to get it
2. **Version everything** - Lock files ensure reproducibility
3. **Single source of truth** - One repo for all machines
4. **Gradual adoption** - Traditional install works, Nix when ready
5. **Escape hatches** - Local overrides for machine-specific needs

---

Ready to set up a new machine? Start with `make nix` and your environment will be exactly as you left it.
