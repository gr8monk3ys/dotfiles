# omarchy

The Omarchy layer: the **Monochrome 43** rice for an Omarchy 4.x desktop,
after [43PR/dotfiles](https://github.com/43PR/dotfiles) (MIT). Like
[`windows/`](../windows/README.md), it sits outside `.config/` on purpose:
Omarchy owns `~/.config/hypr` and `~/.config/omarchy`, so stowing them would
fight `omarchy update`. [`setup.sh`](setup.sh) places individual files and
drives Omarchy's own commands instead. It is this directory's `make link`.

| Piece | File | Lands in |
| --- | --- | --- |
| Theme colours | [`themes/monochrome-43/colors.toml`](themes/monochrome-43/colors.toml) | `~/.config/omarchy/themes/monochrome-43/` (symlink) |
| Icon theme | [`themes/monochrome-43/icons.theme`](themes/monochrome-43/icons.theme) | same (symlink) |
| Backgrounds | not tracked | copied from Omarchy's Vantablack theme, plus 43PR's wallpaper fetched by URL and SHA-256 checked |
| Hyprland look | [`hypr/monochrome_43.lua`](hypr/monochrome_43.lua) | `~/.config/hypr/monochrome_43.lua` (symlink), loaded by one `require` line appended to `looknfeel.lua` |
| Shell plugins | [`plugins.tsv`](plugins.tsv) | `~/.config/omarchy/plugins/<id>`, via `omarchy plugin add`, pinned |
| Bar | [`bar.json`](bar.json) | position via `omarchy bar position`; layout merged into `~/.config/omarchy/shell.json` |

## Use

```bash
make omarchy                 # dry run: what would change
make omarchy apply=1         # do it
make omarchy only=hypr       # one step: theme | plugins | bar | hypr
omarchy/setup.sh --help
```

On a machine where `bin/platform is-omarchy` is false the dry run says so
and exits 0; `apply=1` refuses. A second run reports everything as `ok`.

What `apply=1` changes, and how to undo it:

- **Theme**: `omarchy theme set monochrome-43` if it is not already current.
  Switch back with `omarchy theme set <name>`. A differing `colors.toml`
  already there is kept as `colors.toml.dotfiles-bak`.
- **Plugins**: each missing plugin is added with `omarchy plugin add <url>
  --yes`, then checked out at its pinned commit and re-validated; installed
  ones are moved to their pin only when their tree is clean. Enabled when
  marked `yes`. Note `plugin add` clones the default branch first, so the
  pinned checkout happens a moment after the clone — the plugin is not
  enabled in between.
- **Bar**: `shell.json` is copied to `shell.json.dotfiles-bak.<epoch>`, then
  only `.bar.layout` is replaced (other keys keep their values and order);
  restore that file to undo.
- **Hypr**: if `looknfeel.lua` already holds a pasted copy of the rice (the
  `riceOut` curve), setup warns and does not add the `require` — delete the
  pasted block first, or the look is applied twice.

## Plugins and pins

Plugins run as unsandboxed code inside the long-lived `omarchy-shell`
process. Each third-party plugin is pinned to the commit that was reviewed
before it was installed. Do not run `omarchy plugin update` on them — it
moves them to the latest commit. To take an update: review the diff, change
the commit in `plugins.tsv`, run `make omarchy apply=1 only=plugins`.

| Plugin | Repo | Enabled |
| --- | --- | --- |
| Exposé | kristofferR/omarchy-expose | yes |
| Rice Bar | jcarcinogen/omarchy-rice-bar | no (installed only) |
| Dynamic Island | ofa14-prog/omarchy-dynamic-island | yes |
| Omaudix | qempexe/omarchy-omaudix | yes |
| Segue | SteveB98/omarchy-segue | yes |
| Hardware Monitor | meviusisback/omarchy-hw-monitor | yes |
| Agent Skills Manager | oliwier-xiao/agent-skills-manager | yes |
| 60Hz Audio Spectrum | pennyfx/omarchy-spectrum | yes |
| Agent Usage | robzolkos/omarchy-agent-usage | yes |
| Colophon | ssandys/colophon | yes |
| Spaces | tornikegomareli/omarchy-spaces | yes |
| OMCP | btsouth/omarchy-omcp | yes |

`gr8monk3ys.sysstats` (CPU, memory, temperature) is placed by `bar.json`
but is `external` in `plugins.tsv`: it is maintained outside this repo, and
`setup.sh` never creates, replaces, links or enables its directory. Without
it installed, its bar slot is simply empty.

## The look

- Black ground, white text, greys for structure:
  [`.config/palette/monochrome-43.conf`](../.config/palette/monochrome-43.conf)
  is the source; `colors.toml` uses only its colours (checked by
  `test/test_palette.bats`).
- Hyprland: gaps 4 inside, 8 at the edges (5 at the top), 1px borders,
  8px rounding, light blur and shadow, quick ease-out window animations and
  vertical slide-fade workspaces — 43PR's `look.lua` values. Border colours
  come from the theme.
- Bar on the left (`bar.json`).
- The matching macOS look is opt-in: see
  [`.config/sketchybar/README.md`](../.config/sketchybar/README.md).

## Not automated

- The terminal configs' Monochrome 43 variants (Ghostty, Starship, fastfetch,
  cava, btop) are opt-in per machine; their READMEs under `.config/` say how.
  Ghostty already follows the Omarchy theme once this repo's config is linked.
- Spotify theming: see [`spicetify/README.md`](../spicetify/README.md).
