# eza Configuration

Modern `ls` replacement with Git integration and icons.

## Theme

The active Rice's (ADR 0003). `rices/<rice>/theme.yml` is rendered per rice
by `bin/rice-themes` from `.config/palette/templates/eza-theme.yml`, and the
shell points `EZA_CONFIG_DIR` at the rice's directory
(`.config/zsh/rice.zsh`). `theme.yml` here links to danse's, the fallback
outside such a shell. Directories take the rice's blue, executables and new
files its green (Field Notebook: the pen), deletions its red.

## Usage

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

Arch's build (also `v0.23.5 [+git]`) ignores it too. `EZA_COLORS` is what
these builds honour, so the same theme is rendered there as well, into
`.config/zsh/rices/<rice>.zsh`. `theme.yml` is kept because it is the
upstream format and will work on a build with the feature enabled; both come
from templates, so edit `.config/palette/templates/` and render.
