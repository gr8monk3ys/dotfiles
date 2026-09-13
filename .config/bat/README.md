# bat Configuration

A `cat` clone with syntax highlighting and Git integration.

## Theme

Configured to use `base16-onedark`, matching the OneDark color scheme
used throughout these dotfiles.

## Features

- Syntax highlighting for 100+ languages
- Git integration (shows modifications)
- Automatic paging
- Line numbers

## Configuration

The config file at `~/.config/bat/config` sets:

- Theme: base16-onedark
- Style: numbers, changes, header
- Tab width: 4 spaces
- Custom syntax mappings for dotfiles

## Usage

```bash
# View a file with syntax highlighting
bat file.py

# Show without paging
bat --paging=never file.py

# Plain output (like cat)
bat --plain file.txt

# Show available themes
bat --list-themes

# Use a specific theme
bat --theme="base16-onedark" file.py
```

## Aliases

These aliases are configured in `~/.config/zsh/aliases.zsh`:

```bash
# cat itself is left alone; use bat directly or:
alias catp='bat'                 # with pager
alias catl='bat --plain'         # plain (no line numbers)
```

## Installation

```bash
brew install bat
```

## Integration with Other Tools

bat integrates well with:

- **fzf**: Use bat for previews
- **git**: Uses bat for `git diff` (via delta)
- **man**: Can be used as a pager for man pages

## Resources

- [bat GitHub](https://github.com/sharkdp/bat)
- [Available Themes](https://github.com/sharkdp/bat#highlighting-theme)

## The theme is vendored

`base16-onedark` is **not** one of bat's built-in themes. `themes/base16-onedark.tmTheme`
is vendored here and compiled into bat's cache:

```bash
bat cache --build
```

Without that step bat silently falls back to its default and prints
`Unknown theme 'base16-onedark', using default` — which is what it did for as
long as this config has existed. `make link` puts the theme in place;
`bat cache --build` is the part a fresh machine still needs.

The same name is used by delta (`.config/git/config` `syntax-theme`), which
shares bat's syntect engine and the same cache.
