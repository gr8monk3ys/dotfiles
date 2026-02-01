# Automated Dotfiles Sync Design

**Date:** 2026-01-31
**Status:** Approved

## Overview

Implement automated daily sync for dotfiles using macOS launchd, with native notifications.

## Requirements

- **Frequency:** Daily at 10:00 AM
- **Scope:** Git pull only (fast, safe, minimal disruption)
- **Notifications:** macOS native notifications via osascript
- **Behavior:** Silent when no updates, notifies on changes or errors

## Components

### 1. Sync Script (`bin/dotfiles-sync`)

Lightweight script optimized for automated runs:
- Pulls git changes only
- Handles uncommitted changes gracefully (skips with notification)
- Sends macOS notifications via osascript
- Silent when already up to date
- Exits cleanly for launchd

### 2. LaunchAgent Plist (`.config/macos/com.dotfiles.sync.plist`)

Stored in dotfiles, symlinked to `~/Library/LaunchAgents/`:
- Runs daily at 10:00 AM using StartCalendarInterval
- Catches up if Mac was asleep at scheduled time
- Errors logged to `/tmp/dotfiles-sync.err`

### 3. Makefile Integration

New targets:
- `make sync-install` - Enable automated sync
- `make sync-uninstall` - Disable automated sync
- `make sync-status` - Check if service is running
- `make sync-run` - Run sync manually

## File Locations

| File | Location |
|------|----------|
| Sync script | `bin/dotfiles-sync` |
| Plist template | `.config/macos/com.dotfiles.sync.plist` |
| Installed plist | `~/Library/LaunchAgents/com.dotfiles.sync.plist` |
| Error log | `/tmp/dotfiles-sync.err` |

## Implementation Notes

- Plist uses absolute paths (required by launchd)
- `sed` templating replaces username during install
- Service can be enabled/disabled without removing dotfiles changes
