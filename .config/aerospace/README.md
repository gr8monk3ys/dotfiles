# AeroSpace Configuration

This directory contains the configuration for [AeroSpace](https://github.com/nikitabobko/AeroSpace), a tiling window manager for macOS.

## Files

- `aerospace.toml` - Main configuration file for AeroSpace window manager

## What is AeroSpace?

AeroSpace is an i3-like tiling window manager for macOS that provides:
- Automatic window tiling and management
- Keyboard-driven window navigation and manipulation
- Workspace management for organizing windows
- Monitor-aware window placement

## Configuration Overview

### Key Features Enabled

- **Start at Login**: AeroSpace launches automatically when you log in
- **Container Normalization**: Automatic layout optimization for nested containers
- **No Gaps**: Windows are tiled without spacing (gaps set to 0)
- **Mouse Follows Focus**: Mouse automatically moves when switching monitors

### Keyboard Shortcuts

#### Layout Management
- `Alt+/` - Toggle between horizontal and vertical tiling
- `Alt+,` - Set horizontal tiling layout
- `Alt+Cmd+M` - Decrease window size
- `Alt+Cmd+I` - Increase window size

#### Workspace Navigation
- `Alt+1-9` - Switch to workspace 1-9
- `Alt+Shift+1-9` - Move current window to workspace 1-9
- `Alt+Shift+Tab` - Move workspace to next monitor

#### Special Workspaces
- `Alt+P` - Go to PDF workspace
- `Alt+Shift+K` - Go to KeePass workspace
- `Alt+Shift+F` - Go to Finder workspace

### Automatic Window Placement

The configuration automatically routes applications to specific workspaces:
- **Workspace 1**: Alacritty (Terminal)
- **Workspace 2**: Firefox (Web Browser)
- **Workspace 3**: Spotify (Music)
- **Workspace K**: KeePassXC (Password Manager)
- **Workspace F**: Finder (File Manager)
- **Workspace G**: Messages
- **Workspace M**: iMovie
- **Workspace D**: Figma
- **Workspace Z**: Mail
- **Workspace P**: PDF viewers (Zathura)

## Usage

After installation, AeroSpace will start automatically and begin managing your windows according to the configuration. Use the keyboard shortcuts to navigate between workspaces and manage window layouts.

## Resources

- [AeroSpace Documentation](https://nikitabobko.github.io/AeroSpace/)
- [AeroSpace Commands Reference](https://nikitabobko.github.io/AeroSpace/commands)
