# SketchyBar Configuration

macOS status bar with AeroSpace workspace integration, in the Monochrome 43
rice whose Omarchy half lives in `omarchy/` at the repo root.

## Features

- **Workspace indicators** — shows AeroSpace workspaces (1-9), highlights active
- **Calendar** — date and time display (right side)
- **Apple menu** — popup with System Settings, Activity Monitor, Lock Screen

## Design (Monochrome 43, the default)

- **Position:** a slim (28pt) flat pure-black strip flush with the top edge
- **Colors:** white on black, an inverted active workspace, colour only for
  warning/error (from
  [`.config/palette/monochrome-43.conf`](../palette/monochrome-43.conf))
- **Font:** JetBrainsMono Nerd Font (the one Ghostty uses)

AeroSpace's gaps (`inner` 4, `outer` 8, `outer.top` 36 = 28 + 8) are sized
for this bar.

## danse (opt back in)

The older look — a floating, rounded, blurred 37pt bar in the OneDark-based
[`danse`](../palette/danse.conf) palette with SF Pro — is one word in a
gitignored file away. It switches this bar, `borders` and the starship prompt:

```bash
echo danse > ~/.config/palette/rice.local
sketchybar --reload; killall borders; aerospace reload-config
```

Delete the file to go back. AeroSpace's gaps are not switched (TOML has no
conditionals); for the danse bar set `inner.* = 8` and `outer.top = 45` in
`aerospace.toml` by hand.

## File Structure

```
sketchybar/
├── sketchybarrc          # Main config — bar appearance, loads items
├── colors.sh             # palette -> role names (rice.local picks the palette)
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
