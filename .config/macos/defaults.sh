#!/usr/bin/env bash
# macOS user defaults for a keyboard-driven setup (Ghostty + Karabiner +
# AeroSpace + sketchybar). Every setting here:
#   - exists on current macOS (verified against 26.x),
#   - lives in the user's own preference domains (no sudo),
#   - is idempotent: running it twice is the same as running it once.
#
# Usage:
#   ./defaults.sh              apply the settings, then restart Finder, Dock
#                              and SystemUIServer so they take effect
#   DRY_RUN=1 ./defaults.sh    print every `defaults write` instead of running it
#
# Deliberately left alone: scroll direction, locale, timezone, hot corners,
# anything under /Library or /System.

set -euo pipefail

DRY_RUN="${DRY_RUN:-0}"
SCREENSHOT_DIR="$HOME/Pictures/screenshots"

write() {
    if [[ "$DRY_RUN" == "1" ]]; then
        printf 'defaults write %s\n' "$*"
    else
        defaults write "$@"
    fi
}

run() {
    if [[ "$DRY_RUN" == "1" ]]; then
        printf '%s\n' "$*"
    else
        "$@"
    fi
}

# --- Keyboard ---------------------------------------------------------------
write NSGlobalDomain KeyRepeat -int 2                          # fastest repeat (lower = faster)
write NSGlobalDomain InitialKeyRepeat -int 15                  # short delay before repeat
write NSGlobalDomain ApplePressAndHoldEnabled -bool false      # hold-to-repeat, not accent popup
write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# --- Trackpad ---------------------------------------------------------------
write com.apple.AppleMultitouchTrackpad Clicking -bool true                   # tap to click
write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true  # ...on external trackpads too
write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# --- Finder -----------------------------------------------------------------
write NSGlobalDomain AppleShowAllExtensions -bool true
write com.apple.finder ShowPathbar -bool true
write com.apple.finder ShowStatusBar -bool true
write com.apple.finder FXPreferredViewStyle -string "Nlsv"     # list view
write com.apple.finder FXDefaultSearchScope -string "SCcf"     # search current folder
write com.apple.finder FXEnableExtensionChangeWarning -bool false
write com.apple.finder _FXSortFoldersFirst -bool true
write com.apple.desktopservices DSDontWriteNetworkStores -bool true  # no .DS_Store on network shares
write com.apple.desktopservices DSDontWriteUSBStores -bool true      # ...or USB volumes

# --- Dock -------------------------------------------------------------------
write com.apple.dock autohide -bool true
write com.apple.dock autohide-delay -float 0
write com.apple.dock autohide-time-modifier -float 0.15
write com.apple.dock show-recents -bool false
write com.apple.dock minimize-to-application -bool true
write com.apple.dock mineffect -string "scale"

# --- Screenshots ------------------------------------------------------------
run mkdir -p "$SCREENSHOT_DIR"
write com.apple.screencapture location -string "$SCREENSHOT_DIR"
write com.apple.screencapture type -string "png"
write com.apple.screencapture disable-shadow -bool true

# --- Apply ------------------------------------------------------------------
for app in Finder Dock SystemUIServer; do
    run killall "$app" 2>/dev/null || true   # not running is fine
done
echo "Done. Keyboard and trackpad changes apply after logging out and back in."
