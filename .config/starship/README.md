# Starship Configuration

Cross-shell prompt — the default prompt for these dotfiles.

## Why starship

- **Role:** Default shell prompt: fast single binary, one TOML file,
  actively developed, works in zsh/bash/fish alike.
- **Why not Powerlevel10k:** p10k (the previous prompt) is in maintenance
  mode — its author wound down active development.
- The layout deliberately replicates the previous lean p10k prompt
  (`user@host dir git duration` / `venv ❯`) so the migration is visually
  quiet. Styles name palette roles and the hexes are rendered in from the
  danse palette by `bin/palette`; the background is transparent so
  Ghostty's frosted glass shows through.

## Upstream

- <https://starship.rs> · <https://starship.rs/config/>
