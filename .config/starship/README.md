# Starship Configuration

Cross-shell prompt — the default prompt for these dotfiles.

## Why starship

- **Role:** Default shell prompt: fast single binary, one TOML file,
  actively developed, works in zsh/bash/fish alike.
- **Why not Powerlevel10k:** p10k (the previous prompt) is in maintenance
  mode — its author wound down active development.
- The layout deliberately replicates the previous lean p10k prompt
  (`user@host dir git duration` / `venv ❯`) so the migration is visually
  quiet. Colors are the repo-wide OneDark palette with a transparent
  background (Ghostty frosted glass shows through).

## Upstream

- <https://starship.rs> · <https://starship.rs/config/>

## Monochrome 43 (opt-in)

[`monochrome-43.toml`](monochrome-43.toml) keeps this layout with
[43PR/dotfiles](https://github.com/43PR/dotfiles) (MIT)'s colours: bold white directory, bright-black git/duration/venv, white
`❯`, red only on failure or root. They are ANSI names, so they follow the
terminal theme. Opt in per machine in `~/.config/zsh/zshrc.local`:

```bash
export STARSHIP_CONFIG="$HOME/.config/starship/monochrome-43.toml"
```
