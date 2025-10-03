# .config Directory

This directory contains user-level configuration files for various applications and tools following the [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html).

## Overview

The `.config` directory centralizes application configurations in a single location, making it easier to:
- Version control your configurations
- Backup and restore settings
- Share configurations across machines
- Keep your home directory clean

## Directory Structure

```
.config/
├── .aliases              # Shell aliases for productivity
├── aerospace/            # AeroSpace window manager
├── curl/                 # cURL HTTP client defaults
├── firefox/              # Firefox browser customization
├── git/                  # Git version control settings
├── kitty/                # Kitty terminal emulator
├── latexmk/              # LaTeX build automation
├── lf/                   # lf terminal file manager
├── macos/                # macOS-specific configurations
├── mpd/                  # Music Player Daemon
├── newsboat/             # RSS/Atom feed reader
├── nvim/                 # Neovim text editor (has its own README)
├── tmux/                 # Tmux terminal multiplexer
├── wget/                 # Wget download utility
├── zathura/              # Zathura document viewer
└── zsh/                  # Zsh shell configuration
```

Each subdirectory contains a `README.md` with detailed information about its specific configuration.

## Configuration Choices

### Window Management & Desktop

#### [aerospace/](aerospace/)
**AeroSpace** - A tiling window manager for macOS inspired by i3wm.

**Why chosen:**
- Provides i3-like tiling capabilities on macOS
- Keyboard-driven workflow increases productivity
- Automatic window placement and workspace management
- No gaps design maximizes screen real estate
- Native macOS integration without requiring disabling SIP

**Key features:**
- Automatic application routing to specific workspaces
- Vim-like navigation keybindings
- Multi-monitor support
- Minimal configuration needed

### Terminal & Shell

#### [kitty/](kitty/)
**Kitty** - GPU-accelerated terminal emulator.

**Why chosen:**
- Hardware acceleration for smooth rendering
- Excellent font ligature support for coding
- Image protocol support
- Highly customizable with simple config
- Fast performance with low latency

#### [tmux/](tmux/)
**Tmux** - Terminal multiplexer for session management.

**Why chosen:**
- Persistent sessions that survive disconnections
- Split panes and windows for multitasking
- Essential for remote development via SSH
- Session sharing capabilities
- Industry-standard tool

#### [zsh/](zsh/)
**Zsh** - Enhanced shell with powerful features.

**Why chosen:**
- Superior auto-completion compared to Bash
- Rich plugin ecosystem (Oh My Zsh)
- Better globbing and scripting capabilities
- Powerlevel10k for informative, beautiful prompts
- Shared history and correction features

### Development Tools

#### [git/](git/)
**Git** - Version control configuration.

**Why chosen:**
- Centralized git settings across all repositories
- Custom aliases for common workflows
- Consistent author information
- Merge and diff tool preferences

#### [nvim/](nvim/)
**Neovim** - Modern, extensible text editor.

**Why chosen:**
- Modal editing increases efficiency
- Extensive plugin ecosystem via Lua
- Built-in LSP support for IDE features
- Fast, keyboard-centric workflow
- Active development and community

### File Management

#### [lf/](lf/)
**lf (list files)** - Terminal file manager.

**Why chosen:**
- Fast, lightweight written in Go
- Vim-like keybindings for familiarity
- Scriptable with shell commands
- File preview support
- Better performance than ranger

#### [.aliases](.aliases)
**Shell Aliases** - Command shortcuts and utilities.

**Why chosen:**
- Quick navigation with `..`, `...`, etc.
- Colored ls output for better readability
- macOS-specific aliases for system management
- Network utility shortcuts
- Git command shortcuts

### Document & Media

#### [zathura/](zathura/)
**Zathura** - Minimal document viewer.

**Why chosen:**
- Vim-like keybindings for keyboard navigation
- Lightweight and fast
- Perfect for LaTeX workflow with SyncTeX
- Customizable appearance and recoloring
- Minimal memory footprint

#### [mpd/](mpd/)
**MPD (Music Player Daemon)** - Server-client music player.

**Why chosen:**
- Lightweight background music server
- Separation of player and interface
- Multiple client support
- Low resource usage
- Scriptable and automatable

#### [latexmk/](latexmk/)
**Latexmk** - LaTeX build automation.

**Why chosen:**
- Automatically runs LaTeX correct number of times
- Handles bibliography and index generation
- Continuous preview mode for live updates
- Simplifies complex LaTeX workflows
- Integrates with editors seamlessly

### Internet & Communication

#### [firefox/](firefox/)
**Firefox** - Web browser customization.

**Why chosen:**
- Privacy-focused browser
- Highly customizable via `user.js`
- Open source with strong community
- Better privacy defaults than Chrome
- Developer-friendly tools

#### [newsboat/](newsboat/)
**Newsboat** - Terminal RSS reader.

**Why chosen:**
- Keyboard-driven interface
- Offline reading support
- Podcast handling capabilities
- Lightweight and fast
- Scriptable with macros

#### [curl/](curl/) & [wget/](wget/)
**Command-line downloaders** - HTTP/FTP clients.

**Why chosen:**
- Essential for scripting and automation
- Consistent behavior across systems
- Resume capability for large files
- Scriptable for batch operations
- curl: Modern, flexible API client
- wget: Recursive downloads, mirrors

### Platform-Specific

#### [macos/](macos/)
**macOS** - System-level configurations.

**Why chosen:**
- Programmatic system preference management
- Consistent setup across machines
- Version-controlled system settings
- Quick deployment on new installations
- Includes Dock, defaults, and Screen configs

## Installation Philosophy

These configurations follow several principles:

1. **Minimal Dependencies**: Most tools are lightweight and focused
2. **Keyboard-Driven**: Emphasizes keyboard workflows for efficiency  
3. **Cross-Platform When Possible**: Many tools work on Linux/macOS
4. **Version Controlled**: All settings tracked in git
5. **Well-Documented**: Each config includes explanatory comments
6. **Modular**: Tools can be adopted independently

## Quick Start

### Clone Repository
```bash
git clone <repository-url> ~/dotfiles
cd ~/dotfiles
```

### Symlink Configurations
```bash
# Create symlinks to this .config directory
ln -s ~/dotfiles/.config ~/.config

# Or selectively link specific configs
ln -s ~/dotfiles/.config/nvim ~/.config/nvim
ln -s ~/dotfiles/.config/zsh/.zshrc ~/.zshrc
```

### Install Dependencies
```bash
# macOS with Homebrew
brew bundle --file=~/dotfiles/install/Brewfile

# See individual README files for specific tool installation
```

## Maintenance

### Adding New Configurations

1. Create a new directory in `.config/`
2. Add configuration files
3. Create a `README.md` explaining the tool and config choices
4. Update this main README with the new tool
5. Add installation steps to appropriate install files

### Updating Configurations

- Test changes locally before committing
- Document significant changes in commit messages
- Keep README files updated with configuration changes
- Consider backward compatibility

### Backup Strategy

This entire directory is version controlled, but consider:
- Regular commits of configuration changes
- Remote repository backup (GitHub/GitLab)
- Periodic exports of critical data (browser bookmarks, etc.)
- Test restore process on clean system

## Troubleshooting

### Configuration Not Loading

1. Check symlinks: `ls -la ~/.config/`
2. Verify file permissions: `chmod 644 ~/.config/tool/config`
3. Review tool-specific logs
4. Ensure tool is properly installed

### Conflicts with System Defaults

Some configurations may conflict with system defaults:
- macOS defaults require logout/restart
- Shell changes need `source ~/.zshrc` or new terminal
- Some tools cache configurations

### Platform Differences

- Some paths differ between macOS and Linux
- Tool versions may have different features
- Check individual README files for platform notes

## Resources

- [XDG Base Directory Spec](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
- [Arch Wiki - Dotfiles](https://wiki.archlinux.org/title/Dotfiles)
- [GitHub Dotfiles](https://dotfiles.github.io/)

## Contributing

When contributing configurations:
1. Test thoroughly on clean system
2. Document all changes
3. Keep configurations minimal and focused
4. Explain rationale for choices
5. Maintain existing style conventions

---

For detailed information about specific tools, see their individual README files in each subdirectory.
