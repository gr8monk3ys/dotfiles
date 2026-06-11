# Atuin Configuration

SQLite-backed shell history with fuzzy search — replaces plain `ctrl-r`.

## Why atuin

- **Role:** Searchable, context-rich shell history (exit code, duration,
  directory) shared across sessions. Initialized from
  [`.config/zsh/.zshrc`](../zsh/.zshrc) when installed.
- **Why not mcfly / plain HISTFILE:** atuin's filtering (by directory,
  host, exit status) and optional end-to-end-encrypted sync are stronger;
  the classic `HISTFILE` is still written as a fallback.

## Configuration choices

- `config.toml` keeps defaults except the theme; **sync is not enabled** —
  run `atuin register` / `atuin login` per machine if you want it.
- `themes/onedark.toml` matches the repo-wide OneDark palette (same hexes
  as the README theme table and `FZF_DEFAULT_OPTS`).

## Upstream

- <https://atuin.sh> · <https://docs.atuin.sh>
