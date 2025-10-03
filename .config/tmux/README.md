# Tmux Configuration

This directory contains the configuration for [tmux](https://github.com/tmux/tmux), a terminal multiplexer.

## Files

- `tmux.conf` - Main configuration file for tmux

## What is Tmux?

Tmux is a terminal multiplexer that allows you to:
- Run multiple terminal sessions in a single window
- Split terminal into multiple panes
- Detach and reattach sessions
- Preserve sessions across disconnections
- Create persistent workspaces
- Share terminal sessions with others

## Configuration Overview

The `tmux.conf` file customizes tmux's behavior, appearance, and keybindings.

### Common Settings

#### Prefix Key
```
# Change prefix from Ctrl-b to Ctrl-a
set -g prefix C-a
unbind C-b
bind C-a send-prefix
```

#### Mouse Support
```
set -g mouse on
```

#### Colors and Appearance
```
set -g default-terminal "screen-256color"
set -g status-style bg=black,fg=white
```

#### Window and Pane Management
```
# Split panes with | and -
bind | split-window -h
bind - split-window -v

# Vim-like pane navigation
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R
```

#### Status Bar
```
set -g status-position bottom
set -g status-left '[#S] '
set -g status-right '%H:%M %d-%b-%y'
```

## Usage

### Starting Tmux

```bash
# Start new session
tmux

# Start named session
tmux new -s mysession

# Attach to existing session
tmux attach -t mysession

# List sessions
tmux ls
```

### Basic Commands

With default prefix (Ctrl-b):

**Sessions**
- `Ctrl-b d` - Detach from session
- `Ctrl-b s` - List sessions
- `Ctrl-b $` - Rename session

**Windows**
- `Ctrl-b c` - Create new window
- `Ctrl-b ,` - Rename window
- `Ctrl-b n` - Next window
- `Ctrl-b p` - Previous window
- `Ctrl-b 0-9` - Switch to window by number
- `Ctrl-b &` - Kill window

**Panes**
- `Ctrl-b %` - Split vertically
- `Ctrl-b "` - Split horizontally
- `Ctrl-b arrow` - Navigate panes
- `Ctrl-b x` - Kill pane
- `Ctrl-b z` - Toggle pane zoom
- `Ctrl-b {` - Move pane left
- `Ctrl-b }` - Move pane right

**Other**
- `Ctrl-b :` - Command prompt
- `Ctrl-b ?` - List keybindings
- `Ctrl-b [` - Enter copy mode

## Features

### Copy Mode

Enter scrollback/copy mode with `Ctrl-b [`
- Navigate with arrow keys or Vim bindings
- `Space` - Start selection
- `Enter` - Copy selection
- `q` - Exit copy mode

### Plugins

Popular tmux plugins via [TPM](https://github.com/tmux-plugins/tpm):
- **tmux-resurrect**: Save and restore sessions
- **tmux-continuum**: Automatic session saving
- **tmux-yank**: Better clipboard integration
- **tmux-sensible**: Sensible default settings

### Session Management

```bash
# Create session with windows
tmux new -s dev -n editor
tmux split-window -h
tmux new-window -n server

# Save session layout
tmux list-windows > layout.txt
```

### Scripting

Automate tmux with scripts:
```bash
#!/bin/bash
tmux new-session -d -s mysession
tmux send-keys 'cd ~/project' C-m
tmux split-window -h
tmux send-keys 'npm run dev' C-m
tmux attach-session -t mysession
```

## Tips

1. **Learn the Prefix**: All tmux commands start with the prefix key
2. **Copy Mode**: Use Vim-style navigation in copy mode for efficiency
3. **Pane Synchronization**: `setw synchronize-panes on` to type in all panes
4. **Session Naming**: Use descriptive names for easier management
5. **Status Bar**: Customize to show useful information

## Integration

Works well with:
- **Shell**: Zsh, Bash with custom prompts
- **Editors**: Vim, Neovim for seamless integration
- **SSH**: Maintain sessions on remote servers
- **Scripts**: Automation and workspace setup

## Resources

- [Tmux Manual](https://man.openbsd.org/tmux.1)
- [Tmux GitHub](https://github.com/tmux/tmux)
- [Tmux Cheat Sheet](https://tmuxcheatsheet.com/)
- [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm)
- [Book: tmux 2](https://pragprog.com/titles/bhtmux2/tmux-2/)
