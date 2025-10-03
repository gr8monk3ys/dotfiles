# Kitty Terminal Configuration

This directory contains the configuration for [Kitty](https://sw.kovidgoyal.net/kitty/), a fast, feature-rich, GPU-based terminal emulator.

## Files

- `kitty.conf` - Main configuration file for Kitty terminal

## What is Kitty?

Kitty is a modern, GPU-accelerated terminal emulator that offers:
- Hardware-accelerated rendering for smooth performance
- True color and image support
- Extensive customization options
- Tabs and window layouts
- Keyboard-driven workflow
- Ligature support for programming fonts
- Session management

## Configuration Overview

The `kitty.conf` file controls all aspects of Kitty's appearance and behavior.

### Common Settings

Typical configurations include:

#### Appearance
- **Fonts**: Font family, size, and ligature settings
- **Colors**: Color schemes and transparency
- **Cursor**: Cursor style and blinking
- **Window**: Padding, margins, and decorations

#### Behavior
- **Scrollback**: Buffer size for scrolling history
- **Mouse**: Click actions and selection behavior
- **Clipboard**: Copy/paste integration
- **Performance**: Rendering optimizations

#### Keyboard Shortcuts
- **Tabs**: Creating, navigating, and closing tabs
- **Windows**: Splitting and managing windows
- **Zoom**: Adjusting font size
- **Search**: Buffer search functionality

### Key Features

- **Splits**: Divide terminal into multiple panes
- **Tabs**: Multiple terminal sessions in one window
- **Layouts**: Predefined window arrangements
- **Hints**: URL and file path detection
- **Unicode**: Full Unicode support including emojis

## Usage

After installation, Kitty reads the configuration from:
- `~/.config/kitty/kitty.conf` (Linux/macOS)
- `%APPDATA%\kitty\kitty.conf` (Windows)

### Reload Configuration

Press `Ctrl+Shift+F5` to reload the configuration without restarting Kitty.

### Testing Changes

You can test configuration changes by:
```bash
# Launch Kitty with custom config
kitty --config /path/to/test/kitty.conf
```

## Customization Tips

1. **Font Selection**: Use fonts with programming ligatures (e.g., Fira Code, JetBrains Mono)
2. **Color Schemes**: Import pre-made themes from [kitty-themes](https://github.com/dexpota/kitty-themes)
3. **Performance**: Adjust `repaint_delay` and `input_delay` for smoother rendering
4. **Shortcuts**: Customize keybindings to match your workflow

## Resources

- [Kitty Documentation](https://sw.kovidgoyal.net/kitty/)
- [Configuration Reference](https://sw.kovidgoyal.net/kitty/conf.html)
- [Kitty Themes](https://github.com/dexpota/kitty-themes)
- [FAQ](https://sw.kovidgoyal.net/kitty/faq.html)
