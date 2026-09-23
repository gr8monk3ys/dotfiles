# eza Configuration

Modern `ls` replacement with Git integration and icons.

## Theme

eza is themed from the danse palette ([`.config/palette/`](../palette/README.md))
in two places, both rendered by `bin/palette`: `EZA_COLORS` in `.zshenv`, which
is what applies on this Mac, and `theme.yml` here. Edit the templates, not
these files.

| Element | Palette colour |
| --- | --- |
| Directories | `blue` |
| Executables | `green` |
| Symlinks | `cyan` |
| Modified (Git) | `yellow` |
| New (Git) | `green` |
| Deleted (Git) | `vermilion` |

## Usage

On macOS the colours come from `EZA_COLORS`; `theme.yml` is not read (see
below).

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

`EZA_COLORS` is what this build honours, so the palette is rendered there in
`.zshenv` too. `theme.yml` stays, rendered from the same slots, for eza builds
that do read it (other platforms' packages, e.g. Arch's, are not built from
the Homebrew bottle); on this Mac it changes nothing.
