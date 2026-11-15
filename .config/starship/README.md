# Starship Configuration

Cross-shell prompt — the default prompt for these dotfiles, on macOS and
Omarchy alike.

## Why starship

- **Role:** Default shell prompt: fast single binary, one TOML file,
  actively developed, works in zsh/bash/fish alike.
- **Why not Powerlevel10k:** p10k (the previous prompt) is in maintenance
  mode — its author wound down active development. Its look is easy to get
  here without it.

## The default: Monochrome 43 powerline

[`starship.toml`](starship.toml) is a two-line powerline prompt in the
Monochrome 43 palette ([`.config/palette/monochrome-43.conf`](../palette/monochrome-43.conf)):

```text
 ~/code/app   main !+   3.13 (.venv)            5s   ✘ 1    14:02
❯
```

- **Left:** OS logo (and `user@host` over SSH or as root), the directory
  (three components, truncated to the repo root), git branch and status, and a
  language/runtime segment only when the directory has its files (Python,
  Node, Bun, Rust, Go, Lua, Zig).
- **Right:** how long the last command took (over 3s), its exit status
  (only on failure), and the time.
- White and grey segments on the black ground; the one colour is red, for a
  failed command, the `❯` after one, and root.

It needs a Nerd Font — JetBrainsMono Nerd Font, which Ghostty uses and both
machines install (`font-jetbrains-mono-nerd-font` in the Caskfile; Omarchy
ships it). Without one the caps and icons render as boxes.

It stays fast: `command_timeout = 500`, no module in `format` runs a
command unless the directory calls for it, and the slow defaults (package
versions, cloud and Kubernetes contexts) are left out. `make bench-shell`
times shell start-up; `starship timings` shows the per-module cost of a
prompt.

## Alternatives

| File | What | Selected by |
| --- | --- | --- |
| [`danse.toml`](danse.toml) | the previous default: the lean p10k layout (`user@host dir git duration` / `venv ❯`) in the danse palette | `danse` in `~/.config/palette/rice.local` (see `.config/zsh/rice.zsh`) |
| [`monochrome-43.toml`](monochrome-43.toml) | the same lean layout in Monochrome 43 colours, after [43PR/dotfiles](https://github.com/43PR/dotfiles) (MIT) | `export STARSHIP_CONFIG="$HOME/.config/starship/monochrome-43.toml"` in `~/.config/zsh/zshrc.local` |

`zshrc.local` is sourced last, so it beats `rice.local`.

## Upstream

- <https://starship.rs> · <https://starship.rs/config/>
