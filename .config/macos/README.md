# macOS Configuration

This directory contains macOS-specific system configurations and settings.

## Files

- `defaults.sh` - Script to configure macOS system preferences via defaults command
- `dock.sh` - Script to configure macOS Dock settings
- `.env.macos` - Environment variables for macOS
- `.screenrc` - GNU Screen configuration

## What These Files Do

### defaults.sh

The `defaults.sh` script uses the macOS `defaults` command to programmatically set system preferences. This allows you to:
- Configure system settings that aren't easily accessible through GUI
- Ensure consistent settings across macOS installations
- Version control your system preferences
- Quickly apply preferred settings on a new machine

Common settings include:
- **Finder**: Show hidden files, file extensions, path bar
- **Dock**: Auto-hide behavior, icon size, animation speed
- **Keyboard**: Key repeat rates, function key behavior
- **Trackpad**: Tracking speed, gestures
- **Mission Control**: Hot corners, spaces behavior
- **Security**: Require password after sleep
- **UI**: Appearance, dark mode, menu bar items

### dock.sh

The `dock.sh` script specifically manages Dock configuration:
- Add/remove applications from the Dock
- Set Dock position (left, bottom, right)
- Configure Dock size and magnification
- Set up persistent applications
- Clear and rebuild Dock from scratch

This ensures a consistent Dock setup across machines.

### .env.macos

Environment variables specific to macOS:
- macOS-specific paths
- Homebrew configuration
- Application preferences
- System-specific settings

Typically sourced by shell configuration files when running on macOS.

### .screenrc

Configuration for [GNU Screen](https://www.gnu.org/software/screen/), a terminal multiplexer:
- Key bindings
- Status bar configuration
- Window management
- Session behavior

While tmux is more commonly used today, Screen is a lighter alternative available on many systems by default.

## Usage

### Applying System Preferences

```bash
# Review the script first
cat defaults.sh

# Make executable
chmod +x defaults.sh

# Run the script
./defaults.sh

# Some settings require a restart
sudo shutdown -r now
```

### Configuring the Dock

```bash
# Make executable
chmod +x dock.sh

# Run the script
./dock.sh

# Dock will restart automatically
```

### Environment Variables

The `.env.macos` file is typically sourced in your shell configuration:

```bash
# In .zshrc or .bash_profile
if [[ "$OSTYPE" == "darwin"* ]]; then
    source ~/.config/macos/.env.macos
fi
```

## Important Notes

1. **Backup First**: These scripts modify system settings. Review them before running.
2. **Restart Required**: Many settings require logout or system restart to take effect.
3. **Test Carefully**: Some settings can affect system stability or accessibility.
4. **Version-Specific**: Some commands may vary between macOS versions.

## Discovering Settings

To find `defaults` commands for specific preferences:

```bash
# List all domains
defaults domains

# Read all settings for a domain
defaults read com.apple.dock

# Monitor changes (run before and after changing a setting in GUI)
defaults read > before.txt
# Change setting in System Preferences
defaults read > after.txt
diff before.txt after.txt
```

## Resources

- [macOS defaults List](https://macos-defaults.com/)
- [Mathias Bynens' dotfiles](https://github.com/mathiasbynens/dotfiles)
- [GNU Screen Manual](https://www.gnu.org/software/screen/manual/)
- [defaults Command Reference](https://ss64.com/osx/defaults.html)
