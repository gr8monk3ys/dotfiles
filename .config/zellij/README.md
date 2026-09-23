# zellij

[Zellij](https://zellij.dev/documentation/), the primary multiplexer. tmux
(`.config/tmux/`) is the backup for remote hosts.

## Why these choices

- **tmux muscle memory:** `keybinds clear-defaults=true` drops Zellij's own
  mode keys (which steal `Ctrl-p`, `Ctrl-n`, `Ctrl-o` and more from the
  programs inside) and replaces them with a single `Ctrl-Space` prefix, the
  same as `tmux.conf`, followed by tmux's keys: `|` and `-` split, `h/j/k/l`
  move, `c`/`n`/`p` for tabs, `d` detaches, `[` scrolls, `w` opens the
  session manager. The full list is `config.kdl`.
- **`default_layout "compact"`:** one status line instead of two bars.
- **`copy_on_select`** into the system clipboard, and a 50 000-line
  scrollback.
- **Colours** are the `custom` theme in `config.kdl`, a region rendered from
  the danse palette by `bin/palette`.

## Gotchas

- `copy_command "pbcopy"` is macOS-only. On Linux, copying fails until it is
  changed to `wl-copy` or `xclip -selection clipboard`.
