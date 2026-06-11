# .local/bin Scripts

Personal utility scripts for system administration, development workflows, and automation.

## Overview

These scripts are designed for personal use and are symlinked to `~/.local/bin/` via Stow. Most scripts are platform-specific (Linux or macOS) and may require additional dependencies.

## Scripts

### System Configuration

#### [macos-defaults](macos-defaults)
Applies comprehensive macOS system preferences and defaults.

**Platform:** macOS only

**What it configures:**
- General UI/UX (transparency, animations, save dialogs)
- Keyboard settings (fast key repeat, disable auto-correct)
- Trackpad (tap to click, natural scrolling)
- Finder (show hidden files, path bar, status bar)
- Dock (auto-hide, icon size, hot corners)
- Safari (privacy settings, developer tools)
- Mail, Messages, Photos preferences
- SSD optimizations

**Usage:**
```bash
macos-defaults
```

**Warning:** Requires sudo. Will restart affected applications. Review the script before running.

---

### Security & Authentication

#### [yubikey-ssh-setup](yubikey-ssh-setup)
Configures a YubiKey smartcard for SSH authentication using GPG.

**Platform:** Linux/macOS

**What it does:**
1. Creates temporary GNUPGHOME with secure config
2. Imports master GPG key
3. Generates signing, encryption, and authentication subkeys
4. Moves subkeys to YubiKey smartcard
5. Updates card holder information
6. Exports public key for upload

**Required environment variables:**
- `KEYID` or `GPGKEY` - Your GPG key ID
- `EMAIL` or `GMAIL` - Your email address

**Optional variables:**
- `SUBKEY_LENGTH` (default: 2048)
- `SUBKEY_EXPIRE` (default: 0, never expires)
- `SURNAME`, `GIVENNAME`, `SEX`
- `PUBLIC_KEY_URL`

**Usage:**
```bash
export KEYID="0x1234567890ABCDEF"
export EMAIL="you@example.com"
yubikey-ssh-setup
```

#### [setup-tor-iptables](setup-tor-iptables)
Configures iptables rules for routing traffic through Tor.

**Platform:** Linux only

**Warning:** Modifies system firewall rules. Use with caution.

#### [tor-exit-threat-score](tor-exit-threat-score)
Checks the threat level/reputation of Tor exit nodes.

**Platform:** Linux/macOS

---

### Development Tools

#### [check-go-repos](check-go-repos)
Checks status of Go repositories in your workspace.

**Platform:** Linux/macOS

#### [generate-go-project-files](generate-go-project-files)
Scaffolds a new Go project with standard directory structure.

**Platform:** Linux/macOS

#### [generate-md-toc](generate-md-toc)
Generates a table of contents for Markdown files.

**Platform:** Linux/macOS

**Usage:**
```bash
generate-md-toc README.md
```

#### [openprs](openprs)
Opens pull requests in browser or lists open PRs for a repository.

**Platform:** Linux/macOS

---

### Repository Management

#### [update-repos](update-repos)
Automatically updates all git repositories in your home directory.

**Platform:** Linux/macOS

**What it does:**
1. Finds all `.git` directories up to 2 levels deep from HOME
2. Runs `git pull` in each repository
3. Executes repo-specific update commands:
   - `.vim`: `make update`
   - `dotfiles`: `make`
   - `configs`: `make dotfiles update`
   - `jenkins-dsl`: `make`
   - `j3ssb0t`: `make archive model`

**Usage:**
```bash
update-repos
```

---

### Docker & Containers

#### [cleanup-non-running-images](cleanup-non-running-images)
Removes Docker images that are not associated with running containers.

**Platform:** Linux/macOS (requires Docker)

**Usage:**
```bash
cleanup-non-running-images
```

---

### Virtual Machines

#### [createvm](createvm)
Creates virtual machines (likely using libvirt/QEMU or similar).

**Platform:** Linux

---

### Display & Hardware

#### [monitor-hotplug](monitor-hotplug)
Handles monitor connection/disconnection events for automatic display configuration.

**Platform:** Linux (X11/Wayland)

#### [screen-backlight](screen-backlight)
Controls screen backlight brightness.

**Platform:** Linux

**Usage:**
```bash
screen-backlight up
screen-backlight down
screen-backlight set 50
```

---

### Desktop Environment

#### [fancy-i3lock](fancy-i3lock)
Enhanced i3 lock screen with blur effect or custom styling.

**Platform:** Linux (i3wm)

#### [browser-exec](browser-exec)
Wrapper for executing browser commands, useful for default browser handling.

**Platform:** Linux

---

### Firmware & System Updates

#### [update-firmware](update-firmware)
Updates system firmware (likely using fwupd on Linux).

**Platform:** Linux

#### [update-iwlwifi](update-iwlwifi)
Updates Intel WiFi (iwlwifi) firmware.

**Platform:** Linux

---

### Kernel Configuration

#### [check-kconfig](check-kconfig)
Verifies kernel configuration options.

**Platform:** Linux

---

### Package Management

#### [slackpm](slackpm)
Slack package manager integration or Slack-related utilities.

**Platform:** Linux/macOS

---

### Installation

#### [install.sh](../../install.sh)
Installation script (repo root) for setting up the dotfiles or related tools.

**Platform:** Linux/macOS

---

## Adding to PATH

These scripts are automatically added to PATH via `.zshenv`:

```bash
if [[ -d "$HOME/.local/bin" ]]; then
  export PATH="$HOME/.local/bin:$PATH"
  for dir in "$HOME/.local/bin"/*(/N); do
    export PATH="$PATH:$dir"
  done
fi
```

## Making Scripts Executable

Ensure all scripts are executable:

```bash
chmod +x ~/.local/bin/*
```

## Platform Compatibility

| Script | Linux | macOS | Notes |
|--------|:-----:|:-----:|-------|
| macos-defaults | - | Yes | macOS system preferences |
| yubikey-ssh-setup | Yes | Yes | Requires GPG, YubiKey |
| setup-tor-iptables | Yes | - | Requires iptables |
| tor-exit-threat-score | Yes | Yes | |
| check-go-repos | Yes | Yes | Requires Go |
| generate-go-project-files | Yes | Yes | |
| generate-md-toc | Yes | Yes | |
| openprs | Yes | Yes | Requires gh CLI |
| update-repos | Yes | Yes | |
| cleanup-non-running-images | Yes | Yes | Requires Docker |
| createvm | Yes | - | Requires libvirt/QEMU |
| monitor-hotplug | Yes | - | X11/Wayland |
| screen-backlight | Yes | - | |
| fancy-i3lock | Yes | - | Requires i3wm |
| browser-exec | Yes | - | |
| update-firmware | Yes | - | Requires fwupd |
| update-iwlwifi | Yes | - | Intel WiFi only |
| check-kconfig | Yes | - | |
| slackpm | Yes | Yes | |
| install.sh | Yes | Yes | |

## Dependencies

Common dependencies across scripts:
- **bash** or **zsh** - Shell
- **git** - Version control
- **gpg2** - GPG encryption (for YubiKey)
- **docker** - Container runtime
- **gh** - GitHub CLI

## Security Notes

- Scripts requiring sudo will prompt for password
- `macos-defaults` makes system-wide changes
- `yubikey-ssh-setup` handles sensitive key material
- `setup-tor-iptables` modifies firewall rules
- Always review scripts before running with elevated privileges

## Contributing

When adding new scripts:
1. Add shebang (`#!/usr/bin/env bash`)
2. Use `set -e` and `set -o pipefail` for error handling
3. Add header comment with description and usage
4. Document in this README
5. Make executable: `chmod +x script-name`
6. Test on target platform
