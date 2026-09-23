# sketchybar

[SketchyBar](https://felixkratz.github.io/SketchyBar/), the floating status
bar (macOS), replacing the menu bar's role under AeroSpace. AeroSpace starts
it (`after-startup-command`), so it runs exactly when the window manager
does.

`sketchybarrc` sets the bar and sources one file per item from `items/`:
Apple menu, workspaces and the front app on the left; calendar, battery,
volume and CPU on the right. `plugins/` holds the scripts those items run
on their events.

## Why these choices

- **Workspace indicators are AeroSpace's**, not macOS Spaces: AeroSpace
  fires `aerospace_workspace_change` (`exec-on-workspace-change` in
  `aerospace.toml`) and `plugins/aerospacer.sh` highlights the focused one.
  `items/spaces.sh` draws 1–9, which is why `aerospace.toml` declares them
  persistent; `test_palette.bats` checks the two lists agree.
- **Floating, 37 points high**, which is what AeroSpace's `outer.top` gap of
  45 leaves room for.
- **Colours are role names** (`$BAR_COLOR`, `$FOREGROUND`, …) from
  `colors.sh`, which `bin/palette` renders from danse in `0xAARRGGBB`.

## Gotchas

- Labels are SF Pro, which ships with macOS. The icons in `icons.sh` are
  Nerd Font code points, whatever its header says about SF Symbols, so they
  draw only while a Nerd Font is installed (the Caskfile's JetBrains Mono).
- Changes need `sketchybar --reload`; a new item file does nothing until
  `sketchybarrc` sources it.
