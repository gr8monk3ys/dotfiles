# macOS Configuration

macOS-specific scripts and settings. Nothing here runs automatically; apply by
hand on a new machine after `brew bundle`.

## Files

- `defaults.sh` - user-level `defaults write` settings (no sudo)
- `dock.sh` - rebuilds the Dock from the daily apps in `install/Caskfile`
- `com.dotfiles.sync.plist` - LaunchAgent for the periodic dotfiles sync
- `.env.macos`, `.screenrc` - macOS-only shell environment and `screen` settings

## defaults.sh

About 30 settings, all in user preference domains, all idempotent, verified
against macOS 26. What it sets:

- **Keyboard**: fastest key repeat, short initial delay, hold-to-repeat instead
  of the accent popup, no auto-capitalisation / smart quotes / smart dashes /
  auto-period / spelling correction.
- **Trackpad**: tap to click (built-in and Bluetooth trackpads).
- **Finder**: show all extensions, path bar, status bar, list view by default,
  search the current folder, no "change extension?" warning, folders first,
  no `.DS_Store` on network shares or USB volumes.
- **Dock**: auto-hide with no delay and a fast animation, no recent apps,
  minimise into the app icon, scale effect.
- **Screenshots**: PNG, no window shadow, saved to `~/Pictures/screenshots`
  (created if missing).

It does not touch scroll direction, locale, timezone, hot corners or anything
that needs `sudo`.

```bash
DRY_RUN=1 ~/.config/macos/defaults.sh   # print every defaults write, change nothing
~/.config/macos/defaults.sh             # apply; restarts Finder, Dock, SystemUIServer
```

Keyboard and trackpad settings take effect after logging out and back in.

## dock.sh

Requires `dockutil` (`brew install dockutil`; it is in `install/Brewfile`) and
exits with an install hint if it is missing. Clears the Dock and pins, in
order: Ghostty, Zen, Firefox, Brave, VSCodium, Obsidian, KeePassXC, TIDAL,
System Settings. Apps that are not installed are skipped with a note rather
than failing. Restarts the Dock at the end.

```bash
~/.config/macos/dock.sh
```

## Discovering settings

```bash
defaults domains                     # list all domains
defaults read com.apple.dock         # dump one domain
defaults read com.apple.finder KEY   # read one key (errors if it was never set)
```

Most keys only appear in a domain after they have been written once, so a
missing key does not mean it is unsupported. Check
[macos-defaults.com](https://macos-defaults.com/) for what current macOS still
honours before adding anything.
