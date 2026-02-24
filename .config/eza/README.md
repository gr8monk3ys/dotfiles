# eza Configuration

Modern `ls` replacement with Git integration and icons.

## Theme

This directory contains the OneDark theme for eza, matching the overall
dotfiles color scheme.

### OneDark Colors Used

| Element | Color | Hex |
|---------|-------|-----|
| Directories | Blue | `#61afef` |
| Executables | Green | `#98c379` |
| Symlinks | Cyan | `#56b6c2` |
| Modified (Git) | Yellow | `#e5c07b` |
| New (Git) | Green | `#98c379` |
| Deleted (Git) | Red | `#e06c75` |

## Usage

eza automatically loads the theme from `~/.config/eza/theme.yml`.

```bash
# Basic listing with icons
eza --icons

# Long format with git status
eza -la --icons --git

# Tree view
eza --tree --icons -L 2
```

## Aliases

These aliases are configured in `~/.config/zsh/aliases.zsh`:

```bash
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --git --group-directories-first'
alias lt='eza --tree --icons --git -L 2'
```

## Installation

```bash
brew install eza
```

## Resources

- [eza GitHub](https://github.com/eza-community/eza)
- [eza Themes](https://github.com/eza-community/eza-themes)
