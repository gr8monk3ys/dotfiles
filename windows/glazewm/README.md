# glazewm

[GlazeWM](https://github.com/glzr-io/glazewm) tiles windows on Windows 11, in
the role Hyprland plays under Omarchy and AeroSpace plays on macOS.

## Why GlazeWM

- **Free for any use** (GPL-3.0). komorebi is closer to Hyprland — automatic
  splits, animations — but needs a paid licence for any work use.
- **Super-key bindings work**: its low-level hook claims `lwin+…` before
  Explorer, so Omarchy's bindings can be used as-is.
- **Config is one YAML file** read straight from this checkout
  (`glazewm start --config`), so there is nothing to copy or re-link.

## Choices

- **Bindings** are Omarchy's; the table is in [`../README.md`](../README.md).
  Nothing binds `lwin+alt+space`: that is Command Palette's launcher hotkey,
  and GlazeWM's hook would swallow it first.
- **Gaps** match `aerospace.toml`: 8px everywhere except the top, which clears
  the 32px Zebar bar.
- **Borders** match `borders/bordersrc`: focused `blue`, everything else
  `surface`, rounded corners. Every hex in `config.yaml` must be a palette
  colour; `test_palette.bats` checks it.
- **Floating by rule**: Task Manager, Settings, Calculator, loopMIDI and
  Explorer's copy-progress dialog, as Omarchy floats small utility windows.

## Lifecycle

Started at sign-in by the HKCU Run value `windows/setup.ps1 -Apply` writes.
GlazeWM starts Zebar on startup and stops it on exit, so the bar never outlives
the window manager. Logs: `%USERPROFILE%\.glzr\glazewm\errors.log`.
