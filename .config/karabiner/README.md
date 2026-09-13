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

## The GUI rewrites this file

Karabiner-Elements rewrites `karabiner.json` when it launches: it canonicalises
key order and drops settings it now manages in-app (`global.show_in_menu_bar`
went this way). Because stow folds `.config/karabiner/` into the checkout, that
write lands **in the repo**, so `git status` will show it.

The remap rules survive — verified after first launch that all 8 manipulators
across both vim-navigation rules were byte-identical. Review the diff rather
than assuming, then commit it.

`automatic_backups/` and `assets/` are the GUI's own state and are gitignored.
