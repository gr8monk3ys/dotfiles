# SketchyBar Configuration

Floating macOS status bar with AeroSpace workspace integration.

## Features

- **Workspace indicators** — shows AeroSpace workspaces (1-9), highlights active
- **Calendar** — date and time display (right side)
- **Apple menu** — popup with System Preferences, Activity Monitor, Lock Screen

## Design

- **Position:** Top, floating with rounded corners
- **Colors:** Catppuccin Mocha palette (matches Ghostty/Neovim)
- **Font:** SF Pro (ships with macOS)

## File Structure

```
sketchybar/
├── sketchybarrc          # Main config — bar appearance, loads items
├── colors.sh             # Catppuccin Mocha color palette
├── icons.sh              # Nerd Font icon constants
├── items/
│   ├── apple.sh          # Apple logo popup menu
│   ├── spaces.sh         # AeroSpace workspace indicators
│   └── calendar.sh       # Date/time display
└── plugins/
    └── aerospacer.sh     # Workspace change event handler
```

## AeroSpace Integration

AeroSpace triggers SketchyBar updates via `exec-on-workspace-change` in
`aerospace.toml`. The `aerospacer.sh` plugin highlights the active workspace.

## Installation

```bash
brew install sketchybar
# or via nix-darwin (already in darwin.nix)
```

## Extending

To add new items (e.g., CPU, battery, media):

1. Create a new file in `items/`
2. Source it from `sketchybarrc`
3. Add any event handlers in `plugins/`
