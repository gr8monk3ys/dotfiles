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

Each `<name>.conf` here is one palette, and the one place its colours are
defined. Each palette is one **Rice**'s (`rice.sh` is the Rice module), and
every themed tool follows the active rice (ADR 0003). `bin/palette` reads
the active rice's palette by default; `PALETTE=<name>` picks another
(`palette palettes` lists them).

| Palette | Rice | Where |
| --- | --- | --- |
| `monochrome-43` | the default on macOS | macOS and Omarchy |
| `field-notebook` | the default on Omarchy | Omarchy |
| `danse` | opt-in | macOS; also `windows/` |

## Choosing the rice

One word in `~/.config/palette/rice.local` (gitignored, per machine), else
the platform default:

```bash
echo danse > ~/.config/palette/rice.local   # macOS: opt in to danse
rm ~/.config/palette/rice.local             # back to the platform default
```

Then open a new shell (and restart Neovim). Read at start-up by SketchyBar
(`colors.sh`), borders (`bordersrc`), Neovim (`nvim/lua/palette.lua`) and the
shell (`zsh/rice.zsh`), which points every CLI tool at its rice's file. On
Omarchy the desktop, Ghostty and btop follow the Omarchy theme instead
(`make omarchy`). `test/test_rice.bats` boots each reader.

## Roles and the rendered themes

The CLI tools' themes are written once, in `templates/`, in **roles**
instead of colours: `{{blue}}`, `{{comment:rgb}}`. The roles are danse's
colour names (every template began as a danse theme). `<rice>.roles` says
which of that rice's colours fills each role; danse's map is the identity,
so danse renders exactly as before.

`bin/rice-themes render` writes one file per tool per rice
(`bin/rice-themes list` shows them); the output is committed, and
`test_palette.bats` runs `bin/rice-themes check`, which fails on a stale or
hand-edited output. To change a tool's look, edit its template and render.

| Template | Rendered to | Picked by |
| --- | --- | --- |
| `bat.tmTheme` | `bat/themes/<rice>.tmTheme` | `BAT_THEME` |
| `delta.gitconfig` | `git/delta/<rice>.gitconfig` | `DELTA_FEATURES=rice-<rice>` |
| `eza-theme.yml` | `eza/rices/<rice>/theme.yml` | `EZA_CONFIG_DIR` |
| `zsh.zsh` | `zsh/rices/<rice>.zsh` (highlight, autosuggest, fzf, `EZA_COLORS`) | sourced by `rice.zsh` |
| `yazi-theme.toml` | `yazi/rices/<rice>/theme.toml` | `YAZI_CONFIG_HOME` |
| `atuin.toml` | `atuin/themes/<rice>.toml` | `ATUIN_THEME__NAME` |
| `zellij.kdl` | `zellij/themes/<rice>.kdl` | the `zellij` shell function |
| `zathurarc` | `zathura/rices/<rice>/zathurarc` | the `zathura` shell function |
| `starship.toml` | `starship/<rice>.toml` (not Monochrome 43, which has its own) | `STARSHIP_CONFIG` |

The environment variables and functions are set in `zsh/rice.zsh`, so an
app started outside a shell gets its file default.

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

## monochrome-43

Pure black ground, white text, greys for structure, and colour only where it
means something (errors, warnings, the one blue accent). Taken from
[43PR/dotfiles](https://github.com/43PR/dotfiles) (MIT), its
`.config/43pr/themes/default.toml`; see the header of
[`monochrome-43.conf`](monochrome-43.conf) for the two departures. The ANSI
slots are 43PR's terminal colours, so `ansi-*` names exist only here.

## Usage

```bash
palette list                      # name<TAB>hex<TAB>role
palette names                     # names only
palette get blue                  # #61afef
palette get blue --format 0x      # 0xff61afef   (sketchybar)
palette get blue --format rgb     # 97;175;239   (EZA_COLORS and other SGR)
palette get blue --format raw     # 61afef
palette export SB                 # SB_BLUE='#61afef' ...
PALETTE=monochrome-43 palette get fg   # #ffffff
palette palettes                  # danse, field-notebook, monochrome-43
PALETTE=field-notebook palette role green   # #42a979 (the pen)
palette roles                     # role<TAB>colour<TAB>hex for the rice
```

The examples without `PALETTE=` assume the active rice is danse.

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
- bat caches compiled themes. After rendering, run `bat cache --build` or
  bat keeps painting the old ones (and does not know a new rice's name).
