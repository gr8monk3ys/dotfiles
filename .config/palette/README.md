# palette

The colour palette every themed tool in this checkout draws from.

## Why this exists

The palette used to be the same hex literals re-typed in fifteen files, in
three spellings (`#61afef`, `0xff61afef` for sketchybar, `97;175;239` in
`EZA_COLORS`). Nothing connected them, so "everything matches" was a claim no
command could check: a retune that rewrote every hex still left the decimal
copy behind in `.zshenv`, and colours that were never on the palette at all
(zathura's whole scheme, bat's base16 greys) slipped in unnoticed.

`danse.conf` is the one place a colour is defined, and `bin/palette` is the
only thing that reads it. Every themed file is **rendered** from a template.

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
painting's _hue_ at OneDark's luminance, and the two fill roles take the
sampled colour unchanged and are used only for chrome.

`danse.conf` is the current table.

## Templates, render, check

```bash
palette render    # rewrite every rendered file from its template
palette check     # exit 1 with a diff if any rendered file is stale (make verify-palette)
palette fill      # expand slots on stdin, for scripts: printf '{{blue:rgb}}' | palette fill
```

A template lives under `templates/`, at the path of the file it renders
relative to the checkout root: `templates/.config/ghostty/themes/danse`
renders `.config/ghostty/themes/danse`. Colours are slots:

| Slot | Renders | For |
| --- | --- | --- |
| `{{blue}}` | `#61afef` | most config formats |
| `{{blue:0x}}` | `0xff61afef` | sketchybar, JankyBorders |
| `{{blue:rgb}}` | `97;175;239` | SGR truecolor: `EZA_COLORS`, `install.sh` |

The rendered files stay committed at their real paths, because stow links
them and the tools read them. Two shapes:

- **Whole file** — pure theme files (ghostty and btop themes, atuin, eza,
  yazi, the bat tmTheme, sketchybar's `colors.sh`, `bordersrc`, nvim's
  `lua/palette.lua`). The template is the file.
- **Region** — files where colours are a few lines of a hand-edited whole
  (`.zshrc`, `.zshenv`, `install.sh`, `bin/lib/ui.sh`, git, ghostty's config,
  cava, zellij, zathura, starship's `[palettes.danse]` table). The file keeps
  a `palette:begin` / `palette:end` comment pair, and the template fills only
  the lines between them; edit the rest of the file normally.

`check` fails on a hand-edited rendered file, a literal colour typed into a
template, and a slot naming a colour or format that does not exist.
`test_palette.bats` additionally fails on a colour literal anywhere outside
rendered output, so a new theme cannot type one in unseen.

To retune: change the hex in `danse.conf`, run `palette render`, commit
both. To theme a new tool: write its template, run `palette render`.

## Gotchas

- `ultramarine`, `viridian` and the two `diff-*` colours are **fills, not text
  colours**. Against the `bg` ground `ultramarine` and `viridian` sit at 1.4:1
  and 2.3:1; foreground text on top of them reaches 4.6:1 and 2.8:1
  respectively. Use them behind text, never as text.
- bat caches compiled themes. After a render changes `bat/themes/danse.tmTheme`,
  run `bat cache --build` or bat keeps painting the old one.
- Running tools pick up a render on their own schedule: restart Ghostty's
  config (`cmd+shift+,`), sketchybar and borders, and open a new shell.
- `bin/wallpaper` keys its cached image on the two matte colours, so a retune
  of `bg-dark` or `ultramarine` rebuilds it; run `wallpaper` to set it.
