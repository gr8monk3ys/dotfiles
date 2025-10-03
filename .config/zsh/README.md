# Zsh Configuration

This directory contains the configuration for [Zsh](https://www.zsh.org/), the Z shell.

## Files

- `.zshrc` - Main Zsh configuration file loaded for interactive shells
- `.inputrc` - Readline configuration for input behavior
- `.p10k.zsh` - Powerlevel10k prompt configuration

## What is Zsh?

Zsh is an extended Bourne shell with many improvements, offering:
- Advanced command-line completion
- Powerful globbing and pattern matching
- Shared command history
- Spelling correction
- Loadable modules
- Customizable prompt
- Theme and plugin support

## Configuration Overview

### .zshrc

The main configuration file that runs for interactive shells. It typically includes:

#### Environment Setup
```bash
# Path configuration
export PATH="$HOME/bin:/usr/local/bin:$PATH"

# Editor preferences
export EDITOR='nvim'
export VISUAL='nvim'
```

#### Oh My Zsh Integration
```bash
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git docker kubectl fzf)
source $ZSH/oh-my-zsh.sh
```

#### Aliases and Functions
- Custom command shortcuts
- Helper functions
- Environment-specific settings

#### History Configuration
```bash
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
```

### .inputrc

Configures readline input behavior for various programs:

#### Key Bindings
```
# Vi mode
set editing-mode vi

# Case-insensitive completion
set completion-ignore-case on

# Show all completions immediately
set show-all-if-ambiguous on

# Color completion matches
set colored-stats on
```

#### Search Settings
```
# Use up/down for history search
"\e[A": history-search-backward
"\e[B": history-search-forward
```

### .p10k.zsh

Configuration for the [Powerlevel10k](https://github.com/romkatv/powerlevel10k) prompt theme:

#### Prompt Elements
- Git status and branch information
- Current directory
- Command execution time
- Exit code indicators
- Virtual environment indicators
- Background jobs
- Custom segments

#### Appearance
- Colors and icons
- Segment spacing
- Transient prompt
- Instant prompt

## Features

### Command Completion

Zsh's intelligent completion system:
```bash
# Complete commands, options, and arguments
git che<TAB>  # Completes to 'checkout'

# Complete from history
cd ~/Doc<TAB>  # Shows recent directories matching pattern

# Correct typos
cd /ect<TAB>  # Suggests /etc
```

### History Substring Search

```bash
# Type partial command and press up/down
git push<UP>  # Cycles through previous git push commands
```

### Directory Navigation

```bash
# Auto-cd (just type directory name)
~/projects

# Directory stack
pushd ~/work
popd

# Named directories
hash -d proj=~/projects
cd ~proj
```

### Glob Patterns

```bash
# Recursive glob
ls **/*.txt

# Qualifiers
ls *(.)  # Regular files only
ls *(/)  # Directories only
ls *(.m-2)  # Files modified in last 2 days
```

## Plugins

Common Oh My Zsh plugins:

### Productivity
- **git**: Git aliases and completion
- **fzf**: Fuzzy finder integration
- **z**: Jump to frequent directories
- **zsh-autosuggestions**: Command suggestions from history

### Development
- **docker**: Docker command completion
- **kubectl**: Kubernetes completion
- **npm**: npm command completion
- **python**: Python-related aliases

### Utilities
- **colored-man-pages**: Colorful man pages
- **extract**: Universal archive extraction
- **sudo**: Press ESC twice to add sudo

## Installation

### Oh My Zsh

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### Powerlevel10k

```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
```

Configure with:
```bash
p10k configure
```

## Usage

### Reload Configuration

```bash
source ~/.zshrc
# or
exec zsh
```

### Enable Vi Mode

```bash
bindkey -v
```

### History Search

```bash
# Search history
Ctrl+R

# Cycle through history
Up/Down arrows
```

## Tips

1. **Aliases**: Create aliases for frequently used commands
2. **Functions**: Use functions for complex operations
3. **Completion**: Press Tab twice to see all options
4. **History**: Use `!!` to repeat last command, `!$` for last argument
5. **Expansion**: Use `{1..10}` for sequences, `{a,b,c}` for alternatives

## Integration

Works well with:
- **Tmux**: Enhanced terminal multiplexing
- **Neovim**: Editor integration
- **Git**: Rich git integration and aliases
- **FZF**: Fuzzy finding for history and files

## Resources

- [Zsh Documentation](https://zsh.sourceforge.io/Doc/)
- [Oh My Zsh](https://ohmyz.sh/)
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k)
- [Awesome Zsh Plugins](https://github.com/unixorn/awesome-zsh-plugins)
- [Zsh Guide](https://zsh.sourceforge.io/Guide/)
