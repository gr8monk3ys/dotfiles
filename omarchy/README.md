# omarchy

The Omarchy layer: the rices for an Omarchy 4.x desktop, and the desktop
settings that go with them. Like [`windows/`](../windows/README.md), it sits
outside `.config/` on purpose: Omarchy owns `~/.config/hypr` and
`~/.config/omarchy`, so stowing them would fight `omarchy update`.
[`setup.sh`](setup.sh) places individual files and drives Omarchy's own
commands instead. It is this directory's `make link`.

## Rices

A **Rice** is one desktop look. Which one a machine shows is decided by the
Rice module, [`.config/palette/rice.sh`](../.config/palette/rice.sh): one
word in the gitignored `~/.config/palette/rice.local`, else the platform
default. On Omarchy:

- **Field Notebook** (the default): lscaturchio.xyz at night, night paper
  and one forest-green pen.
- **Monochrome 43**: black, white and greys, after
  [43PR/dotfiles](https://github.com/43PR/dotfiles) (MIT).

`--rice <name>` (or `$OMARCHY_RICE`) picks another for one run.

Each rice is a directory, [`rices/<rice>/`](rices/), and `setup.sh` acts on
whatever it ships; no step names a rice. Adding a rice is adding a directory
plus one line in the Rice module's table.

| In `rices/<rice>/` | Lands in |
| --- | --- |
| `theme/` (`colors.toml`, `icons.theme`) | `~/.config/omarchy/themes/<rice>/` (symlinks) |
| `backgrounds` (executable, optional) | fills the theme's `backgrounds/` when `backgrounds --check` fails: Field Notebook renders its plates (~35 MB, not tracked); Monochrome 43 copies Vantablack's and fetches 43PR's wallpaper by pinned URL and SHA-256 |
| `hypr.lua` | `~/.config/hypr/<rice_with_underscores>.lua` (symlink), loaded by one `require` line in `looknfeel.lua`; another rice's line is removed |
| `hypr/` (optional) | `~/.config/hypr/` (symlinks); Field Notebook's night-light schedule |
| `packages.pacman`, `packages.aur` (optional) | `omarchy pkg add` / `omarchy pkg aur add`, missing ones only; read through `bin/manifest list rice-pacman` / `rice-aur` |
| `hooks/<event>.d/` (optional) | `~/.config/omarchy/hooks/<event>.d/` (symlinks) |
| `bin/`, `share/` (optional) | `~/.local/bin/`, `~/.local/share/<rice>/` (symlinks); Field Notebook's `fn-*` session scripts and `themed.py`, which re-themes cava, spotify_player, Firefox and gh-dash on every `theme-set` |
| `branding/` (optional) | `~/.config/omarchy/branding/` (symlinks); screensaver art |

Field Notebook's `hypr.lua` also carries glass on every app, the workspace-1
master layout, and `fn-session` and `hyprsunset` at login.

## Desktop settings (every rice)

| Piece | File | Lands in |
| --- | --- | --- |
| Shell plugins | [`plugins.tsv`](plugins.tsv) | `~/.config/omarchy/plugins/<id>`, via `omarchy plugin add`, pinned |
| Bar | [`bar.json`](bar.json) | position via `omarchy bar position`; layout merged into `~/.config/omarchy/shell.json` |
| Idle | [`idle.json`](idle.json) | `.idle` in `~/.config/omarchy/shell.json`: screensaver after 150 s, auto-lock off (`0`), so the display never turns itself off |
| Theme hooks | [`hooks/`](hooks/) | `~/.config/omarchy/hooks/<event>.d/` (symlinks) |
| Ghostty | [`ghostty.conf`](ghostty.conf) | included from `~/.config/ghostty/config.local` by one appended line: zsh as the terminal's command, Omarchy's font size, keybinds and `async-backend` |

## Use

```bash
make omarchy                 # dry run: what would change
make omarchy apply=1         # do it
make omarchy only=hypr       # one step: packages | extras | hooks | theme | plugins | bar | idle | hypr | ghostty
make omarchy rice=monochrome-43   # another rice, this run only
omarchy/setup.sh --help
```

On a machine where `bin/platform is-omarchy` is false the dry run says so
and exits 0; `apply=1` refuses. A second run reports everything as `ok`.

What `apply=1` changes, and how to undo it:

- **Theme**: `omarchy theme set <rice>` if it is not already current.
  Switch back with `omarchy theme set <name>`. Any file a link would replace
  that is not identical is kept as `<file>.dotfiles-bak` (the shared
  `bin/lib/plan.sh` rule).
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
- **Ghostty**: appends `config-file = <checkout>/omarchy/ghostty.conf` to
  `~/.config/ghostty/config.local`; delete that line to undo. Skipped while
  `/usr/bin/zsh` is missing. Omarchy's own `~/.config/ghostty/config` never
  reads `config.local`, so setup also appends `config-file = ?"config.local"`
  to it (the repo's config already has that line).

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
| Dynamic Island | ofa14-prog/omarchy-dynamic-island | no (installed only) |
| Omaudix | qempexe/omarchy-omaudix | yes |
| Segue | SteveB98/omarchy-segue | yes |
| Hardware Monitor | meviusisback/omarchy-hw-monitor | yes |
| Agent Skills Manager | oliwier-xiao/agent-skills-manager | yes |
| 60Hz Audio Spectrum | pennyfx/omarchy-spectrum | no (installed only) |
| Agent Usage | robzolkos/omarchy-agent-usage | yes |
| Colophon | ssandys/colophon | yes |
| Spaces | tornikegomareli/omarchy-spaces | yes |
| OMCP | btsouth/omarchy-omcp | yes |
| Omastorm | wesleygrimes/omastorm | yes |
| OmaqBT | Aweiward/omaqbt | yes |

`gr8monk3ys.sysstats` (CPU, memory, temperature), `superwhisper.panel` and
`io.voxtype.settings` (each shipped by its app's package) are `external` in
`plugins.tsv`: it is maintained outside this repo, and
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
- The matching macOS look (SketchyBar, borders, AeroSpace gaps) is the
  default there too: see
  [`.config/sketchybar/README.md`](../.config/sketchybar/README.md).

## Not automated

- Field Notebook's own wallpapers under `~/.config/omarchy/backgrounds/`
  (the Monet and Shishkin paintings) are not tracked; copy them by hand.
- Spotify sign-in for `spotify_player` (its `client_id` in
  `~/.config/spotify-player/app.toml`) is a secret and stays local.

- The terminal configs come from `make link`, not from here. Ghostty and
  btop follow the Omarchy theme; the editor (Neovim, and the Strudel
  profile), the prompt and the CLI tools (bat, delta, eza, fzf, zsh
  highlighting, yazi, atuin, zellij, zathura) follow the active Rice through
  `.config/zsh/rice.zsh` and `bin/rice-themes` (ADR 0003), so on Field
  Notebook they wear the same night paper and pen.
- Spotify theming: see [`spicetify/README.md`](../spicetify/README.md).
