# eza Configuration

Modern `ls` replacement with Git integration and icons.

## Theme

This directory contains the OneDark theme for eza, matching the overall
dotfiles color scheme.

### OneDark Colors Used

| Element | Color | Hex |
| --- | --- | --- |
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

## theme.yml is inert on Homebrew builds

`theme.yml` requires a build feature Homebrew's bottle does not enable. This
machine's eza reports:

```
v0.23.5 [+git]
```

`git` is the only feature compiled in. eza silently ignores `theme.yml` —
malformed YAML included, which is how to check: if a deliberately broken
`theme.yml` produces no error, theme support is absent.

`EZA_COLORS` is what this build honours, so the same OneDark palette is
expressed there in `.zshenv`. `theme.yml` is kept because it is the upstream
format and will work on a build with the feature enabled, but **editing it
changes nothing today** — change `EZA_COLORS` instead.
