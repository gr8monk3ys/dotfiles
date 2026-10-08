# windows

The Omarchy layout for machines that stay on Windows 11: keyboard-driven
tiling with Omarchy's Super-key bindings, a top bar, and the same `danse`
palette as macOS and Arch. Windows has no `make` or Stow, so
[`setup.ps1`](setup.ps1) is this directory's `make link`.

| Piece | Tool | Config |
| --- | --- | --- |
| Tiling, workspaces, borders | [GlazeWM](https://github.com/glzr-io/glazewm) | [`glazewm/config.yaml`](glazewm/config.yaml) |
| Top bar | [Zebar](https://github.com/glzr-io/zebar) | [`zebar/`](zebar/README.md) |
| Terminal theme and font | Windows Terminal fragment | [`windows-terminal/`](windows-terminal/README.md) |
| Launcher | PowerToys Command Palette | its own default hotkey, Super+Alt+Space |
| Shell | WSL Arch | the rest of this repo, linked inside WSL as usual |

Packages come from [`install/wingetfile`](../install/wingetfile), read through
`bin/manifest` like every other manifest.

## Setup

From a normal (not elevated) PowerShell, in the checkout that should stay:

```powershell
.\windows\setup.ps1                 # status only
.\windows\setup.ps1 -Apply -Start   # install missing packages, link, start tiling
.\windows\setup.ps1 -Remove         # undo the links and stop GlazeWM
```

`-Apply` changes, all per user and all undone by `-Remove`:

- **HKCU Run value `GlazeWM`**: starts GlazeWM at sign-in with
  `--config <checkout>\windows\glazewm\config.yaml`. Edits take effect on
  Super+Shift+Alt+R; nothing is copied.
- **`%USERPROFILE%\.glzr\zebar\danse`**: a directory junction into
  `windows\zebar\danse`, plus Zebar's `settings.json` (an existing one is kept
  as `settings.json.bak-<date>` and restored by `-Remove`).
- **Windows Terminal fragment** in
  `%LOCALAPPDATA%\Microsoft\Windows Terminal\Fragments\dotfiles\`: adds the
  `danse` scheme and sets it and the font on the `Arch` profile, without
  touching Terminal's own `settings.json`.

- **The look**: taskbar auto-hide (only the Zebar bar shows, as in Omarchy),
  dark mode, the palette's `blue` as accent colour — the whole `AccentPalette`,
  so Start and the taskbar follow it — and the La Danse wallpaper that
  [`bin/wallpaper`](../bin/wallpaper) builds at the screen's resolution (needs
  ImageMagick, from the wingetfile). Each original value is saved once under
  `HKCU\Software\dotfiles\windows-setup` before the first change; `-Remove`
  puts it back and deletes that key. Wallpaper Engine, if running, draws over
  the desktop and can reset the accent; quit it to see this one.

Run it from a normal PowerShell or Windows Terminal window. A shell spawned by
an MSIX-packaged app (the Claude desktop app is one) inherits that app's
sandbox: its `HKCU` writes and new `AppData` files go to the app's private
copy, so the Run value and colours would exist only inside that app. The
script detects this — it creates a probe folder in `%LOCALAPPDATA%` and checks
whether it lands in `Packages\<app>\LocalCache` — and refuses to change
anything.

Not automated: turning off Snap (Settings → System → Multitasking) if its
Win+arrow layouts get in the way.

## Keys

Super is the Windows key. The left column is Omarchy's binding.

| Keys | Action |
| --- | --- |
| Super+Return | Terminal (new Windows Terminal window, Arch profile) |
| Super+Alt+Space | Launcher (Command Palette) |
| Super+Shift+B | Browser |
| Super+Shift+F | File manager |
| Super+W | Close window |
| Super+T | Toggle floating |
| Super+F | Fullscreen |
| Super+J | Toggle tiling direction |
| Super+Arrows | Move focus |
| Super+Shift+Arrows | Move window |
| Super+- / Super+= | Narrower / wider (Shift: shorter / taller) |
| Super+1..9 | Go to workspace |
| Super+Shift+1..9 | Move window to workspace and follow |
| Super+Tab / Super+Shift+Tab | Next / previous workspace |
| Super+Ctrl+Tab | Last-used workspace |
| Super+Shift+Alt+Left/Right | Move workspace to the other monitor |
| Super+Shift+Alt+R | Reload the config |
| Super+Shift+Alt+P | Pause / resume tiling (the bar shows PAUSED) |
| Super+Shift+Alt+E | Quit GlazeWM |

GlazeWM's keyboard hook takes these before Explorer does, so the Windows
shortcuts they replace (Widgets, Feedback Hub, Task View, pinned-app launch)
are gone while it runs. Win+L (lock) and Win+R (Run) are left alone.

## What does not carry over from Hyprland

- No animations, blur or rounded-corner control beyond Windows 11's own.
- Windows running as administrator (UAC prompts, an elevated Task Manager)
  cannot be tiled by a GlazeWM that is not itself elevated.
- Exclusive-fullscreen games are not managed. Press Super+Shift+Alt+P before
  playing, and again after.
- Omarchy's menus (Super+Space system menu, theme picker) have no equivalent
  here; the palette is fixed to `danse`.
