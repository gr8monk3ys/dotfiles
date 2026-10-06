# ghostty

[Ghostty](https://ghostty.org/docs/config), the primary terminal. Splits and
tabs are Ghostty's own (`Cmd`-based keybinds in `config`); Zellij runs inside
it when a session has to survive the window.

## Why these choices

- **Keybinds for many panes at once:** `Cmd+D` / `Cmd+Shift+D` split,
  `Cmd+H/J/K/L` move between splits, resize and equalize keys, and a zoom
  toggle to read one pane full-size. The full list is the `keybind` lines in
  `config`.
- **Frosted glass over a painting:** the desktop is _La Danse_
  (`bin/wallpaper`), so opacity is 0.86 rather than the usual 0.8, and
  `background-opacity-cells` stops cells with their own background from
  showing as opaque patches.
- **JetBrains Mono Nerd Font** (installed by the Caskfile) with ligatures on
  and 20% extra line height.
- **`macos-option-as-alt`**, so Option works as Meta in zsh, Neovim and
  Zellij.
- **Colours:** `theme = danse` loads `themes/danse`, and the chrome colours
  (split fill, divider, Dock icon) are a region of `config`. Both are
  rendered from the palette by `bin/palette`; edit the templates under
  `.config/palette/templates/`.

## Gotchas

- Changes need a config reload (`Cmd+Shift+,`) or a restart;
  `ghostty +validate-config` catches typos first.
- Background blur on Linux depends on the compositor.
- On Omarchy the login shell stays bash; OPERATING.md § Arch: Omarchy says
  how to start zsh from Ghostty instead.
