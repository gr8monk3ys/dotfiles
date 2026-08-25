#!/usr/bin/env bash
# Rebuild the Dock with the daily apps from install/Caskfile.
# Apps that are not installed are skipped with a note, so this is safe to run
# on a machine that has only some of them.
#
# Usage: ./dock.sh          (restarts the Dock at the end)

set -euo pipefail

if ! command -v dockutil >/dev/null 2>&1; then
    echo "dock.sh: dockutil not found. Install it with: brew install dockutil" >&2
    echo "         (it is listed in install/Brewfile; 'brew bundle' installs it too)" >&2
    exit 1
fi

apps=(
    "/Applications/Ghostty.app"
    "/Applications/Zen.app"
    "/Applications/Firefox.app"
    "/Applications/Brave Browser.app"
    "/Applications/VSCodium.app"
    "/Applications/Obsidian.app"
    "/Applications/KeePassXC.app"
    "/Applications/TIDAL.app"
    "/System/Applications/System Settings.app"
)

dockutil --no-restart --remove all >/dev/null

for app in "${apps[@]}"; do
    if [[ -d "$app" ]]; then
        dockutil --no-restart --add "$app" >/dev/null
    else
        echo "skip (not installed): $app"
    fi
done

killall Dock
