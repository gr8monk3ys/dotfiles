# zathura

Keyboard-driven PDF viewer, with the MuPDF backend (`zathura-pdf-mupdf`). On
macOS it comes from the `homebrew-zathura` tap; on Arch from pacman.

## Why these choices

- **Colours are the danse palette**, rendered into `zathurarc` by
  `bin/palette` from `.config/palette/templates/`. `recolor` is on, so pages
  are drawn in the terminal's own ground and foreground; `i` toggles it back
  to the document's real colours. `recolor-keephue` keeps figures and
  highlighted text recognisable while recoloured.
- **`J`/`K` zoom** rather than page, and `R` rotates, freeing `r` to reload a
  document that a build (latexmk) has just rewritten.
- **`selection-clipboard clipboard`**: a mouse selection goes to the system
  clipboard, not the X primary selection.
- **No GUI chrome** (`guioptions ""`): no status or input bar until needed.

## Gotchas

- `scroll-step` is set twice; the later `50` wins over the `0.01` above it.
- The font is `inconsolata 15`, which no manifest installs, so zathura falls
  back to a default font until Inconsolata is present.
- Colour values are rendered: edit
  `.config/palette/templates/.config/zathura/zathurarc`, then
  `bin/palette render`. `make lint` fails on a hand edit.
