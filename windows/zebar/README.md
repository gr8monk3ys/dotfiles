# zebar

[Zebar](https://github.com/glzr-io/zebar) draws the top bar, in the role of
Omarchy's Waybar and SketchyBar on macOS.

## Layout

Omarchy's Waybar arrangement: GlazeWM workspaces on the left (click to switch),
the clock in the centre, and on the right a PAUSED badge when tiling is paused,
the tiling direction (click to flip), network, CPU and memory. CPU and memory
turn `vermilion` above 85%.

## Files

- [`danse/`](danse/zpack.json) — the widget pack: `zpack.json` (one widget,
  `bar`, 32px tall across every monitor), `bar.html`, `styles.css`. Adapted
  from Zebar's own GlazeWM starter widget (also GPL-3.0).
- [`settings.json`](settings.json) — tells Zebar to open `danse/bar` at start.

`windows/setup.ps1` junctions `%USERPROFILE%\.glzr\zebar\danse` to `danse/`,
so edits here show up on the next Zebar start. Zebar itself is started and
stopped by GlazeWM.

## Colours

`styles.css` names its colours after the palette; every hex in it must be a
palette colour, which `test_palette.bats` checks.

## Network use

The widget loads React, Babel and the Nerd Font icon stylesheet from CDNs, the
way Zebar's starter does, and Zebar caches them for a week. With no network on
the very first start, the bar is blank until it can fetch them.
