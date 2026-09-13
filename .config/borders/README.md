# borders

[JankyBorders](https://github.com/FelixKratz/JankyBorders) draws the
focused-window border macOS does not.

## Why

Under a tiling window manager the border is how you know where focus is.
AeroSpace moves focus with the keyboard, without moving the mouse, and macOS
gives an unfocused window almost no visual distinction — so without this, the
answer to "which window will my next keystroke go to" is a guess.

## Colours

From [`.config/palette/danse.conf`](../palette/danse.conf), as `0xAARRGGBB`:

| Role | Palette name | Value |
| --- | --- | --- |
| Focused | `blue` | `0xff61afef` |
| Everything else | `surface` | `0xff3e4451` |

## Lifecycle

Launched from `aerospace.toml`'s `after-startup-command`, **not** as a brew
service, so window-manager chrome starts and stops with the window manager.
`brew services start borders` would leave borders drawn on a machine where
AeroSpace is not running, which is worse than no borders at all.

Restart it by restarting AeroSpace:

```bash
aerospace reload-config          # config only
killall borders; aerospace reload-config
```

## Gotchas

- Needs Screen Recording permission on first run — macOS asks, and until it is
  granted the process runs but draws nothing.
- `width` is in points, not pixels; `hidpi=on` is what makes it crisp on a
  Retina display.
