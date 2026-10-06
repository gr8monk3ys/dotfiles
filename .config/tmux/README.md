# tmux

The backup multiplexer. Zellij is primary (`.config/zellij/`); tmux stays for
SSH sessions and hosts where Zellij is not installed. tmux 3.1+ reads
`~/.config/tmux/tmux.conf` on its own. No plugins, no TPM: the file is
self-contained so it works on a bare remote box.

## Why these choices

- **Prefix `Ctrl-Space`**, not `Ctrl-b`, which shadows readline's
  back-one-character. `prefix r` reloads the config.
- **`escape-time 0`**: the default delay makes `Esc` in Neovim lag.
- **True colour** via `tmux-256color` plus the `Tc` override, so themes look
  the same inside and outside tmux.
- **Windows and panes count from 1** and renumber on close, matching the
  keyboard.
- **`detach-on-destroy off`**: killing a session (`prefix X`) drops you into
  another one instead of out of tmux.
- **Copy mode is vi**, and a copy goes to the system clipboard through
  `pbcopy`, `wl-copy` or `xclip`, whichever exists.

## Gotchas

- `Ctrl-k` is bound without the prefix to clear the screen _and_ scrollback,
  so it never reaches the program in the pane.
- Arrow keys are rebound to send themselves (`bind -n Up send-keys Up`), which
  overrides any terminal-level arrow handling inside tmux.
- On Omarchy, its installer writes its own `~/.config/tmux/tmux.conf`; move it
  aside before `make link` (OPERATING.md § Arch: Omarchy).
