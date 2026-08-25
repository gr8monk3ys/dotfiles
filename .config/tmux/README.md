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
# Prefix is Ctrl-Space (not the default Ctrl-b)
set -g prefix C-Space
bind C-Space send-prefix
```

#### Mouse Support

```
set -g mouse on
```

#### Colors and Appearance

```
set -g default-terminal "tmux-256color"
set -g status-interval 5
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
setw -g automatic-rename-format "#P #{pane_current_path}  #{pane_current_command}"
set -g status-right ''
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

With this config's prefix (Ctrl-Space); `prefix r` reloads the config and `Shift-←/→` moves between panes without the prefix:

**Sessions**

- `Ctrl-Space d` - Detach from session
- `Ctrl-Space s` - List sessions
- `Ctrl-Space $` - Rename session

**Windows**

- `Ctrl-Space c` - Create new window
- `Ctrl-Space ,` - Rename window
- `Ctrl-Space n` - Next window
- `Ctrl-Space p` - Previous window
- `Ctrl-Space 0-9` - Switch to window by number
- `Ctrl-Space &` - Kill window

**Panes**

- `Ctrl-Space |` - Split vertically
- `Ctrl-Space -` or `_` - Split horizontally
- `Ctrl-Space arrow` - Navigate panes
- `Ctrl-Space x` - Kill pane
- `Ctrl-Space z` - Toggle pane zoom
- `Ctrl-Space {` - Move pane left
- `Ctrl-Space }` - Move pane right

**Other**

- `Ctrl-Space :` - Command prompt
- `Ctrl-Space ?` - List keybindings
- `Ctrl-Space [` - Enter copy mode

## Features

### Copy Mode

Enter scrollback/copy mode with `Ctrl-Space [`

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
