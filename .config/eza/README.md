# eza

The `ls` replacement: `ls`, `l`, `ll` and `lt` are eza with icons, Git
status and directories first when eza is installed, and plain `ls` when it
is not (`.config/zsh/aliases.zsh`).

## Colours

Themed from the danse palette in two places, both rendered by `bin/palette`:
`EZA_COLORS` in `.zshenv`, and `theme.yml` here. Edit the templates under
`.config/palette/templates/`, not these files.

## Gotchas

- **`theme.yml` is inert on Homebrew's eza.** The bottle is built without
  theme support (`eza --version` lists only `[+git]`), and eza then ignores
  `theme.yml` silently, malformed YAML included. `EZA_COLORS` is what that
  build honours, so it is the one that applies on macOS; `theme.yml` stays
  for builds that read it. `test_shell_boot.bats` asserts a booted shell's
  eza really colours directories from the palette.
- `EZA_COLORS` is exported from `.zshenv`, so eza run outside a zsh that read
  it is uncoloured.
