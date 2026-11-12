# SketchyBar Configuration

Floating macOS status bar with AeroSpace workspace integration.

## Features

- **Workspace indicators** — shows AeroSpace workspaces (1-9), highlights active
- **Calendar** — date and time display (right side)
- **Apple menu** — popup with System Settings, Activity Monitor, Lock Screen

## Design

- **Position:** Top, floating with rounded corners
- **Colors:** OneDark palette (same hexes as Starship, zsh, Ghostty, Neovim)
- **Font:** SF Pro (ships with macOS)

## Monochrome 43 (opt-in)

The default look above is unchanged. One word in a gitignored file switches
this bar and `borders` to the Monochrome 43 rice whose Omarchy half lives in
`omarchy/` at the repo root:

```bash
echo monochrome-43 > ~/.config/palette/rice.local
sketchybar --reload; killall borders; aerospace reload-config
```

That gives a slim (28pt) flat pure-black strip flush with the top edge, white
JetBrainsMono Nerd Font text and icons, an inverted active workspace, and
colour only for warning/error (from
[`.config/palette/monochrome-43.conf`](../palette/monochrome-43.conf)). Delete
the file to go back. AeroSpace's gaps are not switched (TOML has no
conditionals); for the matching 4/8 spacing set `inner.* = 4` and
`outer.top = 36` in `aerospace.toml` by hand.

## File Structure

```
sketchybar/
├── sketchybarrc          # Main config — bar appearance, loads items
├── colors.sh             # OneDark color palette
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
```

## Extending

To add new items (e.g., CPU, battery, media):

1. Create a new file in `items/`
2. Source it from `sketchybarrc`
3. Add any event handlers in `plugins/`
