# spicetify

A Monochrome 43 theme for the Spotify desktop client, applied with
[Spicetify](https://spicetify.app/). After
[43PR/dotfiles](https://github.com/43PR/dotfiles) (MIT), which uses
Spicetify's `text` theme with its Monochrome scheme; this one is built from
[`.config/palette/monochrome-43.conf`](../.config/palette/monochrome-43.conf).

## Why it is not under `.config/`

Stow would link `.config/spicetify` into `~/.config` and, on a machine where
that directory does not exist yet, fold it into this checkout. Spicetify
then writes its own state there — `config-xpui.ini` (with the local Spotify
paths) and a backup of Spotify's app files — inside the repo. So the theme
lives here and is linked into Spicetify's own directory by hand. Nothing
here runs unless you run it.

## Install

`spicetify-cli` is opt-in and deliberately in no install manifest, so
`make macos` and `make arch` never install it. Install it by hand:
`brew install spicetify-cli` on macOS, `yay -S spicetify-cli` on Arch
(AUR-only). Spotify itself must be installed and opened once.

```bash
spicetify                                   # first run creates its config
themes="$(dirname "$(spicetify -c)")/Themes"
mkdir -p "$themes"
ln -s ~/.dotfiles/spicetify/Themes/monochrome-43 "$themes/monochrome-43"
spicetify config current_theme monochrome-43 color_scheme Monochrome
spicetify backup apply
```

Undo with `spicetify restore`. After a Spotify update, re-run
`spicetify backup apply`.

On Arch with Spotify from the AUR, Spicetify needs write access to the
Spotify install (`/opt/spotify`); see the Linux notes in the Spicetify docs:
<https://spicetify.app/docs/>.

## Spotify Stats

[spicetify-stats](https://github.com/harbassan/spicetify-stats) is a custom
app with top tracks, artists and genres. Install it from the Spicetify
Marketplace, or by hand: download the latest release from that repository,
unpack it as `stats` in the `CustomApps` directory beside `Themes`, then:

```bash
spicetify config custom_apps stats
spicetify apply
```

## Files

| File | What |
| --- | --- |
| [`Themes/monochrome-43/color.ini`](Themes/monochrome-43/color.ini) | the `Monochrome` scheme; bare hex, every value a palette colour (`test/test_palette.bats`) |
| [`Themes/monochrome-43/user.css`](Themes/monochrome-43/user.css) | JetBrainsMono Nerd Font and square corners |
