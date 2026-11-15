# Yazi File Manager Configuration

[Yazi](https://yazi-rs.github.io/) is a blazing fast terminal file manager written in Rust, with async I/O, image preview, and plugin support.

## Features

- **Async I/O** - Non-blocking operations for smooth performance
- **Image Preview** - Native image preview in supported terminals (Ghostty, Kitty, iTerm2)
- **Plugin System** - Extensible with Lua plugins
- **Vim Keybindings** - Familiar navigation for Vim users
- **Modern Tools Integration** - Works with fd, ripgrep, fzf, zoxide
- **Archive Support** - Preview and extract archives with ouch

## Installation

```bash
# macOS (via Homebrew)
brew install yazi ffmpegthumbnailer unar jq poppler fd ripgrep fzf zoxide

# Dependencies for previews
brew install imagemagick ffmpeg
```

## Key Bindings

### Navigation
| Key | Action |
| --- | --- |
| `h/j/k/l` | Navigate (vim-style) |
| `gg` | Go to top |
| `G` | Go to bottom |
| `H/L` | Back/Forward in history |
| `Ctrl+u/d` | Half page up/down |

### File Operations
| Key | Action |
| --- | --- |
| `y` | Yank (copy) |
| `x` | Cut |
| `p` | Paste |
| `dd` | Move to trash |
| `D` | Delete permanently |
| `a` | Create file/directory |
| `r` | Rename |

### Selection
| Key | Action |
| --- | --- |
| `Space` | Toggle selection |
| `v` | Visual mode |
| `Ctrl+a` | Select all |

### Search & Filter
| Key | Action |
| --- | --- |
| `/` | Find |
| `s` | Search with fd |
| `S` | Search with ripgrep |
| `f` | Filter |

### Quick Navigation
| Key | Action |
| --- | --- |
| `gh` | Go to ~ |
| `gc` | Go to ~/.config |
| `gd` | Go to ~/Downloads |
| `gp` | Go to ~/projects |
| `g.` | Go to ~/.dotfiles |
| `z` | Jump with zoxide |
| `Ctrl+f` | Jump with fzf |

### Tabs
| Key | Action |
| --- | --- |
| `t` | New tab |
| `1-4` | Go to tab |
| `[/]` | Previous/Next tab |

### Copy Info
| Key | Action |
| --- | --- |
| `cc` | Copy file path |
| `cd` | Copy directory path |
| `cf` | Copy filename |

## Migration from lf

Yazi is similar to lf but with several advantages:
- Written in Rust (faster, async)
- Built-in image preview
- Better archive handling
- Modern plugin system
- More active development

Key differences:
- Config format is TOML (not shell-like)
- Different keybinding syntax
- Better defaults out of the box

## Theme

The active Rice's (ADR 0003), like Neovim, Ghostty and the other tools.
Each rice has a directory, `rices/<rice>/`, holding its `theme.toml`
(rendered by `bin/rice-themes`) beside links to the shared `yazi.toml` and
`keymap.toml`; the shell sets `YAZI_CONFIG_HOME` to it
(`.config/zsh/rice.zsh`). `theme.toml` here links to danse's, the fallback
outside such a shell.

## Shell Integration

Add to your `.zshrc` to get directory changing on exit:

```zsh
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}
```

## Plugins

Yazi supports Lua plugins. Some useful ones:
- `fzf.yazi` - FZF integration
- `zoxide.yazi` - Zoxide integration

## Resources

- [Yazi Documentation](https://yazi-rs.github.io/docs)
- [Yazi GitHub](https://github.com/sxyazi/yazi)
- [Plugin Repository](https://yazi-rs.github.io/docs/plugins/overview)
