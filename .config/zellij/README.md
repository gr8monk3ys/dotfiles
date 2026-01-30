# Zellij Configuration

[Zellij](https://zellij.dev/) is a modern terminal multiplexer written in Rust, designed as a user-friendly alternative to tmux.

## Features

- **Modern Design** - Clean UI with rounded corners and better defaults
- **Plugin System** - WebAssembly-based plugin architecture
- **Session Management** - Built-in session manager
- **Floating Panes** - Native floating window support
- **Layouts** - Define window layouts in KDL format
- **Scroll/Copy** - Vim-like scroll and search modes

## Installation

```bash
# macOS
brew install zellij

# Or via cargo
cargo install zellij
```

## Key Bindings (tmux-compatible)

Leader key: `Ctrl+Space` (configurable)

### Pane Management
| Key | Action |
|-----|--------|
| `Leader + \|` | Split right |
| `Leader + -` | Split down |
| `Leader + x` | Close pane |
| `Leader + z` | Toggle fullscreen |
| `Leader + h/j/k/l` | Navigate panes (vim-style) |
| `Leader + f` | Toggle floating pane |

### Tab Management
| Key | Action |
|-----|--------|
| `Leader + c` | New tab |
| `Leader + n/p` | Next/Previous tab |
| `Leader + 1-9` | Go to tab N |
| `Leader + &` | Close tab |
| `Leader + ,` | Rename tab |

### Resize
| Key | Action |
|-----|--------|
| `Leader + H/J/K/L` | Resize pane |

### Session
| Key | Action |
|-----|--------|
| `Leader + d` | Detach |
| `Leader + w` | Session manager |

### Scroll/Copy Mode
| Key | Action |
|-----|--------|
| `Leader + [` | Enter scroll mode |
| `j/k` | Scroll up/down |
| `Ctrl+f/b` | Page up/down |
| `/` | Search |
| `q` or `Esc` | Exit scroll mode |

## Commands

```bash
# Start new session
zellij

# Start with name
zellij -s my-session

# Attach to session
zellij attach my-session
zellij a my-session

# List sessions
zellij list-sessions
zellij ls

# Kill session
zellij kill-session my-session

# Kill all sessions
zellij kill-all-sessions
```

## Comparison: Zellij vs tmux

| Feature | tmux | Zellij |
|---------|------|--------|
| Learning curve | Steeper | Gentler |
| Default keybindings | Less intuitive | More intuitive |
| Floating panes | Plugin required | Built-in |
| Session manager | External (tmux-sessionizer) | Built-in |
| Plugins | Limited | WebAssembly-based |
| Configuration | Custom format | KDL (readable) |
| Performance | Excellent | Excellent |
| Ecosystem | Mature | Growing |

## When to Use tmux vs Zellij

**Use Zellij if:**
- You want better defaults out of the box
- You prefer modern, readable config (KDL)
- You want built-in floating panes
- You're new to terminal multiplexers

**Use tmux if:**
- You need mature plugin ecosystem
- You're already proficient with tmux
- You need specific tmux features
- You use tmux-specific tools (tmux-resurrect, etc.)

## Layouts

Create custom layouts in `~/.config/zellij/layouts/`:

```kdl
// ~/.config/zellij/layouts/dev.kdl
layout {
    pane split_direction="vertical" {
        pane command="nvim"
        pane split_direction="horizontal" {
            pane command="lazygit"
            pane
        }
    }
}
```

Use with: `zellij --layout dev`

## Resources

- [Zellij Documentation](https://zellij.dev/documentation/)
- [Zellij GitHub](https://github.com/zellij-org/zellij)
- [KDL Language](https://kdl.dev/)
