# palette

The colour palette every themed tool in this checkout draws from.

## Why this exists

The palette used to be the same six hex literals re-typed in ten files:
`sketchybar/colors.sh`, `starship/starship.toml`, `zellij/config.kdl`,
`yazi/theme.toml`, `eza/theme.yml`, `atuin`'s theme, `.zshrc`'s highlight
styles, `git/config`'s delta colours, `bin/lib/ui.sh`, and a vendored bat
`.tmTheme`. Nothing connected them, so "everything matches" was a claim no
command could check — and a retune that rewrote every hex occurrence of the
old red still left it behind in `.zshenv`, where `EZA_COLORS` spells colours
as decimal SGR triples that a hex grep cannot see.

(The retired values themselves are not quoted here on purpose: they live in
the Makefile's `verify-stale-refs` pattern, which fails the build on any copy
left anywhere under `.config`, `bin` or `.zshenv` — including in prose.)

`danse.conf` is the one place a colour is defined. `bin/palette` reads it.

## The palette

Structurally OneDark. Two accents and two fills are tuned to Henri Matisse,
_La Danse_ (1910, Hermitage) — also the desktop background, see `bin/wallpaper`.
The painting's three fields were sampled from the source scan:

| Field | Sampled |
| --- | --- |
| Ultramarine sky | `#274063` `#31486d` `#243958` |
| Vermilion figures | `#b34931` `#b43e29` |
| Viridian ground | `#476a62` |

Those values are too dark for terminal text, so the two accent roles take the
painting's *hue* at OneDark's luminance, and the two fill roles take the
sampled colour unchanged and are used only for chrome.

Run `palette list` for the current table.

## Usage

```bash
palette list                      # name<TAB>hex<TAB>role
palette names                     # names only
palette get blue                  # #61afef
palette get blue --format 0x      # 0xff61afef   (sketchybar)
palette get blue --format rgb     # 97;175;239   (EZA_COLORS and other SGR)
palette get blue --format raw     # 61afef
palette export SB                 # SB_BLUE='#61afef' ...
```

An unknown colour name is an error, not an empty string: a typo in a theme
should fail loudly rather than silently paint something black.

## Consumers

`sketchybar/colors.sh` reads `danse.conf` directly — sketchybar execs its
scripts with a minimal environment and this checkout's `bin/` is not reliably
on that `PATH`, and the file is two fields and a comment character.

The rest carry their own copies because their formats differ and always will
(kdl, toml, yaml, plist, `0xaarrggbb`). What keeps them honest is
`test/test_palette.bats` plus the retired hexes in the Makefile's
`verify-stale-refs` pattern: retiring a colour means adding its old hex there,
so a copy left behind anywhere fails the build.

## Gotchas

- `ultramarine` and `viridian` are **fills, not text colours**. Against the
  `bg` ground they sit at 1.4:1 and 2.3:1; foreground text on top of them
  reaches 4.6:1 and 2.8:1 respectively. Use them behind text, never as text.
- Changing a hex here changes nothing on its own. Propagate it, then run
  `make verify` — the drift tests and the stale-ref grep are what catch a
  half-finished retune.
- bat caches compiled themes. After editing `bat/themes/danse.tmTheme`, run
  `bat cache --build` or bat keeps painting the old one.
