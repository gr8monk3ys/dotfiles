# Karabiner-Elements Configuration

System-wide Vim-style navigation for macOS.

## Key Mappings

| From | To | Notes |
| --- | --- | --- |
| Left Ctrl + h/j/k/l | Arrow keys | Works with any additional modifier (Shift for selection, etc.) |
| Right Cmd + h/j/k/l | Arrow keys | Alternative modifier for convenience |

## Caps Lock

Caps Lock is remapped to Control in macOS System Settings (Keyboard → Modifier Keys),
**not** in Karabiner, to avoid conflicts. This means Caps Lock + hjkl gives you
arrow keys everywhere.

## Installation

```bash
brew install --cask karabiner-elements
```

Karabiner reads from `~/.config/karabiner/karabiner.json` by default (XDG-compliant).
