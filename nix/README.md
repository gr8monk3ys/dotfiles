# Nix Configuration

This directory contains Nix flake configuration for **fully reproducible** system setup.

## Overview

The Nix configuration provides:
- **Home Manager** - User environment (packages, dotfiles, shell config)
- **nix-darwin** - macOS system configuration (defaults, Homebrew, fonts)
- **Flakes** - Reproducible, version-locked dependencies

## Prerequisites

### Install Nix

```bash
# Official installer (recommended)
sh <(curl -L https://nixos.org/nix/install)

# Or Determinate Systems installer (better macOS support)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

### Enable Flakes

Add to `~/.config/nix/nix.conf`:
```
experimental-features = nix-command flakes
```

## Quick Start

### First-time Setup (macOS)

```bash
cd ~/.dotfiles

# Build and switch to the configuration
# This will install Homebrew, configure macOS defaults, and set up Home Manager
nix run nix-darwin -- switch --flake .#macbook

# For Intel Macs
nix run nix-darwin -- switch --flake .#macbook-intel
```

### First-time Setup (Linux)

```bash
cd ~/.dotfiles

# Apply Home Manager configuration
nix run home-manager -- switch --flake .#lorenzo@linux

# For ARM64
nix run home-manager -- switch --flake .#lorenzo@linux-arm
```

### Daily Usage

```bash
# Update and apply changes (macOS)
darwin-rebuild switch --flake ~/.dotfiles

# Update and apply changes (Linux)
home-manager switch --flake ~/.dotfiles

# Update all flake inputs
nix flake update

# Enter development shell
nix develop
```

## Configuration Structure

```
nix/
├── home.nix      # Home Manager config (cross-platform)
├── darwin.nix    # macOS-specific system config
└── README.md     # This file

flake.nix         # Main flake definition
flake.lock        # Version-locked dependencies
```

## Customization

### Adding Packages

Edit `flake.nix` and add to `commonPackages`:
```nix
commonPackages = pkgs: with pkgs; [
  # ... existing packages
  your-new-package
];
```

### Adding macOS Applications

Edit `nix/darwin.nix` under `homebrew.casks`:
```nix
casks = [
  # ... existing casks
  "your-new-app"
];
```

### Changing macOS Defaults

Edit `nix/darwin.nix` under `system.defaults`:
```nix
defaults = {
  dock.autohide = true;
  # Add more defaults
};
```

### User Configuration

Edit `flake.nix` and update the `user` attribute:
```nix
user = {
  name = "Your Name";
  email = "your@email.com";
  username = "yourusername";
  github = "yourgithub";
};
```

## Benefits Over Traditional Dotfiles

| Feature | Traditional | Nix |
|---------|------------|-----|
| Reproducibility | Partial | 100% |
| Version locking | Manual | Automatic |
| Rollback | Difficult | Built-in |
| Cross-platform | Manual | Unified |
| Declarative | No | Yes |
| Atomic updates | No | Yes |

## Commands Reference

```bash
# System commands (macOS)
darwin-rebuild switch --flake .         # Apply system config
darwin-rebuild build --flake .          # Build without applying
darwin-rebuild check --flake .          # Check for errors

# Home Manager commands
home-manager switch --flake .           # Apply user config
home-manager generations                # List generations
home-manager expire-generations 30d     # Remove old generations

# Flake commands
nix flake update                        # Update all inputs
nix flake update nixpkgs                # Update specific input
nix flake show                          # Show flake outputs
nix flake check                         # Validate flake

# Development
nix develop                             # Enter dev shell
nix build                               # Build default package
nix run .#switch-home                   # Run switch script

# Cleanup
nix-collect-garbage -d                  # Remove all old generations
nix store gc                            # Garbage collect store
nix store optimise                      # Deduplicate store
```

## Troubleshooting

### "experimental-features" error
```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### Homebrew conflicts
If Homebrew packages conflict with Nix:
```bash
# Remove Homebrew version
brew uninstall <package>

# Let Nix manage it instead
darwin-rebuild switch --flake .
```

### Rollback
```bash
# List generations
darwin-rebuild --list-generations

# Rollback to previous
darwin-rebuild --rollback

# Rollback to specific generation
darwin-rebuild switch --generation <number>
```

## Resources

- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [nix-darwin Manual](https://daiderd.com/nix-darwin/manual/)
- [Nix Flakes](https://nixos.wiki/wiki/Flakes)
- [Zero to Nix](https://zero-to-nix.com/)
