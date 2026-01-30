# Ghostty Terminal Configuration

[Ghostty](https://ghostty.org/) is a fast, feature-rich, and cross-platform terminal emulator built from the ground up in Zig by Mitchell Hashimoto (HashiCorp co-founder).

## Features

- **Native GPU Rendering** - Hardware-accelerated rendering for smooth performance
- **Built-in Multiplexing** - Native splits and tabs without tmux
- **Modern Architecture** - Written in Zig for performance and safety
- **Cross-Platform** - macOS, Linux (Windows coming)
- **Font Ligatures** - Full support for programming ligatures
- **Shell Integration** - Smart features like cursor tracking, sudo detection

## Installation

```bash
# macOS (via Homebrew)
brew install --cask ghostty

# Or download from https://ghostty.org/download
```

## Key Bindings

### Splits (Built-in Multiplexing)
| Key | Action |
|-----|--------|
| `Cmd+D` | Split right |
| `Cmd+Shift+D` | Split down |
| `Cmd+W` | Close split |
| `Cmd+H/J/K/L` | Navigate splits (vim-style) |
| `Cmd+Enter` | Toggle split zoom |

### Tabs
| Key | Action |
|-----|--------|
| `Cmd+T` | New tab |
| `Cmd+1-5` | Go to tab 1-5 |
| `Cmd+Shift+Left/Right` | Previous/Next tab |

### General
| Key | Action |
|-----|--------|
| `Cmd+F` | Toggle fullscreen |
| `Cmd++/-` | Increase/Decrease font size |
| `Cmd+0` | Reset font size |
| `Cmd+Shift+C` | Open config |

## Theme

Using OneDark-inspired colors for consistency with Neovim and other tools.

## Why Ghostty over Kitty?

1. **Performance** - Zig-based rendering is exceptionally fast
2. **Built-in Multiplexing** - No need for tmux for basic splits
3. **Modern Codebase** - Clean architecture, actively developed
4. **macOS Native** - Better macOS integration
5. **Configuration** - Simpler config format

## Migration from Kitty

Ghostty and Kitty have similar features. Main differences:
- Ghostty uses `=` for config assignments (not spaces)
- Keybindings use `keybind =` prefix
- Built-in splits use different terminology

## Configuration

Edit `~/.config/ghostty/config` to customize. Changes take effect on restart or with `Cmd+Shift+R`.

## Resources

- [Ghostty Documentation](https://ghostty.org/docs)
- [Ghostty GitHub](https://github.com/ghostty-org/ghostty)
- [Configuration Reference](https://ghostty.org/docs/config)
