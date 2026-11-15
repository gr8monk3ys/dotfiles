# 0003: Every themed tool follows the active Rice

Status: accepted (2026-11-14). Supersedes 0002.

## Context

ADR 0002 kept the CLI tools (bat, eza, zellij, yazi, atuin, delta, the zsh
highlight styles, fzf, Neovim) on danse whatever the desktop rice was, and
kept `bin/palette`'s default at danse to match. On an Omarchy machine that
meant a Field Notebook desktop (night paper, one forest-green pen) with a
OneDark editor and prompt inside it. The shell also asked the Rice module
for the rice with no platform, so on Omarchy it got `monochrome-43`, not
the `field-notebook` the desktop showed.

The ask is that everything look seamless: whatever the desktop rice is, the
editor and every CLI tool wear it too.

## Decision

The active Rice is the one answer for every themed tool. Concretely:

- The Rice module detects its own platform (`rice_platform`, builtins only),
  so `rice_select` with no argument gives the same rice the desktop shows.
  `RICE_PLATFORM` overrides the detection (tests, unusual machines).
- `bin/palette` with no `PALETTE=` reads the active rice's palette.
- The tools' colours are written once, as templates in danse's colour names
  (`.config/palette/templates/`). Danse's names are the **role** vocabulary;
  each rice maps every role to one of its own colours in
  `.config/palette/<rice>.roles`. `bin/rice-themes render` writes one file
  per tool per rice; the output is committed, and `bin/rice-themes check`
  (run by BATS) fails when an output is stale or hand-edited.
- Each tool picks its rice's file with the smallest mechanism it supports:
  an environment variable set by `.config/zsh/rice.zsh` (bat, delta, eza,
  atuin, yazi, starship), a shell function for the bare command (zellij,
  zathura), or reading the palette at start-up (Neovim, via the Rice module).
- On Omarchy, apps Omarchy already themes from the rice's `colors.toml`
  (Ghostty, btop, the desktop) stay on Omarchy's mechanism; `colors.toml` is
  itself checked against the rice's palette.

## Consequences

- Switching rice is one word in `rice.local` plus a new shell (and a Neovim
  restart); nothing is regenerated per machine.
- Danse's role map is the identity, so danse renders exactly as before.
- A new themed file is a template plus one line in `bin/rice-themes`'s
  target table plus one line per rice in `test_palette.bats`'s coverage list
  (ADR 0001 still holds).
- Apps started outside a shell (a PDF opened from the file manager in
  zathura, a GUI-launched lazygit) do not see the shell's environment and
  fall back to their file default.
