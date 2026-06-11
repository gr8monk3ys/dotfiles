# Starship Configuration

Cross-shell prompt — the default prompt for these dotfiles.

## Why starship

- **Role:** Default shell prompt: fast single binary, one TOML file,
  actively developed, works in zsh/bash/fish alike.
- **Why not stay on Powerlevel10k:** p10k is in maintenance mode (its
  author wound down active development). It still works and remains the
  **automatic fallback** — `.zshrc` falls back to p10k whenever the
  `starship` binary is missing, so bare machines keep a good prompt.
- The layout deliberately replicates the previous lean p10k prompt
  (`user@host dir git duration` / `venv ❯`) so the migration is visually
  quiet. Colors are the repo-wide OneDark palette with a transparent
  background (Ghostty frosted glass shows through).

## Switching back to p10k

Per machine (file is gitignored):

```bash
echo p10k > ~/.config/zsh/prompt.local
```

Delete the file (or write `starship` into it) to return to Starship.
The p10k config lives on at [`../zsh/.p10k.zsh`](../zsh/.p10k.zsh).

## Upstream

- <https://starship.rs> · <https://starship.rs/config/>
