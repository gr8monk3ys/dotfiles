# bat Configuration

A `cat` clone with syntax highlighting and Git integration.

## Theme

The active Rice's (ADR 0003): `themes/<rice>.tmTheme`, one per rice,
rendered by `bin/rice-themes` from `.config/palette/templates/bat.tmTheme`.
The shell sets `BAT_THEME` to the rice's name (`.config/zsh/rice.zsh`);
`config`'s `--theme="danse"` is the fallback outside such a shell.

## Features

- Syntax highlighting for 100+ languages
- Git integration (shows modifications)
- Automatic paging
- Line numbers

## Configuration

The config file at `~/.config/bat/config` sets:

- Theme: danse
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
bat --theme="danse" file.py
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

## The themes are vendored

None of the rice themes is one of bat's built-ins. `themes/*.tmTheme` are
vendored here and compiled into bat's cache:

```bash
bat cache --build
```

Without that step bat silently falls back to its default and prints
`Unknown theme 'danse', using default` — which is what it did for as
long as this config has existed. `make link` puts the theme in place;
`bat cache --build` is the part a fresh machine still needs.

Run it again after rendering a new rice. The same names are used by delta
(`syntax-theme` in `.config/git/delta/<rice>.gitconfig`), which shares bat's
syntect engine and the same cache.
