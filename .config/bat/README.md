# bat

`cat` with syntax highlighting, and the highlighting engine behind delta's
diffs. `cat` itself is not aliased to it; `catp` and `catl` are
(`.config/zsh/aliases.zsh`).

## Why these choices

- **Theme `danse`**, `themes/danse.tmTheme`, rendered from the palette by
  `bin/palette`. delta uses the same theme by name
  (`.config/git/config` `syntax-theme`), since it shares bat's engine and
  theme cache.
- **`--map-syntax`** gives the files this repo is full of a real grammar:
  zsh files as bash, `Brewfile`/`Caskfile` as Ruby, `*.conf` as INI.
- **`less -FR`** as the pager, so a short file prints and exits instead of
  opening a pager.

## Gotchas

- `danse` is not built in. bat reads it only from its compiled cache, so a
  fresh machine needs `bat cache --build` once after `make link`, and again
  after a palette retune changes the theme. Until then bat prints
  `Unknown theme 'danse', using default` and delta falls back the same way.
  Nothing in `make` runs it.
